module PuzzleScript::Engine

import String;
import List;
import Type;
import Set;
import IO;
import PuzzleScript::Checker;
import PuzzleScript::AST;
import PuzzleScript::Compiler;
import util::Eval;

int MAX_LOOPS = 20;

Level restart(Level level){	
	level.layers = level.states[level.checkpoint];
	level.states = level.states[0..level.checkpoint];
	return level;
}

Level undo(Level level){
	if (!isEmpty(level.states)) {
		level.layers = level.states[-1];
		level.states = level.states[0..-1];
		
		if (size(level.states) - 1 < level.checkpoint) level.checkpoint = -1;
	}
	
	return level;
}

bool is_last(Engine engine){
	return size(engine.levels) - 1 > engine.index;
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
	'<pattern>;
	'";
}

list[str] ROTATION_ORDER = ["right", "up", "left", "down"];
tuple[Engine, Level] apply_rule(Engine engine, Level level, Rule rule){
	
	//check if all ruleparts match
	str check_left = intercalate(" && ", ["<x> := layers" | str x <- rule.left]);
	int loops = 0;
	list[Layer] layers = level.layers;
	bool changed = false;
	for (str dir <- ROTATION_ORDER){
		if (dir in rule.directions){
			println(dir);
			while (eval(#bool, [EVAL_PRESET, format_pattern(check_left, layers)]).val){
				changed = true;
				int index = loops % size(rule.left);
				
				if (isEmpty(rule.right)){
					break;
				}
				
				println(layers);
				println();
				layers = eval(#list[Layer], [EVAL_PRESET, format_replacement(rule.left[index], rule.right[index], layers)]).val;
				loops += 1;
				println(layers);
				
				if (index == 0 && layers == level.layers){
					break;
				} else if (loops > MAX_LOOPS) {
					break;
				}
			}
		}
		
		layers = rotate_level(layers);
	}
	
	level.layers = layers;
	if (!changed) return <engine, level>;
	
	//compile commands to see if we can cheat and just abort
	for (Command cmd <- rule.commands){
		if (engine.abort) return <engine, level>;
		engine = run_command(cmd, engine);
	}
	
	//transform the level
	
	return <engine, level>;
}

tuple[Engine, Level] rewrite(Engine engine, Level level, bool late){
	list[Rule] rules = [x | Rule x <- engine.rules, x.late == late];

	for (Rule rule <- rules){
		if (engine.abort) break;
		<engine, level> = apply_rule(engine, level, rule);
	}
	
	return <engine, level>;
}

list[str] MOVES = ["left", "up", "rigth", "down"];
tuple[Engine, Level] do_turn(Engine engine, Level level : level(_, _, _, _, _, _)){
	str input = get_input();
	if (input == "undo"){
		return <engine, undo(level)>;
	} else if (input == "restart"){
		return <engine, restart(level)>;
	}
	
	if (level.layers notin level.states) level.states += [deep_copy(level.layers)];
	if (input in MOVES){
		level = plan_move(level, input);
	}
	
	do {
		engine.again = false;
		<engine, level> = rewrite(engine, level, false);
		<engine, level> = rewrite(engine, level, true);
	} while (engine.again && !engine.abort);
	
	level.objectdata = update_objectdata(level);
	level = do_move(level);
	
	return <engine, level>;
}

tuple[Engine, Level] do_turn(Engine engine, Level level : message(_, _)){
	return <engine, level>;
}

// temporary substitute to getting user input
int INDEX = 0;
list[str] GAME1_LEVEL1_MOVES = ["down"," left"," up"," right"," right"," right"," down"," left"," up"," left"," left"," down"," down"," right"," up"," left"," up"," right"," up"," up"," left"," down"," down"," right"," down"," right"," right"," up"," left"," down"," left"," up"," up"," down"," down"," down"," left", "up"];
list[str] GAME1_LEVEL2_MOVES = [];
list[str] PLANNED_MOVES = GAME1_LEVEL1_MOVES + GAME1_LEVEL2_MOVES; 
str get_input(){
	str move = PLANNED_MOVES[INDEX];
	if (INDEX >= size(PLANNED_MOVES)){
		INDEX = 0;
	} else {
		INDEX += 1;
	}
	
	return move;
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

Level move_obstacle(Level level, Coords coords, Coords other_neighbor_coords){
	Object obj = level.layers[coords.z][coords.x][coords.y];
	if (!(obj is moving_object)) return level;
	
	Coords neighbor_coords = shift_coords(level.layers[coords.z], coords, obj.direction);
	if (coords == neighbor_coords) return level;
	
	Object neighbor_obj = level.layers[neighbor_coords.z][neighbor_coords.x][neighbor_coords.y];
	if (!(neighbor_obj is transparent) && neighbor_coords != other_neighbor_coords) level = move_obstacle(level, neighbor_coords, coords);
	
	neighbor_obj = level.layers[neighbor_coords.z][neighbor_coords.x][neighbor_coords.y];
	if (neighbor_obj is transparent) {
		level.layers[coords.z][coords.x][coords.y] = new_transparent(coords);
		level.layers[coords.z][neighbor_coords.x][neighbor_coords.y] = object(obj.name, obj.id, neighbor_coords);
	}
	
	return level;
}

Level do_move(Level level){
	for (int i <- [0..size(level.layers)]){
		Layer layer = level.layers[i];
		for(int j <- [0..size(layer)]){
			Line line = layer[j];
			for(int k <- [0..size(line)]){
				level = move_obstacle(level, <j, k, i>, <j, k, i>); 
			}
		}
	}

	return level;
}

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

bool is_victorious(Engine engine, Level level){
	if (engine.win_keyword || level is message) return true;
	
	victory = true;
	for (Condition cond <- engine.conditions){
		switch(cond){
			case no_objects(list[str] objs): {
				// if any objects present then we don't win
				if (any(str x <- objs, x in level.objectdata)) victory = false;
			}
			
			case some_objects(list[str] objs): {
				// if not any objects present then we dont' win
				if (!any(str x <- objs, x in level.objectdata)) victory = false;
			}
			
			case no_objects_on(list[str] objs, list[str] on): {
				// if any objects are on any of the ons then we don't win
				list[bool] results = is_on(level, objs, on);
				if (any(x <- results, x)) victory = false;
			}
			
			case some_objects_on(list[str] objs, list[str] on): {
				// if no objects are on any of the ons then we don't win
				list[bool] results = is_on(level, objs, on);
				if (!isEmpty(results) && !any(x <- results, x)) victory = false;
			}
			
			case all_objects_on(list[str] objs, list[str] on): {
				// if not all objects are on any of the ons then we don't win
				list[bool] results = is_on(level, objs, on);
				if (!isEmpty(results) && !all(x <- results, x)) victory = false;
			}
		}
	}

	return victory;
}

Engine run_command(Command cmd : again(), Engine engine){
	engine.again = true;
	return engine;
}

Engine run_command(Command cmd : checkpoint(), Engine engine){
	engine.current_level.checkpoint = size(engine.current_level.states) - 1;
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

Engine run_command(Command cmd : message(str string), Engine engine){
	engine.msg_queue += [string];
	return engine;
}

Engine run_command(Command cmd : sound(str event), Engine engine){
	engine.sound_queue += [event];
	return engine;
}

void print_level(Level l: message(str msg, _)){
	print_message(msg);
}

void print_level(Level l : level){
	for (Layer lyr <- l.layers){
		for (Line line <- lyr) {
			print(intercalate("", [x.id | x <- line]));
			print("   ");
			print(intercalate(" ", line));
			println();
		}
		println();
	}
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

Level plan_move(Level level, str direction){	
	for (int i <- [0..size(level.layers)]){
		Layer layer = level.layers[i];
		for(int j <- [0..size(layer)]){
			Line line = layer[j];
			for(int k <- [0..size(line)]){
				Object obj = line[k];
				if (line[k].name == "player"){
					level.layers[i][j][k] = moving_object(obj.name, obj.id, direction, <j, k, i>);
				}
			}
		}
	}
	
	return level;
}

void play_sound(Engine engine, str event){
	if (event in engine.sounds) {
		println(engine.sounds[event]);
	}
}

void print_message(str string){
	println("#####################################################");
	println(string);
	println("#####################################################");
}

void game_loop(Checker c){
	Engine engine = compile(c);
	while (true){
		<engine, engine.current_level> = do_turn(engine, engine.current_level);
		
		for (str event <- engine.sound_queue){
			play_sound(engine, event);
		}
		
		for (str msg <- engine.msg_queue){
			print_message(msg);
		}
		
		bool victory = is_victorious(engine, engine.current_level);
		if (victory && is_last(engine)){
			break;
		} else if (victory) {
			engine = change_level(engine, engine.index + 1);
		}
		
		print_level(engine.current_level);
		engine.abort = false;
	}
	
	println("VICTORY");
}
