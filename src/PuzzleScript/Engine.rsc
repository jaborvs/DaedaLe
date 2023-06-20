module PuzzleScript::Engine

import String;
import List;
import Type;
import Set;
import IO;
import PuzzleScript::Checker;
import PuzzleScript::AST;
import PuzzleScript::Utils;
import PuzzleScript::Compiler;
import util::Eval;
import util::Math;

void print_message(str string){
	println("#####################################################");
	println(string);
	println("#####################################################");
}

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

// Actual appliance of rule
// Engine apply(Engine engine, list[list[Object]] neighboring_objs, list[list[Object]] replacements) {

//     for (int i <- [0..size(replacements)]) {

//         list[Object] replacement_list = replacements[i];
//         list[Object] neighboring = neighboring_objs[i];
//         Coords neighboring_coords = neighboring[0].coords;

//         for (int i <- [0..size(neighboring)]) {
//             list[Object] objects_on_pos = engine.current_level.objects[neighboring_coords];
//             for (int j <- [0..size(objects_on_pos)]) {
//                 if (neighboring[i] == objects_on_pos[j]) {
//                     // println("Removing object <neighboring[0].current_name> from pos <neighboring_coords>");
//                     engine.current_level.objects[neighboring_coords] = remove(objects_on_pos, j);
//                 } 
//                 // else {
//                 //     println("Could not find <neighboring[i]> yet");
//                 // }
//             }
//         }

//         // println("Replacement list:\n<replacement_list>\n\nNeighboring:\n<neighboring>");

//         // list[Object] biggest_list = size(replacement_list) > size(neighboring) ? replacement_list : neighboring;

//         for (Object replacement <- replacement_list) {
            
//             // Object needs to dissapear
//             if (replacement.current_name == "") {
//                 continue;
//                 // for (int j <- [0..size(engine.current_level.objects[neighboring_coords])]) {

//                 //     Object object = engine.current_level.objects[neighboring_coords][j];
//                 //     if (object in neighboring) {
//                 //         engine.current_level.objects[neighboring_coords] = remove(engine.current_level.objects[neighboring_coords], j);
//                 //         break;
//                 //     }

//                 // }

//             }

//             // Object needs to appear
//             else if(!(any(Object neighbor <- neighboring, neighbor.id == replacement.id)) && 
//                 !(replacement in engine.current_level.objects[neighboring_coords])) {
//                     engine.current_level.objects[neighboring_coords] += replacement;
//                     continue;
//                 }

//             // Object needs to be changed
//             else {

//                 Object found;
//                 for (Object obj <- neighboring) {
//                     if (obj.id == replacement.id) found = obj;
//                 }


//                 found.direction = replacement.direction;
//                 found.coords = neighboring_coords;

//                 engine.current_level.objects[neighboring_coords] += found;

//                 // int id = replacement.id;
//                 // str direction = replacement.direction;

//                 // println("Looking for object with id <id>");

//                 // engine.current_level = visit(engine.current_level) {

//                 //     case n: game_object(xc, xn, xp_n, xcoords, xdir, xld, id) => {
//                 //         println("Changing object <xn>");
//                 //         game_object(xc, xn, xp_n, neighboring_coords, direction, xld, id);
//                 //     }

//                 // };
//             }
//         }

//     }

//     return engine;
// }

// Remove all ellipsis from the required object lists
list[list[Object]] remove_ellipsis(list[list[Object]] required) {

    list[list[Object]] new_required = [];
    list[Object] current = [];

    for (int i <- [0..size(required)]) {
        if (game_object("","...",[],<0,0>,"",layer_empty(""),0) in required[i]) continue;
        else new_required += [required[i]];
    }

    return new_required;
}

// Updates engine's level based on the application of a rule
Engine apply_rule(Engine engine, Rule rule, list[list[list[Object]]] row, str ruledir, str dir, list[RuleContent] right) {

    list[list[Object]] required = [];
    Coords dir_difference = get_dir_difference(dir);

    bool one_obj = (all(int i <- [0..size(row)], size(row[i]) == 1));

    if (one_obj) {
        required = [x[0] | x <- row];
    } else {
        for (int i <- [0..size(row)]) {

            list[list[Object]] cell = row[i];
            list[Object] current = [];

            for (int j <- [0..size(cell[0])]) {

                Object cell_obj = cell[0][j];

                list[Object] object_at_pos = engine.current_level.objects[cell_obj.coords];

                // Check if amount of objects on the position of current cell_obj satisfies the amount needed by cell
                if (size(object_at_pos) >= size(cell)) {
                    current = [x | x <- object_at_pos, [x] in cell];
                    current += [y | y <- cell[0], y.char == "no_object"];
                } else {
                    continue;
                }
            }
            if (size(current) == size(cell)) required += [current];
        }
    }

    if (required == []) {
        return engine;
    }

    list[Object] neighboring_objs = [];
    list[list[Object]] replacements = [];

    int neighbour_index = 0;

    // Find all the neighboring objects in the specified direction
    for (Object object <- required[0]) {

        // if (object.char)

        list[list[Object]] all_neighbors = [];
        neighboring_objs = find_neighbours(required, object, 0, ruledir, dir_difference);
        replacements = [];

        required = remove_ellipsis(required);

        if (size(neighboring_objs) == size(required)) {
            for (int i <- [0..size(neighboring_objs)]) {
                Object list1 = neighboring_objs[i];
                all_neighbors += [[obj | obj <- engine.current_level.objects[list1.coords], obj in required[i]]];
            }
        }

        // If enough neighbors are found
        // if (all(int i <- [0..size(all_neighbors)], size(all_neighbors[i]) == size(required[i]))) {
        if (size(all_neighbors) == size(required) && all_neighbors != [[]]) {

            int neighbour_index = 0;

            for (RuleContent rc <- rule.right) {

                if ("..." in rc.content) continue;

                // Object dissapears
                if (size(rc.content) == 0) {
                    replacements += [[game_object("", "", [], <0,0>, "", layer_empty(""), 0)]];
                    continue;
                }

                list[Object] cell_replacements = [];

                for (int i <- [0..size(rc.content)]) {
                    
                    if (i mod 2 == 1) continue;
                    
                    str direction = rc.content[i];
                    str name = rc.content[i + 1];

                    list[Object] objects = [];

                    bool found = false;
                    int highest_id = 0;

                    for (Coords coord <- engine.current_level.objects<0>) {
                        for (Object obj <- engine.current_level.objects[coord]) {

                            if (obj in all_neighbors[neighbour_index] && name in obj.possible_names) {
                                obj.direction = direction;
                                cell_replacements += [obj];
                                found = true;
                                break;
                            }

                            if (obj.id > highest_id) highest_id = obj.id;
                        }
                    }

                    if (found) continue;

                    str char = get_char(name, engine.properties);
                    list[str] all_references = char != "" ? get_all_references(char, engine.properties) : get_references(name, engine.properties);
                                        
                    cell_replacements += [game_object(char != "" ? char : "9", name, all_references, all_neighbors[neighbour_index][0].coords, 
                        direction, get_layer(all_references, engine.game), highest_id + 1)];

                }

                if (cell_replacements != []) replacements += [cell_replacements];
                neighbour_index += 1;
            }
            
            engine = apply(engine, all_neighbors, replacements);

        }
    }

    return engine;
}

// Returns a list of all neighboring objects
// list[Object] find_neighbours(list[list[Object]] all_lists, Object obj1, int index, str direction, Coords dir_difference) {

//     list[list[Object]] all_neighbors = [];
//     list[Object] neighbors = [];
//     bool ellipsis = false;

//     if (index == 0) neighbors += obj1;

//     // println("Finding neighbors for <obj1.current_name> on pos <obj1.coords>");

//     if (index + 1 < size(all_lists)) {

//         // println("Kijken in lijst: <all_lists[index + 1]>");

//         if (all_lists[index + 1][0].current_name == "...") ellipsis = true;

//         if (!ellipsis) {
//             // Find object next to current object
//             if (any(obj2 <- all_lists[index + 1], <obj2.coords[0] - obj1.coords[0], obj2.coords[1] - obj1.coords[1]> == dir_difference) &&
//                     !(obj2 in neighbors)) {

//                 // println("Found <obj2.current_name> for list <index+1>");
//                 neighbors += obj2;
//                 neighbors += find_neighbours(engine, all_lists, obj2, index + 1, direction, dir_difference);
//             } else {
//                 // println("Did not find an object for list <index+1>");
//                 return [];
//             }
//         } else {
//             // Find object at same row/column
//             if (any(obj2 <- all_lists[index + 2], dir_difference[0] == 0 ? obj2.coords[0] == obj1.coords[0] : obj2.coords[1] == obj1.coords[1]) 
//                 && !(obj2 in neighbors)) {

//                 neighbors += obj2;
//                 neighbors += find_neighbours(engine, all_lists, obj2, index + 2, direction, dir_difference);
//             } else {
//                 return [];
//             }

//         }
//     }

//     return neighbors;
// }

bool contains_no_object(Object object, str name) {

    return (name in object.possible_names);

}

bool has_objects(list[str] content, str direction, list[Object] objects_same_pos, Engine engine) {

    // Check if no 'no' objects are present at the position
    list[str] no_objs = [content[i + 2] | i <- [0..size(content)], content[i] == "no"];
    list[Object] no_objects = [obj | name <- no_objs, any(Object obj <- objects_same_pos, name in obj.possible_names)];
    if (size(no_objects) > 0) return false;

    // Check if all required objects are present at the position
    list[str] required_objs = [name | name <- content, !(name == "no"), !(isDirection(name)), !(name == ""), !(name in no_objs)];

    list[Object] rc_objects = [];
    for (str name <- required_objs) {
        if (name in engine.properties<0> && any(Object obj <- objects_same_pos, name in obj.possible_names)) rc_objects += obj;
        else if (any(Object obj <- objects_same_pos, name == obj.current_name)) rc_objects += obj;
    }

    if (size(rc_objects) != size(required_objs)) return false;

    // Check if all the objects have the required movement
    list[str] movements = [content[i] | i <- [0..size(content)], isDirection(content[i]) || content[i] == ""];

    if (rc_objects == []) return true;

    if (!(all(int i <- [0..size(rc_objects)], rc_objects[i].direction == movements[i]))) return false;
    
    return true;

}

list[list[Object]] matches_criteria(Engine engine, Object object, list[RuleContent] lhs, str direction, int index, int required) {

    list[list[Object]] object_matches_criteria = [];
    RuleContent rc = lhs[index];
    bool has_ellipsis = false;
    bool has_zero = false;

    // if ("player" in rc.content) println(rc.content);

    // First part: Check if (multiple) object(s) can be found on layer with corresponding movement
    if (size(rc.content) == 2) {

        if (rc.content[1] in engine.properties<0> && !(rc.content[1] in object.possible_names)) return [];
        
        if (!(rc.content[1] in engine.properties<0>) && !(rc.content[1] == object.current_name)) {
            return [];
        }

        if (rc.content[0] != "no" && rc.content[0] != object.direction) return [];

        if (rc.content[0] == "no" && contains_no_object(object, rc.content[1])) return [];


        object_matches_criteria += [[object]];

    } else if (size(rc.content) == 0) {

        object_matches_criteria += [[]];

    } else {

        list[Object] objects_same_pos = engine.current_level.objects[object.coords];
        if (has_objects(rc.content, direction, objects_same_pos, engine)) object_matches_criteria += [objects_same_pos];
        else return [];

    }

    index += 1;
    if (size(lhs) <= index) {
        return object_matches_criteria;
    }

    if ("rock" in lhs[index - 1].content) println("Objects on the position with rock match <lhs[index-1].content>");

    // Second part: Now that objects in current cell meet the criteria, check if required neighbors exist
    Coords dir_difference = get_dir_difference(direction);
    list[Coords] neighboring_coords = [];
    
    if ("..." in lhs[index].content) {
        has_ellipsis = true;
        object_matches_criteria += [[game_object("","...",[],<0,0>,"",layer_empty(""),0)]];
    }

    // Move on to next cell
    if (has_zero || has_ellipsis) {
        index += 1;
    }

    if (has_ellipsis) {

        int level_width = engine.current_level.additional_info.size[0];
        int level_height = engine.current_level.additional_info.size[1];
        int x = object.coords[0];
        int y = object.coords[1];

        switch(direction) {

            case /left/: neighboring_coords = [<x, y + width> | width <- [-1..-level_width], engine.current_level.objects[<x + width, y>]?];
            case /right/: neighboring_coords = [<x, y + width> | width <- [1..level_width], engine.current_level.objects[<x + width, y>]?];
            case /up/: neighboring_coords = [<x + heigth, y> | heigth <- [-1..-level_height], engine.current_level.objects[<x, y + heigth>]?];
            case /down/: neighboring_coords = [<x + heigth, y> | heigth <- [1..level_height], engine.current_level.objects[<x, y + heigth>]?];
        }

    } else {
        neighboring_coords = [<object.coords[0] + dir_difference[0], object.coords[1] + dir_difference[1]>];
    }

    // Make sure neighbor object is within bounds
    if (any(Coords coord <- neighboring_coords, !(engine.current_level.objects[coord]?))) return object_matches_criteria;


    // Check if all required objects are present at neighboring position
    for (Coords coord <- neighboring_coords) {

        if (size(object_matches_criteria) == required) return object_matches_criteria;

        // println("Calling has_objects in neighboring coords");
        if (has_objects(lhs[index].content, direction, engine.current_level.objects[coord], engine)) {
            if (any(Object object <- engine.current_level.objects[coord], matches_criteria(engine, object, lhs, direction, index, required) != [])) {                
                object_matches_criteria += matches_criteria(engine, object, lhs, direction, index, required);
            }
        }
    }

    return object_matches_criteria;
}

Engine apply(Engine engine, list[list[Object]] found_objects, list[RuleContent] right) {

    list[list[Object]] replacements = [];
    list[Object] current = [];

    if (size(right) == 0) return engine;

    for (int i <- [0..size(right)]) {

        RuleContent rc = right[i];
        list[Object] current = [];

        if (size(rc.content) == 0) replacements += [[game_object("","empty_obj",[],<0,0>,"",layer_empty(""),0)]];

        for (int j <- [0..size(rc.content)]) {

            if (j mod 2 == 1) continue;

            if (j < size(found_objects[i]) && found_objects[i][j].current_name == "...") {
                replacements += [[found_objects[i][j]]];
                break;
            }

            str dir = rc.content[j];
            str name = rc.content[j + 1];

            if (name in engine.properties<0>) {

                if (any(Object obj <- found_objects[i], name in obj.possible_names)) {
                    obj.coords = found_objects[i][0].coords;
                    obj.direction = dir;
                    current += [obj];
                    continue;
                }

            } else if (any(Object obj <- found_objects[i], name == obj.current_name)) {

                if (any(Object obj <- found_objects[i], name in obj.possible_names)) {
                    obj.current_name = name;
                    obj.coords = found_objects[i][0].coords;
                    obj.direction = dir;
                    current += [obj];
                    continue;
                }

            } else {

                str char = get_char(name, engine.properties);
                char = char != "" ? char : "9";

                list[str] references = get_references(name, engine.properties);

                if ("player" in references) engine.current_level.player[1] = name;

                list[str] all_references = engine.current_level.player[1] == name ? references : get_all_references(char, engine.properties);
                int highest_id = max([obj.id | coord <- engine.current_level.objects<0>, obj <- engine.current_level.objects[coord]]);

                current += [game_object(char != "" ? char : "9", name, all_references, found_objects[i][0].coords, 
                    dir, get_layer(all_references, engine.game), highest_id + 1)];

            }


        }

        if (current != []) replacements += [current];

    }

    for (int i <- [0..size(found_objects)]) {

        list[Object] new_objects = [];
        list[Object] original_obj = found_objects[i];
        list[Object] new_objs = replacements[i];
        if (size(new_objs) > 0 && new_objs[0].current_name == "...") {
            continue;
        }

        Coords objects_coords = original_obj[0].coords;

        for (Object object_at_pos <- engine.current_level.objects[objects_coords]) {
            if (!(object_at_pos in original_obj)) {
                new_objects += object_at_pos;
            }
        }

        for (Object new_obj <- new_objs) {
            if (new_obj.current_name == "empty_obj") {
                new_objects += [obj | obj <- engine.current_level.objects[objects_coords], !(obj in new_objects)];
            }

            if (!(new_obj in current)) new_objects += new_obj;
        }

        engine.current_level.objects[objects_coords] = new_objects;

    }

    return engine;
}


Engine apply_rules(Engine engine, Level current_level, str direction, bool late) {

    list[list[Rule]] applied_rules = late ? engine.level_data[current_level.original].applied_late_rules :engine.level_data[current_level.original].applied_rules;

    for (list[Rule] rulegroup <- applied_rules) {

        // For every rule
        for (Rule rule <- rulegroup) {

            str ruledir = "";
            bool can_be_applied = true;
            int applied = 0;
            int max_apply = 5;

            while (can_be_applied) {

                list[list[Object]] found_objects = [];

                for (Coords coord <- engine.current_level.objects<0>) {
                    for (Object object <- engine.current_level.objects[coord]) {

                        if (!(any(str name <- object.possible_names, name in rule.left[0].content || object.current_name in rule.left[0].content))) {
                            continue;
                        }

                        found_objects = matches_criteria(engine, object, rule.left, direction, 0, size(rule.left));
                        if (found_objects != [] && size(found_objects) == size(rule.left)) {
                            engine = apply(engine, found_objects, rule.right);
                            applied += 1;
                            // return engine;
                        } else {
                            found_objects = [];
                        }

                    }
                }
                if (applied == 0) can_be_applied = false;
                else applied = 0;
            }
            
        }
    }   

    return engine; 

}

// Moves object to desired position by adding object to list of objects at that position
Level move_to_pos(Level current_level, Coords old_pos, Coords new_pos, Object obj) {

    for (int j <- [0..size(current_level.objects[old_pos])]) {
        if (current_level.objects[old_pos][j] == obj) {

            current_level.objects[old_pos] = remove(current_level.objects[old_pos], j);
            current_level.objects[new_pos] += game_object(obj.char, obj.current_name, obj.possible_names, new_pos, "", obj.layer, obj.id);

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

    list[Object] objs_at_new_pos = current_level.objects[new_pos];

    if (size(objs_at_new_pos) == 0) {
        current_level = move_to_pos(current_level, old_pos, new_pos, obj);
        return current_level;
    }

    Object same_layer_obj = game_object("","...",[],<0,0>,"",layer_empty(""),0);
    Object other = game_object("","...",[],<0,0>,"",layer_empty(""),0);

    Object new_object;

    for (Object object <- objs_at_new_pos) {

        if (object.layer == obj.layer) same_layer_obj = object;
        else other = object;
    }

    if (same_layer_obj.char != "") new_object = same_layer_obj;
    else new_object = other;

    // for (int i <- [0..size(objs_at_new_pos)]) {

        // Object new_object = objs_at_new_pos[i];

        // Object moves together with other objects
        // if (obj.layer == new_object.layer && new_object.direction != "") {
    if (new_object.direction != "") {

        current_level = try_move(new_object, current_level);
        current_level = try_move(obj, current_level);
        // object = try_move(new_object, current_level);
    }
    // Object can move one pos
    // else if(obj.layer != new_object.layer && new_object.direction == "") {
    else if (obj.layer != new_object.layer) {
        current_level = move_to_pos(current_level, old_pos, new_pos, obj);
        // current_level.objects[new_pos] = remove(current_level.objects[new_pos], i);
    } else {
        for (Coords coords <- current_level.objects<0>) {
            for (int i <- [0..size(current_level.objects[coords])]) {
                Object object = current_level.objects[coords][i];
                if (object == obj) {
                    current_level.objects[coords] = remove(current_level.objects[coords], i);
                    current_level.objects[coords] += game_object(obj.char, obj.current_name, obj.possible_names, obj.coords, "", 
                        obj.layer, obj.id);
                }
            }
        }
    }

    // }

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

// Moves the player object based on player's input
Engine move_player(Engine engine, Level current_level, str direction, Checker c) {

    list[Object] objects = [];

    for (Object object <- current_level.objects[current_level.player[0]]) {
        if (object.current_name == current_level.player[1]) {
            object.direction = direction;
        }
        objects += object;
    }
    current_level.objects[current_level.player[0]] = objects;
    
    engine.current_level = current_level;
    return engine;

}

// Applies movement, checks which rules apply, executes movement, checks which late rules apply
Engine execute_move(Engine engine, Checker c, str direction) {

    engine = move_player(engine, engine.current_level, direction, c);
    engine = apply_rules(engine, engine.current_level, direction, false);
    engine = apply_moves(engine, engine.current_level);
    engine = apply_rules(engine, engine.current_level, direction, true);

    return engine;

}

// If only one object is found in win condition
bool check_win_condition(Level current_level, str amount, str object) {

    list[Object] found = [];

    for (Coords coords <- current_level.objects<0>) {
        for (Object obj <- current_level.objects[coords]) {
            if (toLowerCase(object) in obj.possible_names) found += obj;
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
                if (toLowerCase(objects[i]) in object.possible_names || toLowerCase(objects[i]) == object.current_name) current += object;
            }
        }  
        if (current != []) {
            found_objects += [current];
            current = [];
        } 
    }

    list[Object] same_pos = [];

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

// Checks if current state satisfies all the win conditions
bool check_win_conditions(Engine engine) {

    PSGame game = engine.game;
    list[ConditionData] lcd = game.conditions;
    list[bool] satisfied = [];

    for (ConditionData cd <- lcd) {
        if (cd is condition_data) {
            if ("on" in cd.condition) {
                satisfied += check_win_condition(engine.current_level, toLowerCase(cd.condition[0]), [cd.condition[1], cd.condition[3]]);
            } else {
                satisfied += check_win_condition(engine.current_level, toLowerCase(cd.condition[0]), cd.condition[1]);
            }
        }
    }

    return all(x <- satisfied, x == true);
}

// Prints the current level
void print_level(Engine engine, Checker c) {

    tuple[int width, int height] level_size = engine.level_data[engine.current_level.original].size;
    for (int i <- [0..level_size.height]) {

        list[str] line = [];

        for (int j <- [0..level_size.width]) {

            list[Object] objects = engine.current_level.objects[<i,j>];
            
            if (size(objects) > 1) line += objects[size(objects) - 1].char;
            else if (size(objects) == 1) line += objects[0].char;
            else line += ".";
        }

        println(intercalate("", line));
        line = [];
    }
    println("");

}