module PuzzleScript::Engine

import IO;
import String;
import List;
import Type;
import Set;
import PuzzleScript::Checker;
import PuzzleScript::AST;
import PuzzleScript::Utils;
import util::Eval;

alias Line = list[Object];

data Layer
	= layer(list[Line] lines, list[str] layer, list[str] objects)
	;

data Level
	= level(list[Layer] layers, LEVELDATA original)
	| message(str msg, LEVELDATA original)
	;
	
data Object
	= player(str name, str legend)
	| moving_player(str name, str legend, str direction)
	| object(str name, str legend)
	| moving_object(str name, str legend, str direction)
	| transparent(str name, str legend)
	;
	
alias Rule = tuple[
	bool late,
	set[Command] commands,
	set[str] directions,
	list[RulePart] left,
	list[RulePart] right,
	RULEDATA original
];
	
alias Engine = tuple[
	list[Level] states,
	list[Level] levels,
	Level current_level,
	map[str, list[int]] sounds,
	list[Condition] conditions,
	list[Rule] rules,
	int index,
	bool win_keyword,
	bool abort,
	bool again,
	int checkpoint,
	list[str] sound_queue,
	list[str] msg_queue
];

list[str] GAME1_LEVEL1_MOVES = ["down"," left"," up"," right"," right"," right"," down"," left"," up"," left"," left"," down"," down"," right"," up"," left"," up"," right"," up"," up"," left"," down"," down"," right"," down"," right"," right"," up"," left"," down"," left"," up"," up"," down"," down"," down"," left", "up"];
list[str] GAME1_LEVEL2_MOVES = [];
list[str] MOVES = GAME1_LEVEL1_MOVES + GAME1_LEVEL2_MOVES;

Rule new_rule(RULEDATA r)
	= <false, {}, {}, [], [], r>; 


Engine new_engine()		
	= <[], [], level([], level_data([])), (), [], [], 0, false, false, false, 0, [], []>;

Engine restart(Engine engine){
	engine.current_level = engine.levels[engine.index];
	
	return engine;
}

Engine undo(Engine engine){
	if (!isEmpty(engine.states)) {
		engine.current_level = engine.states[-1];
		engine.states = engine.states[0..-1];
	}
	
	return engine;
}

bool is_last(Engine engine){
	return size(engine.levels) - 1 > engine.index;
}

Engine change_level(Engine engine, int index){
	engine.current_level = engine.levels[index];
	engine.index = index;
	engine.states = [];
	engine.win_keyword = false;
	engine.abort = false;
	engine.again = false;
	
	return engine;
}

set[str] generate_directions(list[str] modifiers){
	set[str] directions = {};
	for (str mo <- modifiers){
		if (mo == "vertical") directions += {"up", "down"};
		if (mo == "horizontal") directions += {"left", "right"};
		if (mo in ["left", "right", "down", "up"]) directions += {mo};
	}
	
	if (isEmpty(directions)) return {"left", "right", "up", "down"};
	return directions;
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

void game_loop(Checker c){
	Engine engine = compile(c);
	while (true){
		str input = get_input();
		if (input == "undo"){
			engine = undo(engine);
			continue;
		} else if (input == "restart"){
			engine = restart(engine);
			continue;
		}
		
		engine.states += [engine.current_level];
		if (input in MOVES){
			engine.current_level = plan_move(engine.current_level, input);
		}
		
		
		do {
			engine.again = false;
			<engine, engine.current_level> = rewrite(engine, engine.current_level, false);
			<engine, engine.current_level> = rewrite(engine, engine.current_level, true);
		} while (engine.again && !engine.abort);
		
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

// temporary substitute to getting user input
int INDEX = 0;
list[str] MOVE_LIST = ["left"];
str get_input(){
	str move = MOVE_LIST[INDEX];
	if (INDEX == size(MOVE_LIST)-1){
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

Level move_obstacle(Level level, Coords coords){
	Object obj = level.layers[coords.z].lines[coords.x][coords.y];
	if (!(obj is moving_object)) return level;
	
	Coords neighbor_coords = shift_coords(level.layers[coords.z], coords, obj.direction);
	if (coords == neighbor_coords) return level;
	
	Object neighbor_obj = level.layers[neighbor_coords.z].lines[neighbor_coords.x][neighbor_coords.y];
	if (!(neighbor_obj is transparent)) level = move_obstacle(level, neighbor_coords);
	
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
				level = move_obstacle(level, <j, k, i>); 
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
	if (engine.win_keyword) return true;
	
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

Engine compile(Checker c){
	Engine engine = new_engine();
	
	for (LEVELDATA l <- c.game.levels){
		engine.levels += [convert_level(l, c)];
	}
	
	engine.sounds = (x : c.sound_events[x].seeds | x <- c.sound_events);
	engine.conditions = c.conditions;
	engine.current_level = engine.levels[0];
	
	for (RULEDATA r <- c.game.rules){
		engine.rules += [convert_rule(r, c)];
	}
	
	return engine;
}

data Command
	= message(str string)
	| sound(str event)
	| cancel()
	| checkpoint()
	| restart()
	| win()
	| again()
	;

Engine run_command(Command cmd : cancel(), Engine engine){
	engine.abort = true;
	return undo(engine);
}

Engine run_command(Command cmd : checkpoint(), Engine engine){
	return undo(engine);
}

Engine run_command(Command cmd : win(), Engine engine){
	engine.abort = true;
	engine.win_keyword = true;
	return engine;
}

Engine run_command(Command cmd : restart(), Engine engine){
	engine.abort = true;
	return restart(engine);
}

Engine run_command(Command cmd : again(), Engine engine){
	return undo(engine);
}

Engine run_command(Command cmd : message(str string), Engine engine){
	engine.msg_queue += [string];
	return engine;
}

Engine run_command(Command cmd : sound(str event), Engine engine){
	engine.sound_queue += [event];
	return engine;
}

Rule convert_rule(RULEDATA r, Checker c){
	Rule rule = new_rule(r);

	list[str] keywords = [toLowerCase(x.prefix) | RULEPART x <- r.left, x is prefix];
	rule.late = "late" in keywords;
	rule.directions = generate_directions(keywords);
	
	for (RULEPART p <- r.left){
		rule = convert_rulepart(p, rule, c, true);
	}
	
	for (RULEPART p <- r.right){
		rule = convert_rulepart(p, rule, c, false);
	}


	if (!isEmpty(r.message)) rule.commands += {Command::message(r.message[0])};
	
	return rule;
}

alias RuleReference = tuple[
	list[str] objects,
	str force
];

alias RuleContent = list[RuleReference];
alias RulePart = list[RuleContent];


Rule convert_rulepart( RULEPART p: part(list[RULECONTENT] _), Rule rule, Checker c, bool pattern) {
	list[RuleContent] contents = [];
	for (RULECONTENT cont <- p.contents){
		RuleContent refs = [];

		for (int i <- [0..size(cont.content)]){
			if (toLowerCase(cont.content[i]) in rulepart_keywords) continue;
			list[str] objs = resolve_reference(cont.content[i], c, p@location).objs;
			str modifier = "none";
			if (i != 0 && toLowerCase(cont.content[i-1]) in rulepart_keywords) modifier = toLowerCase(cont.content[i-1]);
			
			refs += [<objs, modifier>];
		}
		
		contents += [refs];
	}
	
	if (pattern){ 
		rule.left += [contents];
	} else {
		rule.right += [contents];
	}

	return rule;
}

Rule convert_rulepart( RULEPART p: prefix(str _), Rule rule, Checker c, bool pattern) {
	return rule;
}

Rule convert_rulepart( RULEPART p: command(str cmd), Rule rule, Checker c, bool pattern) {
	switch(cmd){
		case /cancel/: rule.commands += {Command::cancel()};
		case /checkpoint/: rule.commands += {Command::checkpoint()};
		case /restart/: rule.commands += {Command::restart()};
		case /win/: rule.commands += {Command::win()};
		case /again/: rule.commands += {Command::again()};
	}
	
	return rule;
}

Rule convert_rulepart( RULEPART p: sound(str snd), Rule rule, Checker c, bool pattern) {
	rule.commands += {Command::sound(snd)};

	return rule;
}

Object new_transparent() = transparent("trans", ".");

Level convert_level(LEVELDATA l: level_data(list[str] level), Checker c){
	list[Layer] layers = [];
	for (LAYERDATA lyr <- c.game.layers){
		list[str] objs = resolve_references(lyr.layer, c, lyr@location).objs;
		list[Line] layer = [];
		list[str] objects = [];
		for (str charline <- l.level){
			Line line = [];
			list[str] chars = split("", charline);
			for (str ch <- chars){
				list[str] obs = resolve_reference(ch, c, lyr@location).objs;
				pix = [x | str x <- obs, x in objs];
				if (isEmpty(pix)){
					line += [new_transparent()];
				//} else if (pix[0] == "player") {
				//	line += [player(pix[0], ch)];
				//	objects += [pix[0]];
				} else {
					line += [object(pix[0], ch)];
					objects += [pix[0]];
				}
			}
			
			layer += [line];
		}
		
		layers += [Layer::layer(layer, objs, objects)];
	}
	
	return Level::level(layers, l);
}

Level convert_level(LEVELDATA l: message(str msg), Checker c){
	return Level::message(msg, l);
}

void print_level(Level l){
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

Level deep_copy(Level _: level(list[Layer] lyrs, LEVELDATA original)){
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
	
	return Level::level(layers, original);
}

Level plan_move(Level l, str direction){
	Level level = deep_copy(l);
	
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
