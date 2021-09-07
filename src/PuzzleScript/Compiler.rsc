module PuzzleScript::Compiler

import String;
import List;
import Type;
import Set;
import PuzzleScript::Checker;
import PuzzleScript::AST;
import PuzzleScript::Utils;

alias Line = list[Object];
alias Layer = list[Line];

data Level
	= level(
		list[Layer] layers, 
		list[list[Layer]] states,
		int checkpoint,
		list[set[str]] layerdata,
		list[str] objectdata,
		LEVELDATA original
	)
	| message(str msg, LEVELDATA original)
	;
	
alias Coords = tuple[int x, int y, int z];
	
	
// CHANGES DONE TO THIS DATA STRUCTURE NEED TO BE MIRRORED BELOW TO 'EVAL_PRESET'
data Object
	= object(str name, int id, Coords coords)
	| moving_object(str name, int id, str direction, Coords coords)
	| transparent(str name, int id, Coords coords)
	;
	
public str EVAL_PRESET = "
	'import List;
	'alias Coords = <#Coords>;
	'data Object
	'= object(str name, int id, Coords coords)
	'| moving_object(str name, int id, str direction, Coords coords)
	'| transparent(str name, int id, Coords coords)
	';
	'alias Line = <#Line>;
	'alias Layer = <#Layer>;
	'";
	
data Command
	= message(str string)
	| sound(str event)
	| cancel()
	| checkpoint()
	| restart()
	| win()
	| again()
	;

	
alias Rule = tuple[
	bool late,
	set[Command] commands,
	set[str] directions,
	list[str] left,
	list[str] right,
	RULEDATA original
];

Rule new_rule(RULEDATA r)
	= <
		false, 
		{}, 
		{}, 
		[], 
		[], 
		r
	>;

alias Engine = tuple[
	list[Level] levels,
	Level current_level,
	map[str, list[int]] sounds,
	list[Condition] conditions,
	list[set[str]] layers,
	list[Rule] rules,
	int index,
	bool win_keyword,
	bool abort,
	bool again,
	list[str] sound_queue,
	list[str] msg_queue,
	PSGAME game
];

Engine new_engine(PSGAME game)		
	= <
		[], 
		level([], [], 0, [], [], level_data([])), 
		(), 
		[], 
		[],
		[],
		0, 
		false, 
		false, 
		false, 
		[], 
		[],
		game
	>;

OBJECTDATA get_object(int id, Engine engine) 
	= [x | x <- engine.game.objects, x.id == id][0];
	
OBJECTDATA get_object(str name, Engine engine) 
	= [x | x <- engine.game.objects, toLowerCase(x.name) == name][0];

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

Rule convert_rule(RULEDATA r, Checker c, Engine engine){
	Rule rule = new_rule(r);

	list[str] keywords = [toLowerCase(x.prefix) | RULEPART x <- r.left, x is prefix];
	rule.late = "late" in keywords;
	rule.directions = generate_directions(keywords);
	
	for (RULEPART p <- r.left){
		rule = convert_rulepart(p, rule, c, engine, true);
	}
	
	for (RULEPART p <- r.right){
		rule = convert_rulepart(p, rule, c, engine, false);
	}


	if (!isEmpty(r.message)) rule.commands += {Command::message(r.message[0])};
	
	return rule;
}

alias RuleReference = tuple[
	list[str] objects,
	str reference,
	str force
];

alias RuleContent = list[RuleReference];
alias RulePart = list[RuleContent];

// matching & replacement
str empty_layer(int index, bool _) = "[ *layer<index> ]";
str empty_level(bool _: true) = "[ *level ]";

str layer(int index, list[str] stuff, bool is_pattern) 
	= "[ *prefix_lines<index>, <line(index, stuff, is_pattern)>, *suffix_lines<index> ]";
	
str line(int index, list[str] stuff, bool _) {
	str compiled_stuff = intercalate(", ", stuff);
	return "[ *prefix_objects<index>, <compiled_stuff>, *suffix_objects<index> ]";
}

str unique(Coords index) = "<index.x>_<index.y>_<index.z>";
str absolufy(str force, Coords coords, bool _: true) 
	= "str direction<unique(coords)> : /<force>/";
	
str absolufy(str force, Coords coords, bool _: false) 
	= "\"<force>\"";

// matching
str coords(Coords index, bool _: true)
	= "Coords coords<unique(index)> : \<int xcoord<index.x>, int ycoord<index.x>, int zcoord<unique(index)>\>";

str object(Coords index, RuleReference ref, Engine engine, bool is_pattern: true) {
	str names = intercalate(", ", ref.objects);
	return "Object <ref.objects[0]><index.y> : object(str name<unique(index)> : /<names>/, int id<unique(index)>, <coords(index, is_pattern)>)";
}

str moving_object(Coords index, RuleReference ref, Engine engine, bool is_pattern: true) {
	str names = intercalate(", ", ref.objects);
	return "Object <ref.objects[0]><index.y> : moving_object(str name<unique(index)> : /<names>/, int id<unique(index)>, <absolufy(ref.force, index, is_pattern)>, <coords(index, is_pattern)>)";
}
	
//replacement

str coords(Coords index, bool _: false)
	= "coords<unique(index)>";	
	
str object(Coords index, RuleReference ref, Engine engine, bool is_pattern: false) {
	if (size(ref.objects) == 1){
		int id = get_object(ref.objects[0], engine).id;
		return "object(\"<ref.objects[0]>\", <id>, <coords(index, is_pattern)>)";
	} else {
		return "object(name<unique(index)>, id<unique(index)>, <coords(index, is_pattern)>)";
	}
}

str moving_object(Coords index, RuleReference ref, Engine engine, bool is_pattern: false) {
	if (size(ref.objects) == 1){
		int id = get_object(ref.objects[0], engine).id;
		return "moving_object(\"<ref.objects[0]>\", <id>, <absolufy(ref.force, index, is_pattern)>, <coords(index, is_pattern)>)";
	} else {
		return "moving_object(name<unique>, id<unique(index)>, <absolufy(ref.force, index, is_pattern)>, <coords(index, is_pattern)>)";
	}
}

Rule compile_rulepart(list[RuleContent] contents, Rule rule, Engine engine, bool is_pattern){
	list[list[str]] compiled_layer = [];
	list[set[str]] layers = engine.layers;
	
	for (int b <- [0..size(layers)]){
		set[str] lyr = layers[b];
		list[str] compiled_lines = [];
		for (int i <- [0..size(contents)]){
			RuleContent refs = contents[i];
			for (int j <- [0..size(refs)]){
				// index = <section_index>_<content_index>
				Coords index = <i, j, b>;
				RuleReference ref = refs[j];
				if (!any(str x <- ref.objects, x in lyr)) continue;
		        if (ref.force == "none"){
		            compiled_lines += [object(index, ref, engine, is_pattern)];
		        } else {
		            str direction = ref.force;
		            compiled_lines += [moving_object(index, ref, engine, is_pattern)];
		        }
		        // only one item from each layer should exist so if we found the one for the
		        // current layer we can just return, if not, then it's on the user
		        break;
			}
			
		}
		
		compiled_layer += [compiled_lines];
    }
    
    list[str] comp = [];
    for (int l <- [0..size(compiled_layer)]){
    	list[str] lyr = compiled_layer[l];
    	if (isEmpty(lyr)) {
    		comp += [empty_layer(l, is_pattern)];
    	} else {
    		comp += [layer(l, lyr, is_pattern)];
    	}
    }
    
    if (is_pattern) {
    	rule.left += ["[ " + intercalate(", ", comp) + " ]"];
    } else {
    	rule.right += ["[ " + intercalate(", ", comp) + " ]"];
    }
    
	return rule;
}

Rule convert_rulepart( RULEPART p: part(list[RULECONTENT] _), Rule rule, Checker c, Engine engine, bool is_pattern) {
	list[RuleContent] contents = [];
	for (RULECONTENT cont <- p.contents){
		RuleContent refs = [];

		for (int i <- [0..size(cont.content)]){
			if (toLowerCase(cont.content[i]) in rulepart_keywords) continue;
			list[str] objs = resolve_reference(cont.content[i], c, p@location).objs;
			str force = "none";
			if (i != 0 && toLowerCase(cont.content[i-1]) in rulepart_keywords) force = toLowerCase(cont.content[i-1]);
			
			if (toLowerCase(cont.content[i]) in c.combinations){
				for (str obj <- objs){
					refs += [<obj, toLowerCase(cont.content[i]), force>];
				}
			} else {
				refs += [<objs, toLowerCase(cont.content[i]), force>];
			}
			
		}
		
		contents += [refs];
	}


	return compile_rulepart(contents, rule, engine, is_pattern);
}

Rule convert_rulepart( RULEPART p: prefix(str _), Rule rule, Checker c, Engine engine, bool pattern) {
	return rule;
}

Rule convert_rulepart( RULEPART p: command(str cmd), Rule rule, Checker c, Engine engine, bool pattern) {
	switch(cmd){
		case /cancel/: rule.commands += {Command::cancel()};
		case /checkpoint/: rule.commands += {Command::checkpoint()};
		case /restart/: rule.commands += {Command::restart()};
		case /win/: rule.commands += {Command::win()};
		case /again/: rule.commands += {Command::again()};
	}
	
	return rule;
}

Rule convert_rulepart( RULEPART p: sound(str snd), Rule rule, Checker c, Engine engine, bool pattern) {
	rule.commands += {Command::sound(snd)};

	return rule;
}

Object new_transparent(Coords coords) = transparent("trans", -1, coords);

Level convert_level(LEVELDATA l: level_data(list[str] level), Checker c, Engine engine){
	list[Layer] layers = [];
	list[str] objectdata = [];
	for (int i <- [0..size(engine.layers)]){
		set[str] lyr = engine.layers[i];
		Layer layer = [];
		for (int j <- [0..size(l.level)]){
			str charline = l.level[j];
			Line line = [];
			list[str] chars = split("", charline);
			for (int k <- [0..size(chars)]){
				str ch = chars[k];
				list[str] objs = resolve_reference(ch, c, l@location).objs;
				pix = [x | str x <- objs, x in lyr];
				if (isEmpty(pix)){
					line += [new_transparent(<j, k, i>)];
				} else {
					line += [object(pix[0], get_object(pix[0], engine).id, <j, k, i>)];
					objectdata += [pix[0]];
				}
			}
			
			layer += [line];
		}
		
		layers += [layer];
	}
	
	return Level::level(layers, [], 0, engine.layers, objectdata, l);
}

Level convert_level(LEVELDATA l: message(str msg), Checker c, Engine engine){
	return Level::message(msg, l);
}

set[str] convert_layer(LAYERDATA l, Checker c){
	set[str] layer = {};
	for (str ref <- l.layer){
		layer +=  toSet(resolve_reference(ref, c, l@location).objs);
	}
	
	return layer;
}

Engine compile(Checker c){
	Engine engine = new_engine(c.game);
	engine.sounds = (x : c.sound_events[x].seeds | x <- c.sound_events);
	engine.conditions = c.conditions;
	engine.layers = [convert_layer(x, c) | x <- c.game.layers];
	
	for (LEVELDATA l <- c.game.levels){
		engine.levels += [convert_level(l, c, engine)];
	}
	
	engine.current_level = engine.levels[0];
	
	
	for (RULEDATA r <- c.game.rules){
		engine.rules += [convert_rule(r, c, engine)];
	}
	
	return engine;
}

