/*
 * @Module: Engine
 * @Desc:   Module to model the engine of a PuzzleScript game    
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
 *          direction -> Direction of the move to be applied
 *          allrules  -> Integer (boolean) that indicates if we need to look at
 *                       all rules or only the level specific ones
 * @Ret:    Updated engine with the move executed
 */
Engine execute_move(Engine engine, str direction, int allrules) {
    println("   5.1");
    engine = prepare_move_player(engine, direction);
    println("   5.2");
    engine = apply_rules(engine, engine.current_level, direction, false, allrules);
    println("   5.3");
    engine = apply_moves(engine, engine.current_level);
    println("   5.4");
    engine = apply_rules(engine, engine.current_level, direction, true, allrules);
    println("   5.5");

    int index = size(engine.level_applied_data[engine.current_level.original].applied_moves<0>);
    engine.level_applied_data[engine.current_level.original].applied_moves[index] = [direction];
    engine.level_applied_data[engine.current_level.original].travelled_coords += [engine.current_level.player[0]];
    println("   5.6");

    return engine;
}

/*
 * @Name:   prepare_move_player
 * @Desc:   Function that prepares the player object to execute a move in a given
 *          direction.
 * @Param:  engine -> Engine
 *          direction -> Direction to be moved
 * @Ret:    Updated engine with 
 *
 */
Engine prepare_move_player(Engine engine, str direction) {
    list[Object] objects = [];

    // We loop over the objects and when we find the player object we update its
    // position
    for (Object object <- engine.current_level.objects[engine.current_level.player.coords]) {
        if (object.current_name == engine.current_level.player.current_name) {
            object.direction = direction;
        }
        objects += object;
    }

    engine.current_level.objects[engine.current_level.player.coords] = objects;

    return engine;
}

/*
 * @Name:   apply_rules
 * @Desc:   Function that applies the rules
 * @Param:  engine    -> Engine
 *          move_direction -> Direction the move has been
 *          late      -> Boolean indicating whether we need to execute the late
 *                       or regular rules
 * @Ret:    Updated engine with the rules updated
 */
Engine apply_rules(Engine engine, Level current_level, str move_direction, bool late, int allrules) {
    list[list[Rule]] applied_rules = [];

    if (allrules == 0) {
        applied_rules = late ? engine.level_checkers[current_level.original].can_be_applied_late_rules : engine.level_checkers[current_level.original].can_be_applied_rules;
    } else {
        applied_rules = late ? engine.late_rules : engine.rules;
    }

    for (list[Rule] rule_group <- applied_rules) {
        // For every rule
        for (Rule rule <- rule_group) {
            // Filter out the contents from the rules to make applying easier
            list[RulePart] rp_left = [rp | RulePart rp <- rule.left, rp is rule_part];
            list[RulePart] rp_right = [rp | RulePart rp <- rule.right, rp is rule_part];
            list[str] right_command = [rp.command | RulePart rp <- rule.right, rp is rule_command];

            bool can_be_applied = true;
            int applied = 0;
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

                    list[RuleContent] rc_list = rp.contents;
                    list[list[Object]] found_objects = [];

                    for (Coords coords <- engine.current_level.objects.coords) {
                        for (Object object <- engine.current_level.objects[coords]) {
                            // If the object is not referenced by rule, skip. 
                            for (RuleContent rc <- rc_list) {
                                if (object.current_name notin rc.content && !(any(str name <- object.possible_names, name in rc.content))) {
                                    continue;
                                }
                            }

                            found_objects = matches_criteria(engine, object, rc_list, rule.direction, 0, size(rc_list));                            

                            if (found_objects != [] && size(found_objects) == size(rc_list) && (size(right_command) == 0)) {
                                println("Here");
                                if (!(found_objects in all_found_objects)) {
                                    println("Here2");
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

                        Engine engine_before = engine;
                        engine = apply(engine, found_objects, rp_left[i].contents, rp_right[i].contents, move_direction);
                        LevelAppliedData ad = engine.level_applied_data[current_level.original];
                        int index = size(ad.applied_moves<0>);
                        if (index in ad.actual_applied_rules<0>) engine.level_applied_data[engine.current_level.original].actual_applied_rules[index] += [rule.original];
                        else engine.level_applied_data[engine.current_level.original].actual_applied_rules += (index: [rule.original]);
                        applied += 1;
                    }
                }
                else {
                    can_be_applied = false;
                }
            }
        }
    }

    return engine; 
}

list[list[Object]] matches_criteria_rule_content_size(Engine engine, Object object, list[str] content, str direction){
    list[list[Object]] object_matches_criteria = [];

    if (size(content) == 0) object_matches_criteria += [[]];
    else if (size(content) == 2) object_matches_criteria += matches_criteria_rule_content_size_single(engine, content, object);
    else object_matches_criteria += matches_criteria_rule_content_size_multiple(engine, content, object, direction);
    
    return object_matches_criteria;
}


// Step 2: This is the normal case where the content is one object and one direction
list[list[Object]] matches_criteria_rule_content_size_single(Engine engine, list[str] content, Object object) {
    if (content[1] in engine.properties.key && !(content[1] in object.possible_names)) return [];
    if (!(content[1] in engine.properties.key) && content[1] != object.current_name) return [];
    if (content[0] != "no" && content[0] != object.direction && content[0] != "") return [];
    if (content[0] == "no" && content[1] in object.possible_names) return [];

    return [[object]];
}

// Step 3: If it is a different size then we need to get the objects that 
//         are in the same position as our current one and verify that 
//         the rc content has the required objects for the rule to be applied
list[list[Object]] matches_criteria_rule_content_size_multiple(Engine engine, list[str] content, Object object, str direction) {
    list[list[Object]] object_matches_criteria = [];

    list[Object] objects_same_position = engine.current_level.objects[object.coords];
    tuple[bool boolean, list[Object] list_objects] has_required_objects = has_objects(content, direction, objects_same_position, engine);

    if (has_required_objects[0]) object_matches_criteria += !(isEmpty(has_required_objects[1])) ? [has_required_objects[1]] : [[game_object(0,"","empty_obj",[], object.coords,"",object.layer)]];
    else return [];

    return object_matches_criteria;
}


/*
 * @Name:   matches_criteria
 * @Desc:   Function that
 * @Param:  engine -> Engine
 *          object -> Object referenced by the rule lhs
 *          lhs    -> Left hand side of a rule
 *          direction -> Direction of the applied move
 *          index -> (???)
 *          required -> Size of the lhs
 * @Ret:    
 */
list[list[Object]] matches_criteria(Engine engine, Object object, list[RuleContent] lhs, str direction, int index, int required) {
    list[list[Object]] object_matches_criteria = [];
    RuleContent rc = lhs[index];
    bool has_ellipsis = false;

    // Step 1: Check if (multiple) object(s) can be found on layer with corresponding movement
    object_matches_criteria += matches_criteria_rule_content_size(engine, object, rc.content, direction);
    // if (size(rc.content) == 2) {
    //     if (rc.content[1] in engine.properties.key && !(rc.content[1] in object.possible_names)) return [];
    //     if (!(rc.content[1] in engine.properties.key) && rc.content[1] != object.current_name) return [];
    //     if (rc.content[0] != "no" && rc.content[0] != object.direction && rc.content[0] != "") return []; // Case where the first content is a command
    //     if (rc.content[0] == "no" && rc.content[1] in object.possible_names) return [];

    //     object_matches_criteria += [[object]];
    // } 
    // else if (size(rc.content) == 0) {
    //     object_matches_criteria += [[]];
    // } 
    // else {
    //     list[Object] objects_same_pos = engine.current_level.objects[object.coords];
    //     tuple[bool, list[Object]] has_required_objs = has_objects(rc.content, direction, objects_same_pos, engine);

    //     if (has_required_objs[0]) object_matches_criteria += !(isEmpty(has_required_objs[1])) ? [has_required_objs[1]] : [[game_object(0,"","empty_obj",[], object.coords,"",object.layer)]];
    //     else return [];
    // }

    index += 1;
    if (size(lhs) <= index) {
        return object_matches_criteria;
    }

    // Second part: Now that objects in current cell meet the criteria, check if required neighbors exist
    Coords dir_difference = get_dir_difference(direction);
    list[Coords] neighboring_coords = [];
    
    if ("..." in lhs[index].content) {
        has_ellipsis = true;
        object_matches_criteria += [[game_object(0,"","...",[],<0,0>,"",layer_empty(""))]];
    }

    // Move on to next cell
    if (has_ellipsis) {
        index += 1;

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
    else {
        neighboring_coords = [<object.coords[0] + dir_difference[0], object.coords[1] + dir_difference[1]>];
    }

    // Make sure neighbor object is within bounds
    if (any(Coords coord <- neighboring_coords, !(engine.current_level.objects[coord]?))) return object_matches_criteria;

    // Check if all required objects are present at neighboring position
    for (Coords coord <- neighboring_coords) {
        if (size(object_matches_criteria) == required) return object_matches_criteria;

        if (has_objects(lhs[index].content, direction, engine.current_level.objects[coord], engine)[0]) {
            if (any(Object object <- engine.current_level.objects[coord], matches_criteria(engine, object, lhs, direction, index, required) != [])) {                
                object_matches_criteria += matches_criteria(engine, object, lhs, direction, index, required);
            }
        }
    }

    return object_matches_criteria;
}

/*
 * @Name:   has_objects
 * @Desc:   
 * @Param:
 *
 *
 *
 * @Ret:
 */
tuple[bool, list[Object]] has_objects(list[str] content, str direction, list[Object] objects_same_pos, Engine engine) {
    // Check if no 'no' objects are present at the position. We do i+2 cause it
    // is stored like "direction", "no", "direction", "object"
    list[str] no_object_names = [content[i + 2] | i <- [0..size(content)], content[i] == "no"];
    list[Object] no_objects = [obj | name <- no_object_names, any(Object obj <- objects_same_pos, name in obj.possible_names)];

    if (size(no_objects) > 0) return <false, []>;

    // Check if all required objects are present at the position
    list[str] required_object_names = [name | name <- content, !(name == "no"), !(isDirection(name)), !(name == ""), !(name in no_object_names)];
    list[Object] required_objects = [];
    for (str name <- required_object_names) {
        if (name in engine.properties.key && any(Object obj <- objects_same_pos, name in obj.possible_names)) required_objects += obj;
        else if (any(Object obj <- objects_same_pos, name == obj.current_name)) required_objects += obj;
    }

    if (size(required_objects) != size(required_object_names)) return <false, []>;
    if (required_objects == []) return <true, []>;

    // Check if all the objects have the required movement
    list[str] movements = [content[i] | i <- [0..size(content)], isDirection(content[i]) || content[i] == ""];
    movements += [""];

    if (!(all(int i <- [0..size(required_objects)], (required_objects[i].direction in movements)))) return <false, []>;
    return <true, required_objects>;
}

/******************************************************************************/


// Returns the differing coordinates based on the direction
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


Engine apply(Engine engine, list[list[Object]] found_objects, list[RuleContent] left, list[RuleContent] right, str applied_dir) {

    list[list[Object]] replacements = [];
    list[Object] current = [];

    if (size(right) == 0) {
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

    // Resolve objects found in the right-hand side of the rule
    for (int i <- [0..size(right)]) {

        RuleContent rc = right[i];
        RuleContent lrc = left[i];
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
            str leftdir = lrc.content[j];

            str new_direction = "";

            if (name in engine.properties<0>) {

                if (any(Object obj <- found_objects[i], name in obj.possible_names)) {

                    new_direction = obj.direction;

                    if (leftdir == "" && dir == "") new_direction = obj.direction;
                    else new_direction = dir;

                    obj.coords = found_objects[i][0].coords;
                    obj.direction = new_direction;
                    current += [obj];
                    continue;
                }

            } else if (any(Object obj <- found_objects[i], name == obj.current_name)) {

                if (any(Object obj <- found_objects[i], name in obj.possible_names)) {

                    if (leftdir == "" && dir == "") new_direction = obj.direction;
                    else new_direction = dir;

                    obj.current_name = name;
                    obj.coords = found_objects[i][0].coords;
                    obj.direction = new_direction;
                    current += [obj];
                    continue;
                }

            } else {
                str rep_char = get_representation_char(name, engine.properties);
                rep_char = rep_char != "" ? rep_char : get_representation_char(name, engine.references);

                list[str] references = get_properties_name(name, engine.properties);

                list[str] all_references = get_resolved_references(rep_char, engine.properties);
                all_references = size(all_references) == 0 ? references : all_references;
                int highest_id = max([obj.id | coord <- engine.current_level.objects<0>, obj <- engine.current_level.objects[coord]]);

                int next_neighbor = 0;
                Coords new_coords = <0,0>;
                if (size(found_objects[i]) == 0) {                    
                    if (any(int j <- [0..size(found_objects)], size(found_objects[j]) > 0)) {
                        next_neighbor = j;
                        Coords dir_difference = get_dir_difference(applied_dir);
                        Coords placeholder = found_objects[j][0].coords;
                        new_coords = <placeholder[0] + dir_difference[0] * (next_neighbor - i), 
                            placeholder[1] + dir_difference[1] * (next_neighbor - i)>;
                    }
                }

                new_coords = new_coords == <0,0> ? found_objects[i][0].coords : new_coords;
                if ("player" in references) engine.current_level.player = <new_coords, name>;

                current += [game_object(highest_id + 1, rep_char != "" ? rep_char : "9", name, all_references, new_coords, 
                    dir, get_layer(engine, all_references))];

            }
        }
        if (current != []) replacements += [current];
    }

    // Do the actual replacements
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
                // new_objects += [obj | obj <- engine.current_level.objects[objects_coords], !(obj in new_objects)];
                continue;        
            }

            if (!(new_obj in new_objects)) new_objects += new_obj;
        }
        engine.current_level.objects[objects_coords] = new_objects;
    }
    return engine;
}

// Moves object to desired position by adding object to list of objects at that position
Level move_to_pos(Level current_level, Coords old_pos, Coords new_pos, Object obj) {

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

// Tries to execute move set in the apply function
Level try_move(Object obj, Level current_level) {

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
        current_level = move_to_pos(current_level, old_pos, new_pos, obj);
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

        current_level = try_move(new_object, current_level);
        current_level = try_move(obj, current_level);
    }
    // Object can move one pos
    else if (obj.layer != new_object.layer) {
        current_level = move_to_pos(current_level, old_pos, new_pos, obj);
    } else {
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

// Applies all the moves of objects with a direction set
Engine apply_moves(Engine engine, Level current_level) {
    list[Object] updated_objects = [];

    for (Coords coord <- current_level.objects<0>) {
        for (Object obj <- current_level.objects[coord]) {
            if (obj.direction != "") {
                current_level = try_move(obj, current_level);
            }
        }
        engine.current_level = current_level;
        updated_objects = [];
    }
    return engine;
}





real calculate_heuristic(Engine engine) {
    
    int score = 0;

    GameData game = engine.game;
    list[ConditionData] lcd = game.conditions;
    list[int] distances = [];

    for (ConditionData cd <- lcd) {
        if (cd is condition_data) {

            list[Object] moveable_win_objs = [];
            list[Object] non_moveable_win_objs = [];

            if (size(cd.items) > 2) {
                str moveable = cd.items[1] in engine.level_checkers[engine.current_level.original].moveable_objects ? 
                    cd.items[1] : cd.items[3];

                str non_moveable = cd.items[1] in engine.level_checkers[engine.current_level.original].moveable_objects ? 
                    cd.items[3] : cd.items[1];

                moveable = toLowerCase(moveable);
                non_moveable = toLowerCase(non_moveable);

                visit(engine.current_level.objects) {
                    case n: game_object(_, _, moveable, _, _, _, _): {
                        moveable_win_objs += n;
                    }
                    case m: game_object(_, _, _, [*N, moveable, *M], _, _, _): {
                        moveable_win_objs += m;
                    }
                }
                visit(engine.current_level.objects) {
                    case n: game_object(_, _, non_moveable, _, _, _, _): {
                        non_moveable_win_objs += n;
                    }
                    case m: game_object(_, _, _, [*N, non_moveable, *M], _, _, _): {
                        non_moveable_win_objs += m;
                    }
                }

                for (Object m_object <- moveable_win_objs) {
                    // if (any(Object n_m_object <- non_moveable_win_objs, n_m_object.coords == m_object.coords)) continue;
                    for (Object n_m_object <- non_moveable_win_objs) {
                        distances += abs(n_m_object.coords[0] - m_object.coords[0]) + abs(n_m_object.coords[1] - m_object.coords[1]);
                    }
                    distances += abs(engine.current_level.player[0][0] - m_object.coords[0]) + abs(engine.current_level.player[0][1] - m_object.coords[1]);
                }
            } else {

                str name = toLowerCase(cd.items[1]);

                visit(engine.current_level.objects) {
                    case n: game_object(_, _, name, _, _, _, _): {
                        moveable_win_objs += n;
                    }
                }
                for (Object m_object <- moveable_win_objs) {
                    distances += abs(engine.current_level.player[0][0] - m_object.coords[0]) + abs(engine.current_level.player[0][1] - m_object.coords[1]);
                }
            }
        }
    }

    real size = engine.level_checkers[engine.current_level.original].size[0] * engine.level_checkers[engine.current_level.original].size[1] / 1.0;

    if (isEmpty(distances)) return 0.0;

    return sum(distances) / size;
}

// If only one object is found in win condition
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

// If more objects are found in win condition
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

bool in_corner(Object object, Engine engine, LevelChecker lc) {

    list[list[str]] corners = [["up", "right"], ["up", "left"], ["down", "left"], ["down", "right"]];

    for (list[str] corner <- corners) {
        list[bool] satisfies = [];

        for (str direction <- corner) {

            Coords dir_diff = get_dir_difference(direction);
            
            Coords neighboring_coord = <object.coords[0] + dir_diff[0], object.coords[1] + dir_diff[1]>;
            LayerData layer = object.layer;

            visit (engine.current_level) {
                case game_object(_, _, name, _, neighboring_coord, _, layer): {
                    satisfies += !(name in lc.moveable_objects);
                }
            }
        }

        if (size(satisfies) == 2 && (all(x <- satisfies, x == true))) {
            return true;
        }
    }
    return false;
}

bool check_dead_end(Engine engine, str amount, str object) {

    list[Object] found = [];

    for (Coords coords <- engine.current_level.objects<0>) {
        for (Object obj <- engine.current_level.objects[coords]) {
            if (toLowerCase(object) in obj.possible_names || toLowerCase(object) == obj.current_name) found += obj;
        }
    }
    return any(Object obj <- found, in_corner(obj, engine, engine.level_checkers[engine.current_level.original]));
}

// Checks if current state satisfies all the win conditions
bool check_conditions(Engine engine, str condition) {
    println("   6.1");
    GameData game = engine.game;
    list[ConditionData] lcd = game.conditions;
    list[bool] satisfied = [];

    for (ConditionData cd <- lcd) {
        if (cd is condition_data) {
            if ("on" in cd.items) {
                str moveable = cd.items[1] in engine.level_checkers[engine.current_level.original].moveable_objects ? 
                    cd.items[1] : cd.items[3];

                if (condition == "win") {
                    println("   6.2");
                    satisfied += check_win_condition(engine.current_level, toLowerCase(cd.items[0]), [cd.items[1], cd.items[3]]);
                } else if (condition == "dead_end") {
                    satisfied += check_dead_end(engine, toLowerCase(cd.items[0]), moveable);
                }

            } else {
                if (condition == "win") {
                    satisfied += check_win_condition(engine.current_level, toLowerCase(cd.items[0]), cd.items[1]);
                }
            }
        }
    }

    return all(x <- satisfied, x == true);
}