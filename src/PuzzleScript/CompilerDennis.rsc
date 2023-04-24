module PuzzleScript::CompilerDennis

import String;
import List;
import Type;
import Set;
import PuzzleScript::CheckerDennis;
import PuzzleScript::AST;
import PuzzleScript::Utils;

import IO;

data Object = object(str name, Coords coords, str direction, LayerData layer);
alias Line = list[list[Object]];
alias Layer = list[Line];

data Level (loc src = |unknown:///|)
	= level(
        map[str, list[Object]] objects,
		// Layer layer, 
		// list[Layer] checkpoint,
		// list[str] objectdata,
		list[str] player,
        LevelChecker additional_info,
		LevelData original
	)
	| message(str msg, LevelData original)
	;

alias Coords = tuple[int x, int y];

// data Object (loc src = |unknown:///|)
// 	= object(str name, int id, Coords coords)
// 	| moving_object(str name, int id, str direction, Coords coords)
// 	| transparent(str name, int id, Coords coords)
// 	;

// data Object (loc src = |unknown:///|)
// 	= object(str name, int id, Coords coords)
// 	| moving_object(str name, int id, str direction, Coords coords)
// 	| transparent(str name, int id, Coords coords)
// 	;

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
	list[Level] converted_levels,
	int current_level,
    map[int, LevelData] level_states,
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
        [], 
		0,
        (), 
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

LayerData get_layer(str object, Checker c) {

    for (LayerData layer <- c.game.layers) {
        if (layer is layer_data) {
            for (str layer_item <- layer.layer) {
                if (toLowerCase(layer_item) == object) {
                    return layer;
                }
            }
        }
    }

    return layer_empty("");

}


Level convert_level(LevelData level, Checker c) {

    map[str, list[Object]] objects = ();

    for (int i <- [0..size(level.level)]) {

 		list[str] char_list = split("", level.level[i]);
        for (int j <- [0..size(char_list)]) {

            str char = toLowerCase(char_list[j]);
            if (char in c.references<0>) {

                LayerData ld = get_layer(c.references[char][0], c);
                list[Object] object = [object(c.references[char][0], <i,j>, "", ld)];

                if (c.references[char][0] in objects) objects[c.references[char][0]] += object;
                else objects += (c.references[char][0]: object);

            }
            else if (char in c.combinations<0>) {
                
                for (str objectName <- c.combinations[char]) {
                    list[Object] object = [object(objectName, <i,j>, "", get_layer(objectName, c))];
                    if (objectName in objects) objects[objectName] += object;
                    else objects += (objectName: object);
                }
                
            }
            else continue;

        }
    }

    // println(c.references);

    return Level::level(
        objects,
		c.references["p"],
        c.level_data[level],
		level        
    );

}

// Level convert_level(LevelData level, Checker c) {

//     // println("Layer list = <c.game.layers>");
//     Layer converted_layer = [[]];

//     for (int i <- [0..size(level.level)]) {

//         Line line = [];

//  		list[str] char_list = split("", level.level[i]);
//         for (int j <- [0..size(char_list)]) {

//             str char = toLowerCase(char_list[j]);
//             if (char in c.references<0>) {

//                 LayerData ld = get_layer(c.references[char][0], c);
//                 line += [[<c.references[char][0], <i,j>, "", ld>]];
//             }
//             else if (char in c.combinations<0>) {
                
//                 list[Object] objects = [];
//                 for (str object <- c.combinations[char]) {
//                     objects += [<object, <i,j>, "", get_layer(object, c)>];
//                 }

//                 line += [objects];
                
//                 // println("char <char> references: <c.combinations[toLowerCase(char)]>");
//             }
//             else continue;
//             // println("char <char> references: <c.references[toLowerCase(char)]>");

//         }
//         converted_layer += [line];

//     }

//     // for (Line line <- converted_layer) {

//     //     for (list[Object] objects <- line) {

//     //         println("First object in at <objects[0].coords> is <objects[0].object>");

//     //     }

//     // }

//     return Level::level(
// 		converted_layer, 
// 		c.references["player"],
//         c.level_data[level],
// 		level
// 	);


// }


Engine compile(Checker c) {

	Engine engine = new_engine(c.game);
	engine.sounds = (x : c.sound_events[x].seeds | x <- c.sound_events);
	engine.conditions = c.conditions;
    engine.levels = c.game.levels;


    for (LevelData ld <- engine.levels) {
        if (ld is level_data) engine.converted_levels += [convert_level(ld, c)];
    }
    // engine.levels = c.game.levels;
    engine.current_level = 1;

    list[RuleData] rules = c.game.rules;

    for (RuleData rule <- rules) {

        if ("late" in [toLowerCase(x.prefix) | x <- rule.left, x is prefix]) engine.late_rules += [rule];
        else engine.rules += [rule];

    }

    // engine.rules = c.game.rules;

	engine.layers = [convert_layer(x, c) | x <- c.game.layers];
	
	// if (!isEmpty(engine.levels)){
	// 	engine.current_level = engine.levels[0];
	// }
	
	engine.objects = (toLowerCase(x.name) : x | x <- c.game.objects);
	
	return engine;
}

