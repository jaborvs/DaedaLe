module PuzzleScript::EngineDennis

import String;
import List;
import Type;
import Set;
import IO;
import PuzzleScript::CheckerDennis;
import PuzzleScript::AST;
import PuzzleScript::Utils;
import PuzzleScript::CompilerDennis;
import util::Eval;
import util::Math;

int MAX_LOOPS = 20;

Level restart(Level level){	
	if (level.states[-1] != level.layers) level.states += [deep_copy(level.layers)];
	
	level.layers = deep_copy(level.checkpoint);
	return level;
}

Level undo(Level level){
	int index;
	if (isEmpty(level.states)) return level;
	
	if (level.layers == level.states[-1]) {
		index = -2;
	} else {
		index = -1;
	}
	
	if(size(level.states) > abs(index)) return level;
	
	level.layers = level.states[index];
	level.states = level.states[0..index];
	
	return level;
}

Level checkpoint(Level level){
	level.checkpoint = deep_copy(level.layers);
	return level;
}

bool is_last(Engine engine){
	return engine.index == size(engine.levels) - 1;
}

Engine change_level(Engine engine, int index){
	engine.current_level = engine.levels[index];
	engine.index = index;
	engine.win_keyword = false;
	engine.abort = false;
	engine.again = false;
	
	return engine;
}

list[str] update_objectdata(Level level){
	set[str] objs = {};
	for (Layer lyr <- level.layers){
		for (Line line <- lyr){
			objs += {x.name | Object x <- line};
		}
	}
	
	return toList(objs);
}

// this rotates a level 90 degrees clockwise
// [ [1, 2] , becomes [ [3, 1] ,
//   [3, 4] ]  			[4, 2] ]
// right matching becomes up matching
list[Layer] rotate_level(list[Layer] layers){
	list[Layer] new_layers = [];
	for (Layer layer <- layers){
		list[Line] new_layer = [[] | _ <- [0..size(layer[0])]];
		for (int i <- [0..size(layer[0])]){
			for (int j <- [0..size(layer)]){
				new_layer[i] += [layer[j][i]];
			}
		}
		
		new_layers += [[reverse(x) | Line x <- new_layer]];
	}
	
	return new_layers;
}

str format_replacement(str pattern, str replacement, list[Layer] layers) {
	return "
	'list[Layer] layers = <layers>;
	'if (<pattern> := layers) layers = <replacement>;
	'layers;
	'";
}

str format_pattern(str pattern, list[Layer] layers){
	return "
	'list[Layer] layers  = <layers>;
	'<pattern> := layers;
	'";
}

map[str, list[str]] directional_absolutes = (
	"right" : ["right", "left",  "down",  "up"], // >
	"left" :  ["left",  "right", "up",    "down"], // <
	"down":   ["down",  "up",    "left",  "right"], // v
	"up" :    ["up",    "down",  "right", "left" ] // ^
);

bool eval_pattern(str pattern, str relatives)
	=	eval(#bool, [EVAL_PRESET, relatives, pattern]).val;

list[str] ROTATION_ORDER = ["right", "up", "left", "down"];

// Applies the rule
// tuple[Engine, Level, Rule] apply_rule(Engine engine, Level level, Rule rule){

//     println("Huidige regel = <rule.left> \n<rule.right>");
//     println("converted = <rule.converted_left> \n<rule.converted_right>");

// 	int loops = 0;
// 	list[Layer] layers = level.layers;
// 	bool changed = false;
// 	for (str dir <- ROTATION_ORDER){
// 		if (dir in rule.directions){

// 			str relatives = format_relatives(directional_absolutes[dir]);

//             // My debugging code, can be removed
//             // int index = 1;
//             // for (str pattern <- rule.left) {
//             //     println("Pattern = <format_pattern(pattern, layers)> <index>");
//             //     // println("Layers:");
//             //     // for (Layer layer <- layers) {
//             //     //     println("\n<layer>\n");
//             //     // }
//             //     index += 1;
//             // }

//             // eval_pattern takes a list of compiled layers (from compile_RulePartContents) defined in compiler
//             // then checks of this pattern matches the layers
// 			while (all(str pattern <- rule.left, eval_pattern(format_pattern(pattern, layers), relatives))){
                
// 				rule.used += 1;
// 				if (isEmpty(rule.right)){
// 					break;
// 				}
//                 // println("level voor eval");
//                 level.layers = layers;
//                 // print_level(level);
				
//                 // println("Level per veranderende layer:");
// 				for (int i <- [0..size(rule.left)]){
//                     println("Vervangt: <rule.left[i]> met: <rule.right[i]>");
// 					layers = eval(#list[Layer], [EVAL_PRESET, relatives, format_replacement(rule.left[i], rule.right[i], layers)]).val;
//                     // level.layers = layers;
//                     // print_level(level);
// 				}

//                 // println("level na eval");
//                 level.layers = layers;
//                 // print_level(level);
				
// 				loops += 1;
				
// 				if (layers == level.layers || loops > MAX_LOOPS){
// 					break;
// 				} else {
// 					changed = true;
// 				}

// 			}
// 		}
		
// 		layers = rotate_level(layers);
// 	}
	
// 	level.layers = layers;
// 	if (!changed) return <engine, level, rule>;
	
// 	for (Command cmd <- rule.commands){
// 		if (engine.abort) return <engine, level, rule>;
// 		engine = run_command(cmd, engine);
// 	}
		
// 	return <engine, level, rule>;
// }

// Applies rules
tuple[Engine, Level] rewrite(Engine engine, Level level, bool late){
	for (int i <- [0..size(engine.rules)]){
		Rule rule = engine.rules[i];
		if (rule.late != late) continue;
		if (engine.abort) break;
		<engine, level, engine.rules[i]> = apply_rule(engine, level, rule);
	}
	
	return <engine, level>;
}

tuple[Engine, Level] do_turn(Engine engine, Level level : level, str input){
	engine.input_log[engine.index] += [input];

	if (input == "undo"){
		return <engine, undo(level)>;
	} else if (input == "restart"){
		return <engine, restart(level)>;
	}
	
	for (int i <- [0..size(engine.rules)]){
		engine.rules[i].used = 0;
	}
	
	// pre-run before the move
	do {
		engine.again = false;
		<engine, level> = rewrite(engine, level, false);
	} while (engine.again && !engine.abort);
	
	if (input in MOVES || input == "action"){
		level = plan_move(level, input);
	}
	
	// run during the move
	do {
		engine.again = false;
		<engine, level> = rewrite(engine, level, false);
	} while (engine.again && !engine.abort);
	
	level = do_move(level);
	
	// post-run after the move
	do {
		engine.again = false;
		<engine, level> = rewrite(engine, level, true);
	} while (engine.again && !engine.abort);
	
	level.objectdata = update_objectdata(level);
	return <engine, level>;
}

tuple[Engine, Level] do_turn(Engine engine, Level level : message(_, _)){
	return <engine, level>;
}

// temporary substitute to getting user input
tuple[str, int] get_input(list[str] moves, int index){
	str move = moves[index];
	index += 1;
	return <move, index>;
}

Coords shift_coords(Layer lyr, Coords coords, str direction : "left"){
	if (coords.y - 1 < 0) return coords;
	
	return <coords.x, coords.y - 1, coords.z>;
}

Coords shift_coords(Layer lyr, Coords coords, str direction : "right"){
	if (coords.y + 1 >= size(lyr[coords.x])) return coords;
	
	return <coords.x, coords.y + 1, coords.z>;
}

Coords shift_coords(Layer lyr, Coords coords, str direction : "up"){
	if (coords.x - 1 < 0) return coords;
	
	return <coords.x - 1, coords.y, coords.z>;
}

Coords shift_coords(Layer lyr, Coords coords, str direction : "down"){
	if (coords.x + 1 >= size(lyr)) return coords;
	
	return <coords.x + 1, coords.y, coords.z>;
}

default Coords shift_coords(_, _, str dir) { 
	throw "expected valid direction, got <dir>"; 
}

Level move_obstacle(Level level, Coords coords, Coords other_neighbor_coords){
	Object obj = level.layers[coords.z][coords.x][coords.y];

	if (!(obj is moving_object)) return level;
	
    // Get coords if were to move in direction stored in moving_object
	Coords neighbor_coords = shift_coords(level.layers[coords.z], coords, obj.direction);
	if (coords == neighbor_coords) return level;
	
    // Get object at this position
	Object neighbor_obj = level.layers[neighbor_coords.z][neighbor_coords.x][neighbor_coords.y];
	if (!(neighbor_obj is transparent) && neighbor_coords != other_neighbor_coords) level = move_obstacle(level, neighbor_coords, coords);
	
	neighbor_obj = level.layers[neighbor_coords.z][neighbor_coords.x][neighbor_coords.y];
	if (neighbor_obj is transparent) {
		level.layers[coords.z][coords.x][coords.y] = new_transparent(coords);
		level.layers[coords.z][neighbor_coords.x][neighbor_coords.y] = object(obj.name, obj.id, neighbor_coords);
	}
	
	return level;
}

// Executes the move that is set in plan_move (moving_object) 
// Level do_move(Level level){
// 	for (int i <- [0..size(level.layers)]){
// 		Layer layer = level.layers[i];
// 		for(int j <- [0..size(layer)]){
// 			Line line = layer[j];
// 			for(int k <- [0..size(line)]){
// 				level = move_obstacle(level, <j, k, i>, <j, k, i>); 
// 			}
// 		}
// 	}
	
// 	if (level.states[-1] != level.layers) level.states += [deep_copy(level.layers)];
// 	return level;
// }

list[bool] is_on(Level level, list[str] objs, list[str] on){
	list[bool] results = [];	
	for (int i <- [0..size(level.layers)]){
		Layer layer = level.layers[i];
		for(int j <- [0..size(layer)]){
			Line line = layer[j];
			for(int k <- [0..size(line)]){
				Object obj = line[k];
				if (obj.name in objs){
					bool t = false;
					for (int l <- [0..size(level.layers)]){
						if (level.layers[l][j][k].name in on) t = true;
					}
					
					results += [t];
				}
			}
		}
	} 


	return results;
}

bool is_met(Condition _, Level level : message)
	= true;

bool is_met(Condition _ : no_objects(list[str] objs, _), Level level : level)
	= !any(str x <- objs, x in level.objectdata);
	
str toString(Condition _ : no_objects(list[str] objs, _)){
	str t = intercalate(", ", objs);
	return "No <t>";
}
	
bool is_met(Condition _ : some_objects(list[str] objs, _), Level level : level)
	= any(str x <- objs, x in level.objectdata);
	
str toString(Condition _ : some_objects(list[str] objs, _)) {
	str t = intercalate(", ", objs);
	return "Some <t>";
}
	
bool is_met(Condition _ : no_objects_on(list[str] objs, list[str] on, _), Level level : level)
	= !any(x <- is_on(level, objs, on), x);
	
str toString(Condition _ : no_objects_on(list[str] objs, list[str] on, _)) {
	str t = intercalate(", ", objs);
	str t2 = intercalate(", ", on);
	return "No <t> On <t2>";
}

	
bool is_met(Condition _ : some_objects_on(list[str] objs, list[str] on, _), Level level : level) {
	list[bool] results = is_on(level, objs, on);
	return isEmpty(results) || any(x <- results, x);
}

str toString(Condition _ : some_objects_on(list[str] objs, list[str] on, _)) {
	str t = intercalate(", ", objs);
	str t2 = intercalate(", ", on);
	return "Some <t> On <t2>";
}
	
bool is_met(Condition _ : all_objects_on(list[str] objs, list[str] on, _), Level level : level) {
	list[bool] results = is_on(level, objs, on);
	return isEmpty(results) || all(x <- results, x);
}

str toString(Condition _ : all_objects_on(list[str] objs, list[str] on, _)) {
	str t = intercalate(", ", objs);
	str t2 = intercalate(", ", on);
	return "All <t> On <t2>";
}

bool is_victorious(Engine engine, Level level){
	if (engine.win_keyword || level is message) return true;
	if (isEmpty(engine.conditions)) return false;
	
	victory = true;
	for (Condition cond <- engine.conditions){
		if (!is_met(cond, level)) victory = false;
	}

	return victory;
}

Engine run_command(Command cmd : again(), Engine engine){
	engine.again = true;
	return engine;
}

Engine run_command(Command cmd : checkpoint(), Engine engine){
	engine.current_level = checkpoint(level);
	return engine;
}

Engine run_command(Command cmd : cancel(), Engine engine){
	engine.abort = true;
	engine.current_level = undo(engine.current_level);
	return engine;
}

Engine run_command(Command cmd : win(), Engine engine){
	engine.abort = true;
	engine.win_keyword = true;
	return engine;
}

Engine run_command(Command cmd : restart(), Engine engine){
	engine.abort = true;
	engine.current_level = restart(engine.current_level);
	return engine;
}


void print_level(Level l: message(str msg, _)){
	print_message(msg);
}


list[Layer] deep_copy(list[Layer] lyrs){
	list[Layer] layers = [];
	for (Layer lyr <- lyrs){
		list[Line] layer = [];
		for (Line lin <- lyr){
			layer += [[x | Object x <- lin]];
		}
		
		layers += [layer];
	}
	
	return layers;
}


void print_message(str string){
	println("#####################################################");
	println(string);
	println("#####################################################");
}

void check_if_applies(list[str] required_objects, bool neighbor, list[str] directions) {

    println(required_objects);

}


bool find_object(Object obj: object(_, _, _, _), Engine engine) {

    // Finds object on position
    if (direction in ["right", "left", "horizontal", "any"]) {

        str name = "";
        // If next object needs to be neighbor
        if (i + 1 <= (size(required) - 1) && required[i + 1] != "...") {
            line += 1;
            name = required[i + 1].name;
            visit(engine.converted_levels[engine.current_level-1]) {
                case n: object(_, _, _, _): {
                    println("Found <n.name> at <coordinate> <line>");
                }
            }
        }
        // If next object does not need to be neighbor
        else if (i + 2 <= size(required) - 1 && required[i + 1] == "...") {
            name = required[i + 2];
            visit(engine.converted_levels[engine.current_level-1]) {
                case n: object(name, <coordinate, _>, _, _): {
                    println("name = <n.name>");
                    break;
                }
            }            
        }


    }
    return true;

}


bool find_object(Object obj: moving_object(_, _, _, _), Engine engine) {

    return true;

}

bool can_be_matched(Engine engine, list[str] required, str direction) {

    // for (str object <- required) {

    // }

    println(required);

    for (int i <- [0..size(required)]) {
        find_object(required[i]);
    }


    tuple[int, int] neighbor_direction = <0,0>;

    int coordinate = 3;
    int line = 0;

    if (direction in ["right", "left", "horizontal"]) {
        neighbor_direction = <0,0>;
    }

    return true;


}

// Ellipsis not accounted for
void apply_rule(Engine engine, Rule rule, list[list[Object]] required, str ruledir, str dir) {

    list[list[Object]] all_objects_in_level = [];
    list[Object] current_objects = [];

    // Get all the coords of the objects
    for (list[Object] objects <- required) {

        current_objects = [];
        for (Object obj <- objects) {
            for (Object object <- engine.current_level.objects[obj.char]) {
                current_objects += object;
            }
        }
        all_objects_in_level += [current_objects];
    }

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

    list[Object] neighboring_objs = [];

    // Find all the neighboring objects in the specified direction
    for (Object object <- all_objects_in_level[0]) {
        neighboring_objs = find_neighbours(all_objects_in_level, object, 0, ruledir, dir_difference);
        if (size(neighboring_objs) == size(required)) {

            println("Rule can be applied for:");
            for (Object object <- neighboring_objs) {

                println("Object with name <object.current_name> at pos <object.coords>");

            }


        };
    }

}

list[Object] find_neighbours(list[list[Object]] all_lists, Object obj1, int index, str direction, Coords dir_difference) {

    list[Object] neighbors = [];

    if (index == 0) neighbors += obj1;

    if (index + 1 < size(all_lists)) {
        if (any(obj2 <- all_lists[index + 1], <obj2.coords[0] - obj1.coords[0], obj2.coords[1] - obj1.coords[1]> == dir_difference) &&
                !(obj2 in neighbors)) {

            neighbors += obj2;
            neighbors += find_neighbours(all_lists, obj2, index + 1, direction, dir_difference);
        } else {
            return [];
        }
    }

    return neighbors;

}



// Apply each rule as many times as possible then move on to next rule
void apply_rules(Engine engine, Level current_level, list[list[Rule]] rules, str direction) {

    list[str] all_objects = engine.all_objects;

    int index = 1;
    for (list[Rule] rulegroup <- rules) {

        for (Rule rule <- rulegroup) {

            list[list[Object]] required_objects = [];
            list[list[str]] directions = [];
            str ruledir = "";

            for (RuleContent rc <- rule.left) {

                ruledir = rule.direction;

                for (int i <- [0..size(rc.content)]) {

                    if (i mod 2 == 1) {
                        continue;
                    }
                    str obj_dir = rc.content[i];
                    str name = toLowerCase(rc.content[i + 1]);

                    list[Object] current_objs = [];

                    for (str object <- current_level.objects<0>) {
                        for (Object obj <- current_level.objects[object]) {
                            if ((name in obj.possible_names) && (obj_dir == obj.direction)) {
                                current_objs += obj;
                            }
                        }
                    }
                    if (current_objs != []) {
                        required_objects += [current_objs];
                    }
                }

            }
            // println("Rule direction = <ruledir>, required objects = <required_objects>");

            // Rule can't be applied
            if (size(required_objects) != size(rule.left)) continue;
            apply_rule(engine, rule, required_objects, ruledir, direction);
        }

        // println("Rule direction = <ruledir>, required objects = <required_objects>");

        // if (can_be_matched(engine, required_objects, direction)) apply_rule();


        index += 1;
    }    



}

bool no_obstacle(Object obj, Level current_level) {

    str dir = obj.direction;

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

    Coords new_pos = <obj.coords[0] + dir_difference[0], obj.coords[1] + dir_difference[1]>;

    visit(current_level) {
        case n: object(_, _, _, new_pos, _, ld): {
            if (ld != obj.layer) println("Found <n.current_name> at <new_pos>");
        }
    }

    return false;

}

void apply_moves(Engine engine, Level current_level) {


    for (str object <- current_level.objects<0>) {

        for (Object obj <- current_level.objects[object]) {

            if (obj.direction != "" && no_obstacle(obj, current_level)) println("Object <obj.current_name> can move <obj.direction>");


        }


    }



}


Engine move_player(Engine engine, Level current_level, str direction) {

    list[Object] objects = [];

    for (Object object <- current_level.objects[current_level.player]) {
        object.direction = direction;
        objects += object;
    }
    current_level.objects[current_level.player] = objects;
    
    engine.current_level = current_level;
    return engine;


}


void apply_late_rules(Engine engine) {

    for (RuleData rd <- engine.late_rules) {
        println("");
    }

}

Engine plan_move(Engine engine, Checker c, str direction) {

    engine = move_player(engine, engine.current_level, direction);
    apply_rules(engine, engine.current_level, engine.rules, direction);
    apply_moves(engine, engine.current_level);
    return engine;

}


Engine do_move(Engine engine, Checker c, str direction) {

    // println(engine.properties);

    // for (list[Object] objects <- engine.current_level.objects<1>) {
    //     for (Object obj <- objects) println("<obj.current_name> possible names = <engine.properties[obj.current_name]>");
    // }

    // apply_rules(engine, engine.current_level, engine.late_rules, direction);

    // for (LevelData current_level <- engine.levels) {
    //     if (current_level is message) {
    //         println(current_level.message);
    //     } else if (current_level is level_data) {
    //         apply_rules(engine.rules, direction);
    //         // apply_rules(engine);
    //     }
    //     // engine.current_level += 1;

    // }

    return engine;



}



