module PuzzleScript::CompilerDennis

import String;
import List;
import Type;
import Set;
import PuzzleScript::CheckerDennis;
import PuzzleScript::AST;
import PuzzleScript::Utils;

import IO;

data Object = object(str char, str current_name, list[str] possible_names, Coords coords, str direction, LayerData layer);
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
    str direction,
	set[str] directions,
	list[RuleContent] left,
	list[RuleContent] right,
	int used,
    map[str, tuple[str, int, str, str, int, int]] movingReplacement,
    map[str, tuple[str, int, str]] aggregateDirReplacement,
	RuleData original
];

Rule new_rule(RuleData r)
	= <
		false, 
		{},
        "", 
		{}, 
		[], 
		[],
		0, 
        (),
        (),
		r
	>;

Rule new_rule(RuleData r, str direction, list[RuleContent] left, list[RuleContent] right)
	= <
		false, 
		{},
        direction, 
		{}, 
		left, 
		right,
		0, 
        (),
        (),
		r
	>;



alias Engine = tuple[
    list[LevelData] levels,
	list[Level] converted_levels,
    list[str] all_objects,
	int current_level,
    map[int, LevelData] level_states,
	map[str, list[int]] sounds,
	list[Condition] conditions,
	list[set[str]] layers,
	list[list[Rule]] rules,
    list[list[Rule]] late_rules,
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

// str format_relatives(list[str] absolutes){
// 	return "
// 	"str relative_right = \"<absolutes[0]>\";
// 	"str relative_left = \"<absolutes[1]>\";
// 	"str relative_down = \"<absolutes[2]>\";
// 	"str relative_up = \"<absolutes[3]>\";
// 	";
// }

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


// Go over each character in the level and convert the character to all possible references
Level convert_level(LevelData level, Checker c) {

    map[str, list[Object]] objects = ();

    for (int i <- [0..size(level.level)]) {

 		list[str] char_list = split("", level.level[i]);
        for (int j <- [0..size(char_list)]) {

            str char = toLowerCase(char_list[j]);
            if (char in c.references<0>) {

                LayerData ld = get_layer(c.references[char][0], c);
                list[Object] object = [object(char, c.references[char][0], get_all_references(char, c.references), <i,j>, 
                    "", ld)];

                if (char in objects) objects[char] += object;
                else objects += (char: object);

            }
            else if (char in c.combinations<0>) {
                
                for (str objectName <- c.combinations[char]) {
                    list[Object] object = [object(char, objectName, get_all_references(char, c.combinations), <i,j>, 
                        "", get_layer(objectName, c))];
                    if (char in objects) objects[char] += object;
                    else objects += (char: object);
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


// ==== DIRECTIONS AND IMPLEMENTATIONS REPRODUCED FROM PUZZLESCRIPTS GITHUB ==== \\

// Directionaggregates translate to multiple other directions
map[str, list[str]] directionaggregates = (
    "horizontal": ["left", "right"],
    "horizontal_par": ["left", "right"],
    "horizontal_perp": ["left", "right"],
    "vertical": ["up", "down"],
    "vertical_par": ["up", "down"],
    "vertical_perp": ["up", "down"],
    "moving": ["up", "down", "left", "right", "action"],
    "orthogonal": ["up", "down", "left", "right"],
    "perpendicular": ["^", "v"],
    "parallel": ["\<", "\>"]
);

list[str] relativeDirections = ["^", "v", "\<", "\>", "perpendicular", "parallel"];
list[str] simpleAbsoluteDirections = ["up", "down", "left", "right"];
list[str] simpleRelativeDirections = ["^", "v", "\<", "\>"];

list[str] relativeDirs = ["^", "v", "\<", "\>", "parallel", "perpendicular"]; //used to index the following
map[str, list[str]] relativeDict = (
    "right": ["up", "down", "left", "right", "horizontal_par", "vertical_perp"],
    "up": ["left", "right", "down", "up", "vertical_par", "horizontal_perp"],
    "down": ["right", "left", "up", "down", "vertical_par", "horizontal_perp"],
    "left": ["down", "up", "right", "left", "horizontal_par", "vertical_perp"]
);

set[value] all_directions = directionaggregates<0> + relativeDict["right"];

bool isDirection (str dir) {

    return (dir in relativeDict["right"] || dir in relativeDirs);

}

// bool directionalRule(list[RulePart] ruleContent) {




// }

// Expanding rules to accompany multiple directions
list[Rule] convert_rule(RuleData rd: rule_data(left, right, _, _), bool late, Checker checker) {

    list[Rule] new_rule_directions = [];
    list[Rule] new_rules = [];
    list[Rule] new_rules2 = [];
    list[Rule] new_rules3 = [];
    list[Rule] new_rules4 = [];

    // Step 1
    new_rule_directions += extend_directions(rd);
    for (Rule rule <- new_rule_directions) {
        Rule absolute_rule = convertRelativeDirsToAbsolute(rule);
        Rule atomized_rule = atomizeAggregates(checker, absolute_rule);
        // Rule synonym_rule = rephraseSynonyms(checker, atomized_rule);
        new_rules += [atomized_rule];
        // new_rules += [rephraseSynonyms(checker, atomized_rule)];
    }

    // Step 2

    // Step 3
    for (Rule rule <- new_rules) {

        new_rules2 += concretizeMovingRule(checker, rule);

    }

    for (Rule rule <- new_rules) {
        rule.late = late;
    }

    return new_rules;


}

list[Rule] extend_directions (RuleData rd: rule_data(left, right, _, _)) {

    list[Rule] new_rule_directions = [];
    Rule cloned_rule = new_rule(rd);

    list[RuleContent] lhs = get_rulecontent(left);
    list[RuleContent] rhs = get_rulecontent(right);

    for (RulePart rp <- left) {
        if (rp is prefix && rp.prefix != "late") {
            str direction = toLowerCase(rp.prefix);

            // AND IS DIRECTIONALRULE (moet nog gedaan worden)
            if (direction in directionaggregates) {
                list[str] directions = directionaggregates[toLowerCase(rp.prefix)];
                for (str direction <- directions) {
                    cloned_rule = new_rule(rd, direction, lhs, rhs);
                    new_rule_directions += cloned_rule;
                }
            }
            else if (direction in simpleAbsoluteDirections) {
                cloned_rule = new_rule(rd, direction, lhs, rhs);
                new_rule_directions += cloned_rule; 
            } 
        }              
    }

    // No direction prefix was registered, meaning all directions apply
    if (cloned_rule.direction == "") {
        list[str] directions = directionaggregates["orthogonal"];
        for (str direction <- directions) {
            cloned_rule = new_rule(rd, direction, lhs, rhs);
            new_rule_directions += cloned_rule;
        }  
    }

    return new_rule_directions;

}

list[RuleContent] get_rulecontent(list[RulePart] ruleparts) {

    for (RulePart rp <- ruleparts) {
        if (rp is part) return rp.contents;
    }
    return [];

}

Rule convertRelativeDirsToAbsolute(Rule rule) {

    str direction = rule.direction;

    list[RuleContent] new_rc = [];
    for (RuleContent rc <- rule.left) {

        if (size(rc.content) == 1) {
            rc.content = [""] + [rc.content[0]];
            new_rc += rc;
            continue;
        }

        for (int i <- [0..size(rc.content)]) {
            int index = indexOf(relativeDirs, rc.content[i]);
            if (index >= 0) rc.content[i] = relativeDict[direction][index];
        }
        new_rc += rc;
    }
    rule.left = new_rc;

    new_rc = [];
    for (RuleContent rc <- rule.right) {

        if (size(rc.content) == 1) {
            rc.content = [""] + [rc.content[0]];
            new_rc += rc;
            continue;
        }

        for (int i <- [0..size(rc.content)]) {
            int index = indexOf(relativeDirs, rc.content[i]);
            if (index >= 0) rc.content[i] = relativeDict[direction][index];
        }
        new_rc += rc;
    }
    rule.right = new_rc;

    return rule;

}

Rule atomizeAggregates(Checker c, Rule rule) {

    list[RuleContent] new_rc = [];
    for (RuleContent rc <- rule.left) {
        list[str] new_content = [];

        for (int i <- [0..size(rc.content)]) {
            
            if (i mod 2 == 1) continue;

            str direction = rc.content[i];
            str object = toLowerCase(rc.content[i+1]);

            if (object in c.combinations<0>) {

                for (int j <- [0..size(c.combinations[object])]) {
                    str new_object = c.combinations[object][j];
                    new_content += [direction] + ["<new_object>"];
                }
            } 
            else {
                new_content += [direction] + [object];
            }
        }

        rc.content = new_content;
        new_rc += rc;
    }
    rule.left = new_rc;

    new_rc = [];
    for (RuleContent rc <- rule.right) {
        list[str] new_content = [];

        for (int i <- [0..size(rc.content)]) {
            if (i mod 2 == 1) continue;

            str direction = rc.content[i];
            str object = toLowerCase(rc.content[i+1]);

            if (object in c.combinations<0>) {

                new_content += [direction];
                for (int j <- [0..size(c.combinations[object])]) {
                    str new_object = c.combinations[object][j];
                    new_content += ["<new_object>"];
                }
            } 
            else {
                new_content += [direction] + [object];
            }
        }
        rc.content = new_content;
        new_rc += rc;
    }
    rule.right = new_rc;

    return rule;

}

// If name has synonym in object section, replace DOES NOT WORK YET
// Rule rephraseSynonyms(Checker c, Rule rule) {

//     for (RuleContent rc <- rule.left) {
//         for (int i <- [0..size(rc.content)]) {
//             str object = rc.content[i];
//             if (object in c.references<0> && size(c.references[object]) == 1) println("<object> references <c.references[object]>");

//         }
//     }
//     for (RuleContent rc <- rule.right) {
//         for (int i <- [0..size(rc.content)]) {
//             str object = rc.content[i];
//             if (object in c.references<0> && size(c.references[object]) == 1) println("<object> references <c.references[object]>");

//         }
//     }
    
//     return rule;

// }

list[Rule] concretizeMovingRule(Checker c, Rule rule) {

    bool shouldRemove;
    bool modified = true;
    list[Rule] result = [rule];

    int begin = 0;

    while(modified) {
        modified = false;
        for (int i <- [begin..size(result)]) {

            Rule rule = result[i];
            shouldRemove = false;
            for (int j <- [0..size(rule.left)]) {

                RuleContent row = rule.left[j];

                list[list[str]] movings = getMovings(row.content);

                if (size(movings) > 0) {
                    shouldRemove = true;
                    modified = true;

                    str name = movings[0][0];
                    str ambiguous_dir = movings[0][1];
                    list[str] concrete_directions = directionaggregates[ambiguous_dir];
                    for (str concr_dir <- concrete_directions) {

                        newrule = new_rule(rule.original, rule.direction, rule.left, rule.right);

                        map[str, tuple[str, int, str, str, int, int]] movingReplacement = ();
                        map[str, tuple[str, int, str]] aggregateDirReplacement = ();

                        for (moveTerm <- rule.movingReplacement<0>) {
                            list[int] moveDat = rule.movingReplacement[moveTerm];
                            newrule.movingReplacement[moveTerm] = [moveDat[0], moveDat[1], moveDat[2], moveDat[3], moveDat[4], moveDat[5]];
                        }

                        for (moveTerm <- rule.aggregateDirReplacement<0>) {
                            list[int] moveDat = rule.aggregateDirReplacement[moveTerm];
                            newrule.aggregateDirReplacement[moveTerm] = [moveDat[0], moveDat[1], moveDat[2]];
                        }
                        
                        newrule.left[j] = concretizeMovingInCell(newrule, newrule.left[j], ambiguous_dir, name, concr_dir);
                        if (size(newrule.right[j].content) > 0) {
                            newrule.right[j] = concretizeMovingInCell(newrule, newrule.right[j], ambiguous_dir, name, concr_dir);
                        }

                        // NOT SURE IF 0 HERE CAN BE LEFT HERE.
                        if (!movingReplacement[name+ambiguous_dir]?) {
                            newrule.movingReplacement[name+ambiguous_dir] = <concr_dir, 1, ambiguous_dir, name, j, 0>;
                        } else {
                            list[int] mr = newrule.movingReplacement[name+ambiguous_dir];

                            if (j != mr[4] || 0 != mr[5]){
                                mr[1] = mr[1] + 1;
                            }
                        }

                        if (!aggregateDirReplacement[ambiguous_dir]?) {
                            newrule.aggregateDirReplacement[ambiguous_dir] = <concr_dir, 1, ambiguous_dir>;
                        } else {
                            newrule.aggregateDirReplacement[ambiguous_dir][1] = aggregateDirReplacement[ambiguous_dir][1] + 1;
                        }

                        result += [newrule];
                    }
                }
            }
            if (shouldRemove) {

                result = remove(result, i);

                if (i >= 1) begin = i - 1;
                else begin = 0;
                break;
            }
        }
    }


    for (int i <- [0..size(result)]) {

        Rule cur_rule = result[i];
        if (!cur_rule.movingReplacement?) {
            continue;
        }

        map[str, list[value]] ambiguous_movement_dict = ();

        for (str name <- cur_rule.movingReplacement<0>) {
            tuple[str, int, str, str, int, int] replacementInfo = cur_rule.movingReplacement[name];
            str concreteMovement = replacementInfo[0];
            int occurrenceCount = replacementInfo[1];
            str ambiguousMovement = replacementInfo[2];
            str ambiguousMovement_attachedObject = replacementInfo[3];

            if (occurrenceCount == 1) {
                //do the replacement
                for (int j <- [0..size(cur_rule.left)]) {
                    RuleContent cellRow_rhs = cur_rule.right[j];
                    for (int k <- [0..size(cellRow_rhs.content)]) {
                        RuleContent cell = cellRow_rhs;
                        cur_rule.right[j] = concretizeMovingInCell(cur_rule, cell, ambiguousMovement, ambiguousMovement_attachedObject, concreteMovement);
                    }
                }
            }
        }

        map[str, str] ambiguous_movement_names_dict = ();
        for (str name <- cur_rule.aggregateDirReplacement<0>) {
            tuple[str, int, str] replacementInfo = cur_rule.aggregateDirReplacement[name];
            str concreteMovement = replacementInfo[0];
            int occurrenceCount = replacementInfo[1];
            str ambiguousMovement = replacementInfo[2];

            if ((ambiguousMovement in ambiguous_movement_names_dict) || (occurrenceCount != 1)) {
                ambiguous_movement_names_dict[ambiguousMovement] = "INVALID";
            } else {
                ambiguous_movement_names_dict[ambiguousMovement] = concreteMovement;
            }

        }

        for (str ambiguousMovement <- ambiguous_movement_dict<0>) {
            if (ambiguousMovement != "INVALID") {
                concreteMovement = ambiguous_movement_dict[ambiguousMovement];
                if (concreteMovement == "INVALID") {
                    continue;
                }
                for (int j <- [0..size(cur_rule.right)]) {
                    RuleContent cellRow_rhs = cur_rule.rhs[j];
                    for (int k <- [0..size(cellRow_rhs.content)]) {
                        RuleContent cell = cellRow_rhs[k];
                        cur_rule.right[j] = concretizeMovingInCellByAmbiguousMovementName(cell, ambiguousMovement, concreteMovement);
                    }
                }
            }
        }  

        for (str ambiguousMovement <- ambiguous_movement_dict<0>) {
            if (ambiguousMovement != "INVALID") {
                concreteMovement = ambiguous_movement_dict[ambiguousMovement];
                if (concreteMovement == "INVALID") {
                    continue;
                }
                for (int j <- [0..size(cur_rule.right)]) {
                    RuleContent cellRow_rhs = cur_rule.rhs[j];
                    for (int k <- [0..size(cellRow_rhs.content)]) {
                        RuleContent cell = cellRow_rhs[k];
                        cur_rule.right[j] = concretizeMovingInCellByAmbiguousMovementName(cell, ambiguousMovement, concreteMovement);
                    }
                }
            }
        }

    }      

    return result;

}

RuleContent concretizeMovingInCellByAmbiguousMovementName(RuleContent rc, str ambiguousMovement, str concreteDirection) {
    
    list[str] new_rc = [];    

    for (int j <- [0..size(rc.content)]) {

        if (j mod 2 == 1) continue;

        if (cell[j] == ambiguousMovement) {
            new_rc += [concr_dir] + [rc.content[i + 1]];
        } else {
            new_rc += [rc.content[i]] + [rc.content[i + 1]];
        }
    }

    rc.content = new_rc;

    return rc;    
}


RuleContent concretizeMovingInCell(Rule rule, RuleContent rc, str ambiguous, str nametomove, str concr_dir) {

    list[str] new_rc = [];

    for (int i <- [0..size(rc.content)]) {

        if (i mod 2 == 1) continue;

        if (rc.content[i] == ambiguous && rc.content[i+1] == nametomove) {
            new_rc += [concr_dir] + [rc.content[i + 1]];
        } else {
            new_rc += [rc.content[i]] + [rc.content[i + 1]];
        }
    }

    rc.content = new_rc;

    return rc;

}

list[list[str]] getMovings(list[str] cell) {

    list[list[str]] result = [];

    for (int i <- [0..size(cell)]) {

        if (i mod 2 == 1) continue;

        str direction = cell[i];
        str name = cell[i + 1];

        if (direction in directionaggregates<0>) {
            result += [[name, direction]];
        }

    }

    return result;


}


Rule concretizePropertyRule(Checker c, Rule rule) {

    // For later
    for (RuleContent rc <- rule.left) {
        rc = expandFixedProperties(c, rc);
    }

    map [str, bool] ambiguous = ();

    for (int i <- [0..size(rule.right)]) {

        RuleContent rc_l = rule.left[i];
        RuleContent rc_r = rule.right[i];

        list[str] properties_left = concat([(rc_l.content[j] in c.references<0>) ? c.references[rc_l.content[j]] : [""] | int j <- [0..size(rc_l.content)]]);
        list[str] properties_right = concat([(rc_r.content[j] in c.references<0>) ? c.references[rc_r.content[j]] : [""] | int j <- [0..size(rc_r.content)]]);

        // for (str property <- properties_right) {

        //     if (!(property in properties_left)) {
                
        //         ambiguous += (property : true);

        //     }

        // }



    }

    return rule;
}

RuleContent expandFixedProperties(Checker c, RuleContent rc) {

    list[str] expanded = [];

    // for (str content <- rc.content) {

    //     println("Content in expandfixed= <content>");


    // }

    return rc;

}

Engine compile(Checker c) {

	Engine engine = new_engine(c.game);
	engine.sounds = (x : c.sound_events[x].seeds | x <- c.sound_events);
	engine.conditions = c.conditions;
    engine.levels = c.game.levels;   

    list[str] all_objects = []; 
    for (LegendData ld <- engine.game.legend) {
        all_objects += toLowerCase(ld.legend);
        for (str object <- ld.values) {
            all_objects += toLowerCase(object);
        }
    }
    engine.all_objects = all_objects;


    for (LevelData ld <- engine.levels) {
        if (ld is level_data) engine.converted_levels += [convert_level(ld, c)];
    }
    // engine.levels = c.game.levels;
    engine.current_level = 1;

    list[RuleData] rules = c.game.rules;

    for (RuleData rule <- rules) {

        if ("late" in [toLowerCase(x.prefix) | x <- rule.left, x is prefix]) engine.late_rules += [convert_rule(rule, true, c)];
        else engine.rules += [convert_rule(rule, false, c)];

    }

    // engine.rules = c.game.rules;

	engine.layers = [convert_layer(x, c) | x <- c.game.layers];
	
	// if (!isEmpty(engine.levels)){
	// 	engine.current_level = engine.levels[0];
	// }
	
	engine.objects = (toLowerCase(x.name) : x | x <- c.game.objects);
	
	return engine;
}

