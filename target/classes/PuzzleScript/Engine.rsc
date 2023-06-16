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
Engine apply(Engine engine, list[Object] neighboring_objs, list[Object] replacements) {

    for (int i <- [0..size(replacements)]) {

        Object replacement = replacements[i];
        Coords neighboring_coords = neighboring_objs[i].coords;

        if (replacement.current_name == "") {

            for (int j <- [0..size(engine.current_level.objects[neighboring_coords])]) {

                Object object = engine.current_level.objects[neighboring_coords][j];
                if (object == neighboring_objs[i]) {
                    engine.current_level.objects[neighboring_coords] = remove(engine.current_level.objects[neighboring_coords], j);
                }

            }
            continue;

        }

        int id = replacement.id;
        str direction = replacement.direction;

        engine.current_level = visit(engine.current_level) {

            case n: game_object(xc, xn, xp_n, xcoords, xdir, xld, id) => {
                game_object(xc, xn, xp_n, neighboring_coords, direction, xld, id);
            }

        };

    }

    return engine;
}

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
Engine apply_rule(Engine engine, Rule rule, list[list[Object]] required, str ruledir, str dir, list[RuleContent] right) {

    Coords dir_difference = get_dir_difference(dir);

    list[Object] neighboring_objs = [];
    list[Object] replacements = [];

    int neighbour_index = 0;

    // Find all the neighboring objects in the specified direction
    for (Object object <- required[0]) {

        neighboring_objs = find_neighbours(required, object, 0, ruledir, dir_difference);
        replacements = [];

        required = remove_ellipsis(required);

        // If enough neighbors are found
        if (size(neighboring_objs) == size(required)) {

            int neighbour_index = 0;

            for (RuleContent rc <- rule.right) {

                if ("..." in rc.content) continue;

                if (size(rc.content) == 0) {
                    replacements += game_object("", "", [], <0,0>, "", layer_empty(""), 0);
                    continue;
                }

                for (int i <- [0..size(rc.content)]) {
                    
                    if (i mod 2 == 1) continue;
                    
                    str direction = rc.content[i];
                    str name = rc.content[i + 1];

                    list[Object] objects = [];

                    for (Coords coord <- engine.current_level.objects<0>) {
                        for (Object obj <- engine.current_level.objects[coord]) {

                            if (obj == neighboring_objs[neighbour_index]) {
                                obj.direction = direction;
                                replacements += obj;
                            }
                        }
                    }
                }
                neighbour_index += 1;
            }

            engine = apply(engine, neighboring_objs, replacements);
        }
    }

    return engine;
}

// Returns a list of all neighboring objects
list[Object] find_neighbours(list[list[Object]] all_lists, Object obj1, int index, str direction, Coords dir_difference) {

    list[Object] neighbors = [];
    bool ellipsis = false;

    if (index == 0) neighbors += obj1;

    if (index + 1 < size(all_lists)) {

        if (all_lists[index + 1][0].current_name == "...") ellipsis = true;

        if (!ellipsis) {
            // Find object next to current object
            if (any(obj2 <- all_lists[index + 1], <obj2.coords[0] - obj1.coords[0], obj2.coords[1] - obj1.coords[1]> == dir_difference) &&
                    !(obj2 in neighbors)) {

                neighbors += obj2;
                neighbors += find_neighbours(all_lists, obj2, index + 1, direction, dir_difference);
            } else {
                return [];
            }
        } else {
            // Find object at same row/column
            if (any(obj2 <- all_lists[index + 2], dir_difference[0] == 0 ? obj2.coords[0] == obj1.coords[0] : obj2.coords[1] == obj1.coords[1]) 
                && !(obj2 in neighbors)) {

                neighbors += obj2;
                neighbors += find_neighbours(all_lists, obj2, index + 2, direction, dir_difference);
            } else {
                return [];
            }

        }
    }

    return neighbors;
}

// Apply each rule as many times as possible then move on to next rule
Engine apply_rules(Engine engine, Level current_level, list[list[Rule]] rules, str direction) {

    list[str] all_objects = engine.all_objects;

    for (list[Rule] rulegroup <- rules) {

        for (Rule rule <- rulegroup) {

            list[list[Object]] old_required_objects = [];
            list[list[Object]] required_objects = [];
            list[list[Object]] right_objects = [];
            str ruledir = "";
            bool can_be_applied = true;

            while (can_be_applied) {

                for (RuleContent rc <- rule.left) {

                    ruledir = rule.direction;

                    for (int i <- [0..size(rc.content)]) {

                        if (i mod 2 == 1) {
                            continue;
                        }
                        str obj_dir = rc.content[i];
                        str name = toLowerCase(rc.content[i + 1]);
                        list[Object] current_objs = [];

                        if (name == "...") {
                            current_objs += game_object("", "...", [], <0,0>, "", layer_empty(""), 0);
                        } else {
                            for (Coords coord <- engine.current_level.objects<0>) {
                                for (Object obj <- engine.current_level.objects[coord]) {

                                    if ((name in obj.possible_names) && (obj_dir == obj.direction)) {
                                        current_objs += obj;
                                    }
                                }
                            }
                        }
                        if (current_objs != []) {
                            required_objects += [current_objs];
                        }
                    }

                }

                // Rule can't be applied
                if (size(required_objects) != size(rule.left) || required_objects == old_required_objects) { 
                    can_be_applied = false;
                }

                else {
                    engine = apply_rule(engine, rule, required_objects, ruledir, direction, rule.right);
                    old_required_objects = required_objects;
                    required_objects = [];
                    current_objs = [];
                }
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

            if (obj.current_name == "player") current_level.player = new_pos;

            break;
        }
    }

    // println("Objects on <old_pos> are now: <current_level.objects[old_pos]>\nObjects on <new_pos> are now: ")

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

    if (same_layer_obj.current_name != "") new_object = same_layer_obj;
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
Engine move_player(Engine engine, Level current_level, str direction) {

    list[Object] objects = [];

    for (Object object <- current_level.objects[current_level.player]) {
        if ("player" in object.possible_names) {
            object.direction = direction;
        }
        objects += object;
    }
    current_level.objects[current_level.player] = objects;
    
    engine.current_level = current_level;
    return engine;

}

// Applies movement, checks which rules apply, executes movement, checks which late rules apply
Engine execute_move(Engine engine, Checker c, str direction) {

    engine = move_player(engine, engine.current_level, direction);
    engine = apply_rules(engine, engine.current_level, engine.rules, direction);
    engine = apply_moves(engine, engine.current_level);
    engine = apply_rules(engine, engine.current_level, engine.late_rules, direction);

    return engine;

}

// If only one object is found in win condition
bool check_win_condition(Level current_level, str amount, str object) {

    list[Object] found = [];

    for (Coords coords <- current_level.objects<0>) {
        for (Object obj <- current_level.objects[coords]) {
            if (toLowerCase(object) in obj.possible_names) found += object;
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
                if (toLowerCase(objects[i]) in object.possible_names) current += object;
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
        return (size(same_pos) == size(found_objects[1]));
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
                satisfied += check_win_condition(engine.current_level, cd.condition[0], [cd.condition[1], cd.condition[3]]);
            } else {
                satisfied += check_win_condition(engine.current_level, cd.condition[0], cd.condition[1]);
            }
        }
    }

    return all(x <- satisfied, x == true);
}

// Prints the current level
void print_level(Engine engine, Checker c) {

    tuple[int width, int height] level_size = c.level_data[engine.current_level.original].size;
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

}