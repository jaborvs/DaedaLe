module PuzzleScript::CompilerDennis

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

data Level (loc src = |unknown:///|)
	= level(
		list[Layer] layers, 
		list[list[Layer]] states,
		list[Layer] checkpoint,
		list[set[str]] layerdata,
		list[str] objectdata,
		list[str] player,
		list[str] background,
		tuple[int height, int width] size,
        LevelChecker additional_info,
		LevelData original
	)
	| message(str msg, LevelData original)
	;
	
alias Coords = tuple[int x, int y, int z];
	
	
// CHANGES DONE TO THIS DATA STRUCTURE NEED TO BE MIRRORED BELOW TO 'EVAL_PRESET'
data Object (loc src = |unknown:///|)
	= object(str name, int id, Coords coords)
	| moving_object(str name, int id, str direction, Coords coords)
	| transparent(str name, int id, Coords coords)
	;

// All kinds of functions to be executed if for example move is random
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
	
data Command (loc src = |unknown:///|)
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
	int used,
	RuleData original
];

Rule new_rule(RuleData r)
	= <
		false, 
		{}, 
		{}, 
		[], 
		[],
		0, 
		r
	>;



alias Engine = tuple[
	list[LevelData] levels,
	LevelData current_level,
	map[str, list[int]] sounds,
	list[Condition] conditions,
	list[set[str]] layers,
	list[RuleData] rules,
    list[RuleData] late_rules,
	int index,
	bool win_keyword,
	bool abort,
	bool again,
	list[str] sound_queue,
	list[str] msg_queue,
	list[Command] cmd_queue,
	map[str, ObjectData] objects,
	list[list[str]] input_log, // keep track of moves made by the player for every level
	PSGame game
];

Engine new_engine(PSGame game)		
	= < 
		[level_data([])], 
		level_data([]), 
        (),
		[], 
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
		(),
		
		[],
		
		game
	>;

ObjectData get_object(int id, Engine engine) 
	= [x | x <- engine.game.objects, x.id == id][0];
	
ObjectData get_object(str name, Engine engine) 
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
alias RulePartContents = list[RuleContent];

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


Command convert_command(RulePartContents _: command(str cmd)) {
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

Command convert_command(RulePartContents _: sound(str snd)) {
	return Command::sound(snd);
}


Object new_transparent(Coords coords) = transparent("trans", -1, coords);

set[str] convert_layer(LayerData l, Checker c){
	set[str] layer = {};
	for (str ref <- l.layer){
		layer +=  toSet(resolve_reference(ref, c, l.src).objs);
	}
	
	return layer;
}


Engine compile(Checker c) {

	Engine engine = new_engine(c.game);
	engine.sounds = (x : c.sound_events[x].seeds | x <- c.sound_events);
	engine.conditions = c.conditions;
    engine.levels = c.game.levels;

    list[RuleData] rules = c.game.rules;

    for (RuleData rule <- rules) {

        if ("late" in [toLowerCase(x.prefix) | x <- rule.left, x is prefix]) engine.late_rules += [rule];
        else engine.rules += [rule];

    }

    // engine.rules = c.game.rules;

	engine.layers = [convert_layer(x, c) | x <- c.game.layers];
	
	if (!isEmpty(engine.levels)){
		engine.current_level = engine.levels[0];
	}
	
	engine.objects = (toLowerCase(x.name) : x | x <- c.game.objects);
	
	return engine;
}

