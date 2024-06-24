/*
 * @Module: Engine
 * @Desc:   Module to model the engine of a PuzzleScript game    
 *          NOTE: This module needs to be refactored soon. See Generation engine
 *                and make use of Rascal's list pattern matching to apply rewrite
 *                rules
 * @Author: Clement Julia -> code
 *          Denis Vet     -> code
 *          Boja Velasco  -> code, comments
 */

module PuzzleScript::Engine

/******************************************************************************/
// --- General modules imports -------------------------------------------------
import String;
import List;
import Type;
import Set;
import IO;
import util::Eval;
import util::Math;

/******************************************************************************/
// --- Own modules imports -------------------------------------------------
import PuzzleScript::AST;
import PuzzleScript::Compiler;
import Utils;

/******************************************************************************/
// --- Public macro definitions ------------------------------------------------
int MAX_RULE_APPLY = 10;

/******************************************************************************/
// --- Public execute move functions -------------------------------------------
// Applies movement, checks which rules apply, executes movement, checks which late rules apply

/*
 * @Name:   execute_move
 * @Desc:   Function to execute a move in the engine. It first moves the player,
 *          then applies rules, then apply the moves and lastly it applies the 
 *          late rules
 * @Param:  engine    -> Engine
 *          move_direction -> Direction of the move to be applied
 *          allrules  -> Integer (boolean) that indicates if we need to look at
 *                       all rules or only the level specific ones
 * @Ret:    Updated engine with the move executed
 */
Engine execute_move(Engine engine, str move_direction, int allrules) {
    engine = prepare_move_player(engine, move_direction);
    engine = apply_rules(engine, move_direction, false);
    engine = apply_moves(engine);
    engine = apply_rules(engine, move_direction, true);

    int index = size(engine.level_applied_data[engine.current_level.original].applied_moves.index);
    engine.level_applied_data[engine.current_level.original].applied_moves[index] = [move_direction];
    engine.level_applied_data[engine.current_level.original].travelled_coords += [engine.current_level.player[0]];

    return engine;
}

/*
 * @Name:   prepare_move_player
 * @Desc:   Function that prepares the player object to execute a move in a given
 *          direction.
 * @Param:  engine -> Engine
 *          move_direction -> Direction to be moved
 * @Ret:    Updated engine with 
 *
 */
Engine prepare_move_player(Engine engine, str move_direction) {
    list[Object] objects = [];

    // We loop over the objects and when we find the player object we update its
    // position
    for (Object object <- engine.current_level.objects[engine.current_level.player.coords]) {
        if (object.current_name == engine.current_level.player.current_name) {
            object.direction = move_direction;
        }
        objects += object;
    }

    engine.current_level.objects[engine.current_level.player.coords] = objects;

    return engine;
}

/*
 * @Name:   apply_rules
 * @Desc:   Function that applies the rules. It loops over each rule and applies
 *          it as many times as it can. Rules that are considered movement rules
 *          only get applied once. 
 *          (NOTE: This function would need more refactoring, but have no time 
 *                 for now)
 * @Param:  engine    -> Engine
 *          move_direction -> Direction the move has been
 *          late      -> Boolean indicating whether we need to execute the late
 *                       or regular rules
 * @Ret:    Updated engine with the rules updated
 */
Engine apply_rules(Engine engine, str move_direction, bool late) {
    list[list[Rule]] applied_rules = [];

    if (late) applied_rules = engine.level_checkers[engine.current_level.original].can_be_applied_late_rules;
    else applied_rules = engine.level_checkers[engine.current_level.original].can_be_applied_rules;

    // Step 1: We loop over every rule group. Remember individual rules could have
    //         been compiled into a rule group depending on their rule direction
    for (list[Rule] rule_group <- applied_rules) {
        // Step 2: We loop over every rule of the rule group
        for (Rule rule <- rule_group) {
            // Step 2.1: Filter out the contents from the rules to make applying easier
            list[RulePart] rp_left = [rp | RulePart rp <- rule.left, rp is rule_part];
            list[RulePart] rp_right = [rp | RulePart rp <- rule.right, rp is rule_part];
            list[str]  cmd_right = [rp.command | RulePart rp <- rule.right, rp is rule_command];

            bool can_be_applied = true;
            int applied = 0;
            // Step 3: We apply the rule the maximun ammount of times possible
            while (can_be_applied && applied < MAX_RULE_APPLY) {
                // A rule: [Moveable | Moveable] possibly has [[OrangeBlock, Player], [OrangeBlock, Player]] stored
                // A rule: [Moveable | Moveable] [Moveable] has [[[OrangeBlock, Player], [OrangeBlock, Player]], [[OrangeBlock,Player]]]
                // Hence the list of lists in a list
                list[list[list[Object]]] all_found_objects = [];
                bool find_next = false;
                list[bool] applicable = [];

                // For every element in the rule
                for (RulePart rp <- rp_left) {
                    find_next = false;

                    list[RuleContent] rc = rp.contents;
                    list[list[Object]] found_objects = [];

                    for (Coords coords <- engine.current_level.objects.coords) {
                        for (Object object <- engine.current_level.objects[coords]) {
                            // If the object is not referenced by rule, skip.
                            // (I think this is only half correct, reordered rule contents would make it break)
                            if (object.current_name == "playerhead1") println();
                            if (object.current_name notin rc[0].content && !(any(str name <- object.possible_names, name in rc[0].content))) continue;

                            if (rule.movement && move_direction != rule.direction) continue;

                            // We check if the current object matches criteria
                            int r = 0;
                            r += 1;

                            found_objects = _apply_rules_matches_contents_criteria(engine, object, rc, rule.movement, rule.direction, 0, size(rc));

                            if (found_objects != [] && size(found_objects) == size(rc) && size(cmd_right) == 0) {
                                if (!(found_objects in all_found_objects)) {
                                    all_found_objects += [found_objects];
                                    applicable += true;
                                    find_next = true;
                                } 
                            } else {
                                found_objects = [];
                            }
                            if (find_next) break;
                        }
                        if (find_next) break;
                    }
                }

                // Means all components to match the rule have been found
                if (size(applicable) == size(rp_left)) {
                    for (int i <- [0..size(all_found_objects)]) {
                        list[list[Object]] found_objects = all_found_objects[i];

                        engine = _apply_rule_apply(engine, found_objects, rp_left[i].contents, rp_right[i].contents, move_direction);

                        LevelAppliedData ad = engine.level_applied_data[engine.current_level.original];

                        int index = size(ad.applied_moves.index);
                        if (index in ad.actual_applied_rules.index) engine.level_applied_data[engine.current_level.original].actual_applied_rules[index] += [rule.original];
                        else engine.level_applied_data[engine.current_level.original].actual_applied_rules += (index: [rule.original]);

                        applied += 1;
                    }

                    if (rule.movement) can_be_applied = false; // Movement rules only get applied once
                }
                else {
                    can_be_applied = false;
                }
            }
        }
    }

    return engine; 
}

/*
 * @Name:   matches_criteria
 * @Desc:   Function that checks if an object matches the contents of a rule part.
 *          It is a recursive function, meaning that if the present object is 
 *          found inside the lhs and it matches, then it gets called again 
 *          on its neighbor coords.
 * @Param:  engine    -> Engine
 *          object    -> Object referenced by the rule lhs
 *          lhs       -> Left hand side of a rule
 *          direction -> Direction of the applied move
 *          index     -> No. call done
 *          required  -> Size of the lhs
 * @Ret:    
 */
list[list[Object]] _apply_rules_matches_contents_criteria(Engine engine, Object object, list[RuleContent] lhs, bool movement, str direction, int index, int required) {
    list[list[Object]] object_matches_criteria = [];
    RuleContent rc = lhs[index];

    // Step 1: Check if (multiple) object(s) can be found on layer for the rule 
    //         to be valid to apply
    object_matches_criteria += _apply_rule_matches_criteria_rule_content_size(engine, object, rc.content, direction);

    index += 1;
    if (size(lhs) <= index) {
        return object_matches_criteria;
    }

    // Second part: Now that objects in current cell meet the criteria, check if required neighbors exist
    list[Coords] neighboring_coords = _apply_rule_matches_criteria_neighboring_coords(engine, object, lhs[index].content, direction);
    if ("..." in lhs[index].content) {
        object_matches_criteria += [[game_object(0,"","...",[],<0,0>,"",layer_empty(""))]];
        index += 1;
    }

    // We check if the neighbor has the objects. It if matches, then we check
    // for each of the object in that neighbor position if it matches the position
    // In case one does, we add the matches result to the object matches
    for (Coords coord <- neighboring_coords) {
        tuple[bool, list[Object]] tmp_has = _apply_rule_has_objects(lhs[index].content, direction, engine.current_level.objects[coord], engine);
        if (tmp_has[0]) {
            for (Object object <- engine.current_level.objects[coord]) {
                list[list[Object]] tmp_matches = _apply_rules_matches_contents_criteria(engine, object, lhs, movement, direction, index, required);
                if (tmp_matches != []) {
                    object_matches_criteria += tmp_matches;
                    break;
                }
            }
        }

        if (size(object_matches_criteria) == required) break;
    }

    return object_matches_criteria;
}

/*
 * @Name:   _apply_rule_matches_criteria_rule_content_size
 * @Desc:   Function that checks if an object matches a specific RuleContent 
 *          content. Depending on the size of the content, one out of three 
 *          functions gets called
 * @Param:  engine -> Engine
 *          object -> Object to be checked
 *          content -> Contents of the RuleContent
 *          direction -> Direction of the rule
 * @Ret:    Objects that match the contents criteria
 */
list[list[Object]] _apply_rule_matches_criteria_rule_content_size(Engine engine, Object object, list[str] content, str direction){
    list[list[Object]] object_matches_criteria = [];

    if (size(content) == 0) object_matches_criteria += [[]];
    else if (size(content) == 2) object_matches_criteria += _apply_rule_matches_criteria_rule_content_size_single(engine, content, object);
    else object_matches_criteria += _apply_rule_matches_criteria_rule_content_size_multiple(engine, content, object, direction);

    return object_matches_criteria;
}


/*
 * @Name:   _apply_rule_matches_criteria_rule_content_size_single
 * @Desc:   Function that checks if an object matches a specific RuleContent 
 *          content of size 2
 * @Param:  engine -> Engine
 *          object -> Object to be checked
 *          content -> Contents of the RuleContent
 * @Ret:    Objects that match the contents criteria
 */
list[list[Object]] _apply_rule_matches_criteria_rule_content_size_single(Engine engine, list[str] content, Object object) {
    if (content[1] in engine.properties.key && !(content[1] in object.possible_names)) return [];
    if (!(content[1] in engine.properties.key) && content[1] != object.current_name) return [];
    if (content[0] != "no" && content[0] != object.direction && content[0] != "") return [];
    if (content[0] == "no" && content[1] in object.possible_names) return [];

    return [[object]];
}

/*
 * @Name:   _apply_rule_matches_criteria_rule_content_size_multiple
 * @Desc:   Function that checks if an object matches a specific RuleContent 
 *          content of size 3 or more
 * @Param:  engine    -> Engine
 *          object    -> Object to be checked
 *          content   -> Contents of the RuleContent
 *          direction -> Direction of the rule
 * @Ret:    Objects that match the contents criteria
 */
list[list[Object]] _apply_rule_matches_criteria_rule_content_size_multiple(Engine engine, list[str] content, Object object, str direction) {
    list[list[Object]] object_matches_criteria = [];

    list[Object] objects_same_position = engine.current_level.objects[object.coords];
    tuple[bool boolean, list[Object] list_objects] has_required_objects = _apply_rule_has_objects(content, direction, objects_same_position, engine);

    if (has_required_objects.boolean) {
        if (has_required_objects.list_objects != []) object_matches_criteria += [has_required_objects.list_objects];
        else object_matches_criteria += [[game_object(0,"","empty_obj",[], object.coords,"",object.layer)]];
    }

    return object_matches_criteria;
}

/*
 * @Name:   _apply_rule_matches_criteria_neighboring_coords
 * @Desc:   Function that calculates the neighboring coords of a given object.
 *          If the content contains ellipsis, it returns the coords of the closest
 *          matching neighbor. If it has no ellipsis, just the next coords depending
 *          on the direction.
 * @Param:  engine    -> Engine
 *          object    -> Object to calculate the neighbors from
 *          content   -> Rule contents
 *          direction -> Rule direction 
 * @Ret:    List of coords neighbor
 */
list[Coords] _apply_rule_matches_criteria_neighboring_coords(Engine engine, Object object, list[str] content, str direction) {
    list[Coords] neighboring_coords = [];

    Coords dir_difference = get_dir_difference(direction);

    if ("..." notin content) {
        Coords n_coords = <object.coords.x + dir_difference.x, object.coords.y + dir_difference.y>;
        if (engine.current_level.objects[n_coords]?) neighboring_coords += [n_coords];
    } 
    else {
        int level_width = engine.level_checkers[engine.current_level.original].size[0];
        int level_height = engine.level_checkers[engine.current_level.original].size[1];
        int x = object.coords.x;
        int y = object.coords.y;

        
        switch(direction) {
            case /left/: neighboring_coords = [<x, y + width> | width <- [-1..-level_width] , engine.current_level.objects[<x, y + width>]? && size(engine.current_level.objects[<x, y + width>]) > 1];
            case /right/: neighboring_coords = [<x, y + width> | width <- [1..level_width]  , engine.current_level.objects[<x, y + width>]? && size(engine.current_level.objects[<x, y + width>]) > 1];
            case /up/: neighboring_coords = [<x + height, y> | height <- [-1..-level_height], engine.current_level.objects[<x + height, y>]? && size(engine.current_level.objects[<x + height, y>]) > 1];
            case /down/: neighboring_coords = [<x + height, y> | height <- [1..level_height], engine.current_level.objects[<x + height, y>]? && size(engine.current_level.objects[<x + height, y>]) > 1];
        }
    }

    return neighboring_coords;
}

/*
 * @Name:   has_objects
 * @Desc:   Function that checks whether the given content can be matched with 
 *          the objects of the given position
 * @Param:  content   -> Content of the rule to be checked 
 *          direction -> Direction of the rule
 *          objects_same_pos -> Objects in the given position
 *          engine -> Engine
 * @Ret:    A tuple indicating whether the content of the rule holds, i.e., the 
 *          objects in the same position (objects required) are there
 */
tuple[bool, list[Object]] _apply_rule_has_objects(list[str] content, str direction, list[Object] objects_same_pos, Engine engine) {
    // Step 1: Check if no 'no' objects are present at the position. We do i+2 
    //         cause it is stored like "direction", "no", "direction", "object".
    //         If we found at least one no object it means that the rule cannot 
    //         apply, since we have an object on the same position
    list[str] no_object_names = [content[i + 2] | i <- [0..size(content)], content[i] == "no"];
    list[Object] no_objects = [obj | name <- no_object_names, any(Object obj <- objects_same_pos, name in obj.possible_names)];

    if (size(no_objects) > 0) return <false, []>;

    // Step 2: Check if all required objects are present at the position
    list[str] required_object_names = [name | name <- content, !(name == "no"), !(isDirection(name)), !(name == ""), !(name in no_object_names)];
    list[Object] required_objects = [];
    for (str name <- required_object_names) {
        if (name in engine.properties.key && any(Object obj <- objects_same_pos, name in obj.possible_names)) required_objects += obj;
        else if (any(Object obj <- objects_same_pos, name == obj.current_name)) required_objects += obj;
    }

    if (size(required_objects) != size(required_object_names)) return <false, []>; // If the size is different, it means we are lacking objects for the rule to hold
    if (required_objects == []) return <true, []>;  // Case where we have a no object_name and there was no objects like that in the same pos

    // Step 3: Check if all the objects have the required movement
    list[str] movements = [c | c <- content, isDirection(c)];
    movements += [""];

    if (!(all(obj <- required_objects, obj.direction in movements))) {
        return <false, []>;
    }

    return <true, required_objects>;
}

/*
 * @Name:   _apply_rule_apply
 * @Desc:   Function that applies a rule. 
 * @Param:  engine -> Engine
 *          found_objects -> Found objects that match the rule
 *          left -> Left part of a rule
 *          right -> Right part of a rule
 *          move_direction -> Direction in which the rule needs to be applied
 * @Ret:    Updated engine with the rule already applied
 */
Engine _apply_rule_apply(Engine engine, list[list[Object]] found_objects, list[RuleContent] left, list[RuleContent] right, str move_direction) {
    list[list[Object]] replacements = [];

    if (size(right) == 0) {
        engine = _apply_rule_apply_reset_object_directions(engine, found_objects);
        return engine;
    }

    replacements += _apply_rule_apply_resolve_right_objects(engine, found_objects, left, right, move_direction);

    engine = _apply_rule_apply_replace(engine, found_objects, replacements);

    return engine;
}

/*
 * @Name:   _apply_rule_apply_reset_object_directions
 * @Desc:   Function that resets the directions of the objects in case the 
 *          rhs of the rule is empty
 * @Param:  engine        -> Engine
 *          found_objects -> Objects that matches the lhs of the rule
 * @Ret:    Updated engine
 */
Engine _apply_rule_apply_reset_object_directions(Engine engine, list[list[Object]] found_objects) {
    int id = 0;

    for (list[Object] lobj <- found_objects) {
        for (Object obj <- lobj) {
            id = obj.id;
            engine.current_level = visit(engine.current_level) {
                case n: game_object(id, xn, xcn, xpn, xc, xd, xld) =>
                    game_object(id, xn, xcn, xpn, xc, "", xld)

            }
        }
    }

    return engine;
}

/*
 * @Name:   _apply_rule_apply_reset_object_directions
 * @Desc:   Function that resolves the objects of the rhs of a rule.
 *          rhs of the rule is empty
 * @Param:  engine         -> Engine
 *          found_objects  -> Objects that matches the lhs of the rule
 *          left           -> Left part of a rule
 *          right          -> Right part of a rule
 *          move_direction -> Direction of the movement
 * @Ret:    List of objects from the right part
 */
list[list[Object]] _apply_rule_apply_resolve_right_objects(Engine engine, list[list[Object]] found_objects, list[RuleContent] left, list[RuleContent] right, str move_direction) {
    list[list[Object]] replacements = [];

    for (int i <- [0..size(right)]) {
        RuleContent rc = right[i];
        RuleContent lrc = left[i]; // This is a big assumption right? (FIX)
        list[Object] current = [];

        if (size(rc.content) == 0) replacements += [[game_object(0,"","empty_obj",[],<0,0>,"",layer_empty(""))]];

        for (int j <- [0..size(rc.content)]) {
            if (j mod 2 == 1 || j + 1 > size(lrc.content)) continue;

            if (j < size(found_objects[i]) && found_objects[i][j].current_name == "...") {
                replacements += [[found_objects[i][j]]];
                break;
            }

            str dir = rc.content[j];
            str name = rc.content[j + 1];

            int next_neighbor = 0;
            Coords new_coords = <0,0>;
            if (size(found_objects[i]) == 0) {                    
                if (any(int j <- [0..size(found_objects)], size(found_objects[j]) > 0)) {
                    next_neighbor = j;
                    Coords dir_difference = get_dir_difference(move_direction);
                    Coords placeholder = found_objects[j][0].coords;
                    new_coords = <placeholder[0] + dir_difference[0] * (next_neighbor - i), placeholder[1] + dir_difference[1] * (next_neighbor - i)>;
                }
            }

            str rep_char = get_representation_char(name, engine.references);
            list[str] possible_names = get_properties_name(name, engine.properties);
            int highest_id = max([obj.id | coord <- engine.current_level.objects.coords, obj <- engine.current_level.objects[coord]]);
            new_coords = (new_coords == <0,0>) ? found_objects[i][0].coords : new_coords;

            current += [game_object(highest_id + 1, rep_char, name, possible_names, new_coords, dir, get_layer(engine, possible_names))];
        }
        if (current != []) replacements += [current];
    }

    return replacements;
}

/*
 * @Name:   _apply_rule_apply_replace
 * @Desc:   Function that replaces the objects from the left with the objects 
 *          from the right part
 * @Param:  engine         -> Engine
 *          found_objects  -> Objects that matches the lhs of the rule
 *          left           -> Left part of a rule
 *          right          -> Right part of a rule
 *          move_direction -> Direction of the movement
 * @Ret:    List of objects from the right part
 */
Engine _apply_rule_apply_replace(Engine engine, list[list[Object]] found_objects, list[list[Object]] replacements) {
    for (int i <- [0..size(found_objects)]) {
        list[Object] new_objects = [];
        list[Object] original_obj = found_objects[i];
        list[Object] new_objs = replacements[i];
        if (size(new_objs) > 0 && new_objs[0].current_name == "...") {
            continue;
        }

        Coords objects_coords = size(original_obj) == 0 ? new_objs[0].coords : original_obj[0].coords;
        list[Object] object_at_pos = engine.current_level.objects[objects_coords];

        new_objects += [obj | obj <- object_at_pos, !(obj in original_obj)];

        for (Object new_obj <- new_objs) {
            if (new_obj.current_name == "empty_obj") {
                continue;        
            }

            if ("player" in new_obj.possible_names) {
                engine.current_level.player = <new_obj.coords, new_obj.current_name>;
            }

            if (!(new_obj in new_objects)) new_objects += new_obj;
        }
        engine.current_level.objects[objects_coords] = new_objects;
    }

    return engine;
}

/*
 * @Name:   apply_moves
 * @Desc:   Function that applies all the moves of the objects with a set 
 *          direction
 * @Param:  engine -> Engine
 * @Ret:    Updated engine with the moves
 */
Engine apply_moves(Engine engine) {
    list[Object] updated_objects = [];
     Level current_level = engine.current_level;

    for (Coords coord <- current_level.objects<0>) {
        for (Object obj <- current_level.objects[coord]) {
            if (obj.direction != "") {
                current_level = _apply_moves_try_move(obj, current_level);
            }
        }
        engine.current_level = current_level;
        updated_objects = [];
    }
    return engine;
}

/*
 * @Name:   _apply_moves_try_move
 * @Desc:   Function that tries to execute a move of a given object
 * @Param:  obj           -> Object to be moved
 *          current_level -> Current level being played
 * @Ret:    Updated level
 */
Level _apply_moves_try_move(Object obj, Level current_level) {
    str dir = obj.direction;

    list[Object] updated_objects = [];

    Coords dir_difference = get_dir_difference(dir);
    Coords old_pos = obj.coords;
    Coords new_pos = <obj.coords[0] + dir_difference[0], obj.coords[1] + dir_difference[1]>;

    if (!(current_level.objects[new_pos]?)) {
        int id = obj.id;

        current_level = visit(current_level) {
            case n: game_object(id, xn, xcn, xpn, xc, xd, xld) =>
                game_object(id, xn, xcn, xpn, xc, "", xld)

        }
        return current_level;
    }
    list[Object] objs_at_new_pos = current_level.objects[new_pos];

    if (size(objs_at_new_pos) == 0) {
        current_level = _apply_moves_move_to_pos(current_level, old_pos, new_pos, obj);
        return current_level;
    }

    Object same_layer_obj = game_object(0,"","...",[],<0,0>,"",layer_empty(""));
    Object other = game_object(0,"","...",[],<0,0>,"",layer_empty(""));

    Object new_object;

    for (Object object <- objs_at_new_pos) {
        if (object.layer == obj.layer) same_layer_obj = object;
        else other = object;
    }

    if (same_layer_obj.char != "") new_object = same_layer_obj;
    else new_object = other;

    if (new_object.direction != "") {

        current_level = _apply_moves_try_move(new_object, current_level);
        current_level = _apply_moves_try_move(obj, current_level);
    }
    else if (obj.layer != new_object.layer) {     // Object can move one pos
        current_level = _apply_moves_move_to_pos(current_level, old_pos, new_pos, obj);
    } 
    else {
        for (Coords coords <- current_level.objects<0>) {
            for (int i <- [0..size(current_level.objects[coords])]) {
                Object object = current_level.objects[coords][i];
                if (object == obj) {
                    current_level.objects[coords] = remove(current_level.objects[coords], i);
                    current_level.objects[coords] += game_object(obj.id, obj.char, obj.current_name, obj.possible_names, obj.coords, "", 
                        obj.layer);
                }
            }
        }
    }
    return current_level;
}

// Moves object to desired position by adding object to list of objects at that position
/*
 * @Name:   _apply_moves_move_to_pos
 * @Desc:   Function that moves a given object to a desired position. It adds one 
 *          object to the list of objects in that position and removes the object
 *          from the old position
 * @Param:  current_level -> Current level played
 *          old_pos       -> Object old position
 *          new_pos       -> Object new position
 *          obj           -> Object to be moved
 * @Ret:    Updated current level
 */
Level _apply_moves_move_to_pos(Level current_level, Coords old_pos, Coords new_pos, Object obj) {
    for (int j <- [0..size(current_level.objects[old_pos])]) {
        if (current_level.objects[old_pos][j] == obj) {
            current_level.objects[old_pos] = remove(current_level.objects[old_pos], j);
            current_level.objects[new_pos] += game_object(obj.id, obj.char, obj.current_name, obj.possible_names, new_pos, "", obj.layer);

            if (obj.current_name == current_level.player[1]) current_level.player = <new_pos, current_level.player[1]>;

            break;
        }
    }

    return current_level;
}

/******************************************************************************/
// --- Function to check the win condition -------------------------------------

// Checks if current state satisfies all the win conditions
/*
 * @Name:   check_conditions
 * @Desc:   Function that checks if the current state satisfies all the win 
 *          conditions
 * @Param:  engine -> Engine
 * @Ret:    Boolean indicating if the conditions are satisfied 
 */
bool check_conditions(Engine engine) {
    GameData game = engine.game;
    list[ConditionData] lcd = game.conditions;
    list[bool] satisfied = [];

    for (ConditionData cd <- lcd) {
        if (cd is condition_data) {
            if ("on" in cd.items) {
                str moveable = cd.items[1] in engine.level_checkers[engine.current_level.original].moveable_objects ? cd.items[1] : cd.items[3];
                satisfied += check_win_condition(engine.current_level, toLowerCase(cd.items[0]), [cd.items[1], cd.items[3]]);
            } else {
                satisfied += check_win_condition(engine.current_level, toLowerCase(cd.items[0]), cd.items[1]);
            }
        }
    }

    return all(x <- satisfied, x == true);
}

/*
 * @Name:   check_win_condition
 * @Desc:   Function that checks if the win condition is reached when only one 
 *          object is found in win conditions
 * @Param:  current_level -> Current level
 *          amound        -> Amount of objects
 *          object        -> Name of the object
 * @Ret:    Boolean indicating if satisfied
 */
bool check_win_condition(Level current_level, str amount, str object) {

    list[Object] found = [];

    for (Coords coords <- current_level.objects<0>) {
        for (Object obj <- current_level.objects[coords]) {
            if (toLowerCase(object) in obj.possible_names || toLowerCase(object) == obj.current_name) found += obj;
        }
    }   

    if (amount == "some") {
        return (size(found) > 0);
    } else if (amount == "no") {
        return (size(found) == 0);
    }

    return false;
}

/*
 * @Name:   check_win_condition
 * @Desc:   Function that checks if the win condition is reached when only more 
 *          than one object is found in win conditions
 * @Param:  current_level -> Current level
 *          amound        -> Amount of objects
 *          objects       -> Names of the objects
 * @Ret:    Boolean indicating if satisfied
 */
bool check_win_condition(Level current_level, str amount, list[str] objects) {
    list[list[Object]] found_objects = [];
    list[Object] current = [];

    for (int i <- [0..size(objects)]) {
        for (Coords coords <- current_level.objects<0>) {
            for (Object object <- current_level.objects[coords]) {
                if (toLowerCase(objects[i]) in object.possible_names || toLowerCase(objects[i]) == object.current_name) {
                    current += object;
                }
            }
        }  
        if (current != []) {
            found_objects += [current];
            current = [];
        } 
    }

    list[Object] same_pos = [];

    if (size(found_objects) != 2) {
        println("ERROR FINDING OBJECTS FOR WIN CONDITION");
        i = 1/0;
    }

    for (Object object <- found_objects[0]) {
        same_pos += [obj | obj <- found_objects[1], obj.coords == object.coords];
    }

    if (amount == "all") {
        return (size(same_pos) == size(found_objects[1]) && size(same_pos) == size(found_objects[0]));
    } else if (amount == "no") {
        return (size(same_pos) == 0);
    } else if (amount == "any" || amount == "some") {
        return (size(same_pos) > 0 && size(same_pos) <= size(found_objects[1]));
    }

    return false;
}

/******************************************************************************/
// --- Public Getter Functions -------------------------------------------------

/*
 * @Name:   get_dir_difference
 * @Desc:   Function that calculates the difference in coords when a movement is 
 *          going to be done
 * @Param:  dir -> Direction of the movement
 * @Ret:    Coords difference
 */
Coords get_dir_difference(str dir) {
    Coords dir_difference = <0,0>;

    switch(dir) {
        case /right/: {
            dir_difference = <0,1>;
        }
        case /left/: {
            dir_difference = <0,-1>;
        }
        case /down/: {
            dir_difference = <1,0>;
        }
        case /up/: {
            dir_difference = <-1,0>;
        }
    }

    return dir_difference;
}

/*
 *  @Name:  get_level_index
 *  @Desc:  Gets the index of the current represented level
 *  @Param:
 *      engine          Engine of the application
 *      current_level   Current represented level
 *  @Ret:   Index of the level (???)
 */
int get_level_index(Engine engine, Level current_level) {
    int index = 0;

    while (engine.levels[index].original != current_level.original) {
        index += 1;
    }

    return index + 1;
}