module PuzzleScript::Compiler

import String;
import List;
import Type;
import Set;
import PuzzleScript::Checker;
import PuzzleScript::AST;
import PuzzleScript::Utils;

import IO;

alias Line = list[Object];
alias Layer = list[Line];

data Level
	= level(
		list[Layer] layers, 
		list[list[Layer]] states,
		list[Layer] checkpoint,
		list[set[str]] layerdata,
		list[str] objectdata,
		list[str] player,
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

// TODO: play around with imports	
public str EVAL_PRESET = "
	'import List;
	'import util::Math;
	'
	'str randomDir(){
	'	int rand = arbInt(4);
	'	return <MOVES>[rand];
	'}
	'
	'alias Coords = <#Coords>;
	'data Object
	'= object(str name, int id, Coords coords)
	'| moving_object(str name, int id, str direction, Coords coords)
	'| transparent(str name, int id, Coords coords)
	';
	'alias Line = <#Line>;
	'alias Layer = <#Layer>;
	'
	'Object randomObject(list[Object] objs){
	'	int rand = arbInt(size(objs));
	'	return objs[rand];
	'}
	'
	'
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
	list[RulePart] converted_left,
	list[RulePart] converted_right,
	int used,
	RULEDATA original
];

Rule new_rule(RULEDATA r)
	= <
		false, 
		{}, 
		{}, 
		[], 
		[],
		[],
		[],
		0, 
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
	list[Command] cmd_queue,
	list[str] player,
	map[str, OBJECTDATA] objects,
	list[list[str]] input_log, // keep track of moves made by the player for every level
	PSGAME game
];

Engine new_engine(PSGAME game)		
	= <
		[], 
		level([], [], [], [], [], [], level_data([])), 
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
		[],
		[],
		(),
		
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

alias RuleReference = tuple[
	list[str] objects,
	str reference,
	str force
];

data RuleContent
	= references(list[RuleReference] refs)
	| ellipsis()
	| empty()
	;

//alias RuleContent = list[RuleReference];
alias RulePart = list[RuleContent];

// matching & replacement
str empty_layer(int index, bool _) = "[ *layer<index> ]";
str empty_level(bool _: true) = "[ *level ]";

str layer(int index, list[str] stuff, bool is_pattern) 
	= "[ *prefix_lines<index>, \n\t\t<line(index, stuff, is_pattern)>, \n\t*suffix_lines<index> ]";
	
str line(int index, list[str] stuff, bool _) {
	str compiled_stuff = intercalate(", \n\t\t\t", stuff);
	return "[ *prefix_objects<index>, \n\t\t\t<compiled_stuff>, \n\t\t*suffix_objects<index> ]";
}

str unique(Coords index) = "<index.x>_<index.y>_<index.z>";

//ANY CHANGES TO THE VALUES ON THE RIGHT MUST BE MIRRORED IN THE FUNCTION BELOW
map[str, str] relative_mapping = (
	"\>": "relative_right",
	"\<": "relative_left",
	"v": "relative_down",
	"^": "relative_up"
);

str format_relatives(list[str] absolutes){
	return "
	'str relative_right = \"<absolutes[0]>\";
	'str relative_left = \"<absolutes[1]>\";
	'str relative_down = \"<absolutes[2]>\";
	'str relative_up = \"<absolutes[3]>\";
	";
}

// matching
str absolufy(str force) {
	if (force in absolute_directions_single){
		return "/<force>/";
	} else if (force in relative_mapping){
		return relative_mapping[force];
	} else if (force == "moving"){
		return "/left|right|up|down/";
	} else if (force == "horizontal") {
		return "/left|right/";
	} else if (force == "vertical") {
		return "/up|down/";
	} else if (force == "randomdir") {
		return "randomDir()";
	} else {
		return force;
	}
}

str coords(Coords index, bool _: true)
	= "Coords coords<unique(index)> : \<xcoord<index.x>, ycoord<index.x>, zcoord<unique(index)>\>";

str object(Coords index, RuleReference ref, Engine engine, bool is_pattern: true) {
	str names = intercalate("|", ref.objects);
	str obj_name = "object";
	if (ref.force == "no"){
		names = "^((?!<names>).)*$";
		obj_name = "/object|transparent/";
	}
	return "Object <ref.reference><index.y> : <obj_name>(str name<unique(index)> : /<names>/, int id<unique(index)>, <coords(index, is_pattern)>)";
}

str moving_object(Coords index, RuleReference ref, Engine engine, bool is_pattern: true) {
	str names = intercalate("|", ref.objects);
	return "Object <ref.reference><index.y> : moving_object(str name<unique(index)> : /<names>/, int id<unique(index)>, str direction<unique(index)> : <absolufy(ref.force)>, <coords(index, is_pattern)>)";
}
	
//replacement
str absolufy(str force, Coords index) {
	if (force in absolute_directions_single){
		return "\"<force>\"";
	} else if (force in relative_mapping){
		return relative_mapping[force];
	} else if (force in ["moving", "vertical", "horizontal"]){
		return "direction<unique(index)>";
	} else if (force == "randomdir") {
		return "randomDir()";
	} else {
		return force;
	}
}

str coords(Coords index, bool _: false)
	= "coords<unique(index)>";	
	
str transparent(Coords index)
	= "transparent(\"trans\", -1, coords<unique(index)>)";
	
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
		return "moving_object(\"<ref.objects[0]>\", <id>, <absolufy(ref.force)>, <coords(index, is_pattern)>)";
	} else {
		return "moving_object(name<unique(index)>, id<unique(index)>, <absolufy(ref.force, index)>, <coords(index, is_pattern)>)";
	}
}

str format_compiled_layers(list[list[str]] compiled_layer, bool is_pattern){
	list[str] comp = [];
    for (int l <- [0..size(compiled_layer)]){
    	list[str] lyr = compiled_layer[l];
    	if (isEmpty(lyr)) {
    		comp += [empty_layer(l, is_pattern)];
    	} else {
    		comp += [layer(l, lyr, is_pattern)];
    	}
    }
    
    return "[ \n\t" + intercalate(", \n\t", comp) + "\n ]";
} 

Rule compile_rulepart_left(Rule rule, Engine engine, RulePart left_contents, RulePart right_contents){
	list[list[str]] compiled_layer = [];
	list[set[str]] layers = engine.layers;
	
	for (int b <- [0..size(layers)]){
		set[str] lyr = layers[b];
		list[str] compiled_lines = [];
		for (int i <- [0..size(left_contents)]){
			RuleContent cont = left_contents[i];
			if (cont is references){
				list[RuleReference] refs = cont.refs;
				for (int j <- [0..size(refs)]){
					// index = <section_index, content_index, layer_index>;
					Coords index = <i, j, b>;
					RuleReference ref = refs[j];
					if (!any(str x <- ref.objects, x in lyr)) continue;
			        if (ref.force in ["none", "stationary", "no"]){
			            compiled_lines += [object(index, ref, engine, true)];
			        } else {
			            compiled_lines += [moving_object(index, ref, engine, true)];
			        }
			        // only one item from each layer should exist so if we found the one for the
			        // current layer we can just return, if not, then it's on the user
			        break;
				}
			} else if (cont is ellipsis){
				compiled_lines += ["*ellipsis<b>"];
			} else if (cont is empty){
				compiled_lines += ["empty<i>_<b>"];
			}
		}
		
		compiled_layer += [compiled_lines];
	}
	
	rule.left += [format_compiled_layers(compiled_layer, true)];
	return rule;
}

Rule compile_rulepart_right(Rule rule, Engine engine, RulePart left_contents, RulePart right_contents){
	list[list[str]] compiled_layer = [];
	list[set[str]] layers = engine.layers;
	
	for (int b <- [0..size(layers)]){
		set[str] lyr = layers[b];
		list[str] compiled_lines = [];
		for (int i <- [0..size(right_contents)]){
			RuleContent cont = right_contents[i];
			if (cont is references){
				list[RuleReference] refs = cont.refs;
				for (int j <- [0..size(refs)]){
					// index = <section_index, content_index, layer_index>;
					Coords index = <i, j, b>;
					RuleReference ref = refs[j];
					if (!any(str x <- ref.objects, x in lyr)) continue;
			        if (ref.force in ["none", "stationary"]){
			            compiled_lines += [object(index, ref, engine, false)];
			        } else if (ref.force == "random"){
			        	list[str] objlist = [object(index, <[obj], ref.reference, "none">, engine, false) | str obj <- ref.objects];
			        	str str_objlist = "[" + intercalate(", ", objlist) + "]";
			        	compiled_lines += ["randomObject(<str_objlist>)"];
			        } else {
			            compiled_lines += [moving_object(index, ref, engine, false)];
			        }
			        // only one item from each layer should exist so if we found the one for the
			        // current layer we can just return, if not, then it's on the user
			        break;
				}
			} else if (cont is ellipsis){
				compiled_lines += ["*ellipsis<b>"];
			} else if (cont is empty){
				list[RuleReference] refs = left_contents[i].refs;
				for (int j <- [0..size(refs)]){
					// index = <section_index, content_index, layer_index>;
					Coords index = <i, j, b>;
					RuleReference ref = refs[j];
					if (!any(str x <- ref.objects, x in lyr)) continue;
			        compiled_lines += [transparent(index)];
			        break;
			    }
			}
		}
		compiled_layer += [compiled_lines];
	}
	
	rule.right += [format_compiled_layers(compiled_layer, false)];
	return rule;
}

Rule compile_rulepart(Rule rule, Engine engine, RulePart left, RulePart right){
	rule = compile_rulepart_left(rule, engine, left, right);
	if (!isEmpty(right)) rule = compile_rulepart_right(rule, engine, left, right);
	
	return rule;
}

RulePart convert_rulepart(RULEPART p: part(list[RULECONTENT] _), Rule rule, Checker c, Engine engine, bool is_pattern) {
	RulePart contents = [];
	if (isEmpty(p.contents)) contents += [empty()];
	
	for (int j <- [0..size(p.contents)]){
		RULECONTENT cont = p.contents[j];
		if ("..." in cont.content){
			contents += [ellipsis()];
		} else if (isEmpty(cont.content)){
			contents += [empty()];
		} else {
			list[RuleReference] refs = [];
			//processing direction
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
			contents += [references(refs)];
		}
	}

	return contents;
}

Command convert_command(RULEPART _: command(str cmd)) {
	Command command;
	switch(cmd){
		case /cancel/: command = Command::cancel();
		case /checkpoint/: command = Command::checkpoint();
		case /restart/: command = Command::restart();
		case /win/: command = Command::win();
		case /again/: command = Command::again();
		default: throw "Expected valid command, got <cmd>";
	}
	
	return command;
}

Command convert_command(RULEPART _: sound(str snd)) {
	return Command::sound(snd);
}

Rule convert_rule(RULEDATA r, Checker c, Engine engine){
	Rule rule = new_rule(r);

	list[str] keywords = [toLowerCase(x.prefix) | RULEPART x <- r.left, x is prefix];
	rule.late = "late" in keywords;
	rule.directions = generate_directions(keywords);
	
	list[RulePart] left  = [];
	for (RULEPART p <- [x | RULEPART x <- r.left, x is part]){
		left += [convert_rulepart(p, rule, c, engine, true)];
	}
	
	list[RulePart] right = [];
	for (RULEPART p <- [x | RULEPART x <- r.right, x is part]){
		right += [convert_rulepart(p, rule, c, engine, false)];
	}
	
	for (int i <- [0..size(left)]){
		RulePart right_part;
		if (i < size(right)){
			right_part = right[i];
		} else {
			right_part = [];
		}
		
		rule = compile_rulepart(rule, engine, left[i], right_part);
	}

	rule.converted_left = left;
	rule.converted_right = right;
	rule.commands = {convert_command(x) | RULEPART x <- r.right, x is command || x is sound};
	if (!isEmpty(r.message)) rule.commands += {Command::message(r.message[0])};
	
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
	
	return Level::level(layers, [layers], layers, engine.layers, objectdata, c.references["player"], l);
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
		engine.input_log += [[]];
	}
	
	engine.current_level = engine.levels[0];
	
	for (RULEDATA r <- c.game.rules){
		engine.rules += [convert_rule(r, c, engine)];
	}
	
	engine.objects = (toLowerCase(x.name) : x | x <- c.game.objects);
	
	return engine;
}

