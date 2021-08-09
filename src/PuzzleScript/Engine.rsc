module PuzzleScript::Engine

import IO;
import String;
import List;
import Type;
import PuzzleScript::Checker;
import PuzzleScript::AST;

alias Line = list[Object];

data Layer
	= layer(list[Line] lines, list[str] layer, list[str] objects)
	;

data Level
	= level(list[Layer] layers)
	| message(str msg)
	;
	
data Object
	= player(str name, str legend)
	| moving_player(str name, str legend, str direction)
	| object(str name, str legend)
	| moving_object(str name, str legend, str direction)
	| transparent(str name, str legend)
	;
	
//alias alt_Line = list[alt_Object];
//
//data alt_Level
//	= level(list[alt_Line] lines)
//	| message(str msg)
//	;
//	
//data alt_Object
//	= player(list[str] names, str legend)
//	| moving_player(list[str] names, str legend, str direction)
//	| object(list[str] names, str legend)
//	| moving_object(list[str] names, str legend, str direction)
//	| transparent(list[str] names, str legend)
//	;
	
alias Engine = tuple[
	list[Level] states,
	list[Level] levels,
	Level current_level,
	map[str, list[int]] sounds,
	list[Condition] conditions
];

Engine new_engine(){		
	return <[], [], level([]), (), []>;
}

Engine restart(Engine engine){
	
	return engine;
}

Engine undo(Engine engine){

	return engine;
}

void game_loop(Checker c){
	Engine engine = compile(c);
	while (!is_victorious(engine)){
		str input = get_input();
		engine = do_move(engine, input);
		engine = rewrite(engine);
		print_level(engine.current_level);
	}
	
	println("VICTORY");
}

str get_input(){
	return "left";
}

Engine rewrite(Engine engine){
	
	return engine;
}

str is_on(Engine engine, list[str] objs, list[str] on){
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


	if (isEmpty(results) || !any(x <- results, x)) return "no";
	if (all(x <- results, x)) return "all";
	
	return "some";
}

bool is_victorious(Engine engine){
	victory = true;
	for (Condition cond <- engine.conditions){
		switch(cond){
			case no_objects(list[str] objs): {
				for (Layer lyr <- engine.current_level.layers){
					if (any(str x <- objs, x in lyr.objects)) victory = false;
				}
			}
			
			case no_objects_on(list[str] objs, list[str] on): {
				if (is_on(engine, objs, on) != "no") victory = false;
			}
			
			case some_objects(list[str] objs): {
				for (Layer lyr <- engine.current_level.layers){
					if (all(str x <- objs, !(x in lyr.objects))) victory = false;
				}
			}
			
			case some_objects_on(list[str] objs, list[str] on): {
				if (is_on(engine, objs, on) != "some") victory = false;
			}
			
			case all_objects_on(list[str] objs, list[str] on): {
				if (is_on(engine, objs, on) != "all") victory = false;
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
	engine.states += [engine.levels[0]];
	
	return engine;
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
				pixel = [x | str x <- obs, x in objs];
				if (isEmpty(pixel)){
					line += [transparent("trans", ".")];
				} else if (pixel[0] == "player") {
					line += [player(pixel[0], ch)];
					objects += [pixel[0]];
				} else {
					line += [object(pixel[0], ch)];
					objects += [pixel[0]];
				}
			}
			
			layer += [line];
		}
		
		layers += [Layer::layer(layer, objs, objects)];
	}
	
	return Level::level(layers);
}

Level convert_level(LEVELDATA l: message(str msg), Checker c){
	return Level::message(msg);
}

void print_level(Level l){
	for (Layer lyr <- l.layers){
		for (Line line <- lyr.lines) {
			print(intercalate("", [x.legend | x <- line]));
			print("   ");
			print(intercalate(" ", line));
			println();
		}
		println();
	}
}

Level deep_copy(Level l: level(list[Layer] lyrs)){
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
	
	return Level::level(layers);
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

