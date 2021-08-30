module PuzzleScript::Engine

import String;
import List;
import Type;
import Set;
import PuzzleScript::Checker;
import PuzzleScript::AST;
import PuzzleScript::Compiler;
import PuzzleScript::Utils;
import util::Eval;

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

// this rotates a level 90 degrees clockwise
// [ [1, 2] , becomes [ [3, 1] ,
//   [3, 4] ]  			[4, 2] ]
// right matching becomes up matching
Level rotate_level(Level level){
	list[Layer] lyrs = [];
	for (Layer lyr <- level.layers){
		list[Line] new_layer = [[] | _ <- [0..size(lyr.lines[0])]];
		for (int i <- [0..size(lyr.lines[0])]){
			for (int j <- [0..size(lyr.lines)]){
				new_layer[i] += [lyr.lines[j][i]];
			}
		}
		
		lyrs += layer([reverse(x) | Line x <- new_layer], lyr.layer, lyr.objects);
	}
	
	level.layers = lyrs; 
	return level;
}

tuple[Engine, Level] apply_rule(Engine engine, Level level, Rule rule){
	//bool match = true;
	//str right = MOVES[index];
	//str up = MOVES[(index+1) % size(MOVES)];
	//str left = MOVES[(index+1) % size(MOVES)];
	//str down = MOVES[(index+1) % size(MOVES)];
	//
	//
	//if (!all(RulePart part <- rule.left, eval("<part.pattern> := level") == result(true))) return level;
	
	
	
	for (Command cmd <- rule.commands){
		if (engine.abort) return <engine, level>;
		engine = run_command(cmd, engine);
	}
	
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
tuple[Engine, Level] do_turn(Engine engine, Level level : level(_, _, _, _)){
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

alias Coords = tuple[int x, int y, int z];

Coords shift_coords(Layer lyr, Coords coords, str direction : "left"){
	if (coords.y - 1 < 0) return coords;
	
	return <coords.x, coords.y - 1, coords.z>;
}

Coords shift_coords(Layer lyr, Coords coords, str direction : "right"){
	if (coords.y + 1 >= size(lyr.lines[coords.x])) return coords;
	
	return <coords.x, coords.y + 1, coords.z>;
}

Coords shift_coords(Layer lyr, Coords coords, str direction : "up"){
	if (coords.x - 1 < 0) return coords;
	
	return <coords.x - 1, coords.y, coords.z>;
}

Coords shift_coords(Layer lyr, Coords coords, str direction : "down"){
	if (coords.x + 1 >= size(lyr.lines)) return coords;
	
	return <coords.x + 1, coords.y, coords.z>;
}

Level move_obstacle(Level level, Coords coords, Coords other_neighbor_coords){
	Object obj = level.layers[coords.z].lines[coords.x][coords.y];
	if (!(obj is moving_object)) return level;
	
	Coords neighbor_coords = shift_coords(level.layers[coords.z], coords, obj.direction);
	if (coords == neighbor_coords) return level;
	
	Object neighbor_obj = level.layers[neighbor_coords.z].lines[neighbor_coords.x][neighbor_coords.y];
	if (!(neighbor_obj is transparent) && neighbor_coords != other_neighbor_coords) level = move_obstacle(level, neighbor_coords, coords);
	
	neighbor_obj = level.layers[neighbor_coords.z].lines[neighbor_coords.x][neighbor_coords.y];
	if (neighbor_obj is transparent) {
		level.layers[coords.z].lines[coords.x][coords.y] = new_transparent();
		level.layers[coords.z].lines[neighbor_coords.x][neighbor_coords.y] = object(obj.name, obj.legend);
	}
	
	return level;
}

Level do_move(Level level){
	for (int i <- [0..size(level.layers)]){
		Layer layer = level.layers[i];
		for(int j <- [0..size(layer.lines)]){
			Line line = layer.lines[j];
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
		for(int j <- [0..size(layer.lines)]){
			Line line = layer.lines[j];
			for(int k <- [0..size(line)]){
				Object obj = line[k];
				if (obj.name in objs){
					bool t = false;
					for (int l <- [0..size(level.layers)]){
						if (level.layers[l].lines[j][k].name in on) t = true;
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
				for (Layer lyr <- level.layers){
					// if any objects present then we don't win
					if (any(str x <- objs, x in lyr.objects)) victory = false;
				}
			}
			
			case some_objects(list[str] objs): {
				for (Layer lyr <- level.layers){
					// if not any objects present then we dont' win
					if (!any(str x <- objs, x in lyr.objects)) victory = false;
				}
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

//TODO
Engine run_command(Command cmd : again(), Engine engine){
	return engine;
}

Engine run_command(Command cmd : checkpoint(), Engine engine){
	engine.current_level.checkpoint = size(engine.current_level.states) - 1;
	return engine;
}
//TODO

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

void print_level(Level _: message(str msg, _)){
	println("#####################################################");
	println(msg);
	println("#####################################################");
}

void print_level(Level l : level(_, _, _, _)){
	for (Layer lyr <- l.layers){
		for (Line line <- lyr.lines) {
			print(intercalate("", [x.legend | x <- line]));
			//print("   ");
			//print(intercalate(" ", line));
			println();
		}
		println();
	}
}

list[Layer] deep_copy(list[Layer] lyrs){
	list[Layer] layers = [];
	for (Layer lyr <- lyrs){
		list[Line] layer = [];
		for (Line lin <- lyr.lines){
			layer += [[x | Object x <- lin]];
		}
		
		layers += [Layer::layer(
			layer, 
			[x | x <- lyr.layer], 
			[x | x <- lyr.objects]
		)];
	}
	
	return layers;
}

Level plan_move(Level level, str direction){	
	for (int i <- [0..size(level.layers)]){
		Layer layer = level.layers[i];
		for(int j <- [0..size(layer.lines)]){
			Line line = layer.lines[j];
			for(int k <- [0..size(line)]){
				Object obj = line[k];
				if (line[k].name == "player"){
					level.layers[i].lines[j][k] = moving_object(obj.name, obj.legend, direction);
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
	println(string);
}

void game_loop(Checker c){
	Engine engine = compile(c);
	while (true){
		<engine, engine.current_level> = do_turn(engine, engine.current_level);
		bool victory = is_victorious(engine, engine.current_level);
		if (victory && is_last(engine)){
			break;
		} else if (victory) {
			engine = change_level(engine, engine.index + 1);
		}
		
		for (str event <- engine.sound_queue){
			play_sound(engine, event);
		}
		
		for (str msg <- engine.msg_queue){
			print_message(msg);
		}
		
		print_level(engine.current_level);
		engine.abort = false;
	}
	
	println("VICTORY");
}
