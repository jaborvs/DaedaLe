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

void apply_rule() {
    println("");
}

// Apply each rule as many times as possible then move on to next rule
void apply_rules(Engine engine, str direction) {

    list[str] all_objects = engine.all_objects;

    int index = 1;
    for (RuleData rd <- engine.rules) {

        if (!(rd is rule_data)) {
            index +=1; 
            continue;
        }

        list[str] required_objects = [];
        str direction = "any";

        for (RulePart rulepart <- rd.left) {

            if (rulepart is prefix) {
                direction = toLowerCase(rulepart.prefix);
            }

            if (rulepart is part) {
                for (RuleContent content <- rulepart.contents) {
                    for (str content <- content.content) {
                        if (toLowerCase(content) in all_objects || toLowerCase(content) == "...") {
                            required_objects += toLowerCase(content);
                        }
                    }
                }
            }
        }

        if (can_be_matched(engine, required_objects, direction)) apply_rule();

    //     // println(N);
    //     // println()
    //     // println("Left hand rule requires: <required_objects>, neighbor matters = <neighbor>, direction = <direction>");
    //     // println("Rule <index> can be applied:");

    //     // println(rd);

        index += 1;
    }    


}


void apply_late_rules(Engine engine) {

    for (RuleData rd <- engine.late_rules) {
        println("");
    }

}

Engine do_move(Engine engine, Checker c, str direction) {



    for (LevelData current_level <- engine.levels) {

        if (current_level is message) {
            println(current_level.message);
        } else if (current_level is level_data) {
            apply_rules(engine, direction);
            // apply_rules(engine);
        }
        // engine.current_level += 1;

    }

    return engine;



}



