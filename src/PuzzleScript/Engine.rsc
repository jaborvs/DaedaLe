module PuzzleScript::Engine

import IO;
import String;
import List;
import Type;
import Set;
import PuzzleScript::Checker;
import PuzzleScript::AST;

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
	bool win_keyword
];

list[str] MOVES = ["left", "up", "down", "right"];

Engine new_engine(){		
	return <[], [], level([], level_data([])), (), [], [], 0, false>;
}

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
	
	return engine;
}

str empty_layer(int index)
	= "[ *layer<index> ]";
	
str default_layer(str lines, int index)
	= "[ *prefix_lines<index>, <lines>, *suffix_lines<index> ]";

str default_line(str cells, int index)
	=	"[ *prefix_cells<index>, <cells>, *suffix_cells<index> ]";

map[str, str] convert_part(RULEPART p : part(list[RULECONTENT] contents)){
	list[Object] objs = [];
	
	
	return ();
}

str process_obj(Object _: object(str name, str _), int index){
	return "arg<index> : object(name<index> : \"<name>\", legend<index>)";
}

str generate_rule(list[Object] contents){
	list [str] strings = [];
	
	int index = 0;
	for (Object obj <- contents){
		strings += [process_obj(obj, index)];
		index += 1;
	}
	
	string = intercalate(", ", strings);
	rule = "[*prefix, <string>, *suffix]";
	
	return rule;
}

set[str] generate_directions(list[str] modifiers){
	if (isEmpty(modifiers)) return {"left", "right", "up", "down"};

	set[str] directions = {};
	for (str mo <- modifiers){
		if (mo == "vertical") directions += {"up", "down"};
		if (mo == "horizontal") directions += {"left", "right"};
	}
	
	return directions;
}

Engine apply_rule(Rule rule, Engine engine){
	
	return engine;
}

Engine rewrite(Engine engine, bool late=false){
	list[Rule] rules = [x | Rule x <- engine.rules, x.late == late];
	
	for (Rule rule <- rules){
		engine = apply_rule(rule, engine);
	}
	
	return engine;
}

void game_loop(Checker c){
	Engine engine = compile(c);
	while (true){
		str input = get_input();
		if (input in MOVES){
			engine = do_move(engine, input);
			engine = rewrite(engine, late=false);
			engine = rewrite(engine, late=true);
		} else if (input == "undo"){
			engine = undo(engine);
		} else if (input == "restart"){
			engine = restart(engine);
		}
		
		bool victory = is_victorious(engine);
		if (victory && !is_last(engine)){
			engine = change_level(engine, engine.index + 1);
		} else if (victory) {
			break;
		}
		
		print_level(engine.current_level);
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

list[bool] is_on(Engine engine, list[str] objs, list[str] on){
	list[bool] results = [];
	Level level = engine.current_level;
	
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

bool is_victorious(Engine engine){
	if (engine.win_keyword) return true;
	
	victory = true;
	for (Condition cond <- engine.conditions){
		switch(cond){
			case no_objects(list[str] objs): {
				for (Layer lyr <- engine.current_level.layers){
					// if any objects present then we don't win
					if (any(str x <- objs, x in lyr.objects)) victory = false;
				}
			}
			
			case some_objects(list[str] objs): {
				for (Layer lyr <- engine.current_level.layers){
					// if not any objects present then we dont' win
					if (!any(str x <- objs, x in lyr.objects)) victory = false;
				}
			}
			
			case no_objects_on(list[str] objs, list[str] on): {
				// if any objects are on any of the ons then we don't win
				list[bool] results = is_on(engine, objs, on);
				if (any(x <- results, x)) victory = false;
			}
			
			case some_objects_on(list[str] objs, list[str] on): {
				// if no objects are on any of the ons then we don't win
				list[bool] results = is_on(engine, objs, on);
				if (!isEmpty(results) && !any(x <- results, x)) victory = false;
			}
			
			case all_objects_on(list[str] objs, list[str] on): {
				// if not all objects are on any of the ons then we don't win
				list[bool] results = is_on(engine, objs, on);
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
	
	engine.sounds = c.sound_events;
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

Rule convert_rule(RULEDATA r, Checker c){
	// rework
	list[str] keywords = [toLowerCase(x.prefix) | RULEPART x <- r.left, x is prefix];
	bool late = "late" in keywords;


	list[RulePart] left = [];
	list[RulePart] right = [];
	set[Command] commands = {};
	list[str] prefixes = [];
	
	for (RULEPART p <- r.left){
		if (p is prefix && toLowerCase(p.prefix) != "late"){
			prefixes += [toLowerCase(p.prefix)];
		} else if (p is part) {
			left += [convert_rulepart(p, prefixes, c)];
			prefixes = [];
		}
	}
	
	for (RULEPART p <- r.right){
		if (p is command){
			switch(p){
				case /cancel/: commands += {cancel()};
				case /checkpoint/: commands += {checkpoint()};
				case /restart/: commands += {restart()};
				case /win/: commands += {win()};
				case /again/: commands += {again()};
			}
		} else if (p is sound) {
			commands += {sound(p.sound)};
		} else if (p is part) {
			right += [convert_rulepart(p, [], c)];
		}
	}


	if (!isEmpty(r.message)) commands += {message(r.message[0])};
	
	return <
		late,
		commands,
		left,
		right,
		r
	>;
}

alias RuleReference = tuple[
	list[str] objects,
	str force
];

alias RuleContent = list[RuleReference];

alias RulePart = tuple[
	list[RuleContent] content,
	set[str] directions
];

RulePart convert_rulepart(RULEPART p, list[str] prefixes, Checker c){
	list[RuleContent] contents = [];
	for (RULECONTENT cont <- p.contents){
		RuleContent refs = [];

		for (int i <- [0..size(cont.content)]){
			if (toLowerCase(cont.content[i]) in PuzzleScript::Checker::rulepart_keywords) continue;
			list[str] objs = resolve_reference(cont.content[i], c, p@location).objs;
			str modifier = "none";
			if (i != 0 && toLowerCase(cont.content[i-1]) in PuzzleScript::Checker::rulepart_keywords) modifier = toLowerCase(cont.content[i-1]);
			
			refs += [<objs, modifier>];
		}
		
		contents += [refs];
	}
	
	return <contents, generate_directions(prefixes)>;
}

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
					line += [transparent("trans", ".")];
				} else if (pix[0] == "player") {
					line += [player(pix[0], ch)];
					objects += [pix[0]];
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

Level deep_copy(Level l: level(list[Layer] lyrs, LEVELDATA original)){
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

Engine do_move(Engine engine, str direction){
	Level level = engine.current_level;
	
	level = deep_copy(level);
	
	for (int i <- [0..size(level.layers)]){
		Layer layer = level.layers[i];
		for(int j <- [0..size(layer.lines)]){
			Line line = layer.lines[j];
			for(int k <- [0..size(line)]){
				Object obj = line[k];
				if (line[k] is player){
					level.layers[i].lines[j][k] = moving_player(obj.name, obj.legend, direction);
				}
			}
		}
	}
	
	engine.current_level = level;
	return engine;
}

void play_sound(str event, Engine engine){
	if (event in engine.sounds) {
		println(engine.sounds[event]);
	}
}

