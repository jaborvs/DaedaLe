module PuzzleScript::Compiler

import String;
import List;
import Type;
import Set;
import PuzzleScript::Checker;
import PuzzleScript::AST;
import PuzzleScript::Utils;

import IO;

data Object = game_object(str char, str current_name, list[str] possible_names, Coords coords, str direction, LayerData layer, int id);
alias Line = list[list[Object]];
alias Layer = list[Line];

data Level (loc src = |unknown:///|)
	= level(
        map[Coords, list[Object]] objects,
		// Layer layer, 
		// list[Layer] checkpoint,
		// list[str] objectdata,
		tuple[Coords, str] player,
		LevelData original
	)
	| message(str msg, LevelData original)
	;

alias Coords = tuple[int x, int y];

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
	list[RulePart] left,
	list[RulePart] right,
	int used,
    map[str, tuple[str, int, str, str, int, int]] movingReplacement,
    map[str, tuple[str, int, str]] aggregateDirReplacement,
    map[str, tuple[str, int]] propertyReplacement,
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
        (),
		r
	>;

Rule new_rule(RuleData r, str direction, list[RulePart] left, list[RulePart] right)
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
        (),
		r
	>;

alias LevelChecker = tuple[
    list[Object] starting_objects,
    list[list[str]] starting_objects_names,
    list[str] moveable_objects,
    int moveable_amount_level,
    tuple[int width, int height] size,
    list[RuleData] actual_applied_rules,
    list[str] shortest_path,
    list[list[Rule]] applied_rules,
    list[list[Rule]] applied_late_rules,
    list[LevelData] messages,
    Level original
];

LevelChecker new_level_checker(Level level) {
    return <[], [], [], 0, <0,0>, [], [], [], [], [], level>;
}


alias Engine = tuple[
    list[LevelData] levels,
	list[Level] converted_levels,
    int all_objects,
	Level current_level,
	list[Condition] conditions,
	list[list[Rule]] rules,
    list[list[Rule]] late_rules,
    map[RuleData, tuple[int, str]] indexed_rules,
	int index,
	map[str, ObjectData] objects,
    map[str, list[str]] properties,
    map[str, list[str]] references,
    map[LevelData, LevelChecker] level_data,
	PSGame game
];

Engine new_engine(PSGame game)		
	= < 
		[],
        [], 
        0,
		message("", level_data([])),
        [],
		[], 
		[],
        (),
		0, 
		(),
		(),
        (),
        (),
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

LayerData get_layer(list[str] object, PSGame game) {

    for (LayerData layer <- game.layers) {
        if (layer is layer_data) {
            for (str layer_item <- layer.layer) {
                if (toLowerCase(layer_item) in object) {
                    return layer;
                }
            }
        }
    }

    return layer_empty("");

}

map[str, str] resolve_player_name(Checker c) {

    map[str, str] start_name = ();
    list[str] possible_names = ["player"];

    if (any(str key <- c.references<0>, size(key) == 1, "player" in c.references[key])) return (key: "player");
    
    // if (any(str key <- c.references<0>, key == "player")) possible_names += c.references[key];
    for (str key <- c.combinations<0>) {
        if ("player" in c.combinations[key]) start_name += (key: "player");
    }
    if (start_name != ()) return start_name;

    possible_names += c.references["player"];
    for (str key <- c.references<0>) {
        if(size(key) == 1, any(str name <- possible_names, name in c.references[key])) start_name += (key: name);
    }
    for (str key <- c.combinations<0>) {
        if (size(key) == 1, any(str name <- possible_names, name in c.combinations[key])) start_name += (key: name);
    }

    return start_name;

}

// tuple[str, str] resolve_player_name(Checker c) {

//     list[str] possible_player_names = [];
//     tuple[str char, str current_name] current_name = <"", "">;

//     if(any(str key <- c.references<0>, str reference <- c.references[key], "player" == reference)) possible_player_names += c.references[key];
//     if(any(str key <- c.combinations<0>, str reference <- c.combinations[key], "player" == reference)) possible_player_names += c.combinations[key];

//     if (possible_player_names == []) {
//         if (any(str key <- c.references<0>, size(key) == 1 && "player" in c.references[key])) return <key, "player">;
//     }


//     for (str name <- c.combinations<0>) {
//         if (any(str ref <- c.combinations[name], ref in possible_player_names, ref == "player")) {
//             return <name, ref>;
//         }
//     }



//     for (str name <- c.references<0>) {

//         if (any(str ref <- c.references[name], size(name) == 1, ref == "player")) {
//             return <name,ref>;
//         }

//         if (any(str ref <- c.references[name], ref in possible_player_names, size(name) == 1)) {
//             return <name, ref>;
//         } 
//     }

//     if (current_name != <"", "">) return current_name;


//     return current_name;

//     // return possible_player_names[0];

// }


// Go over each character in the level and convert the character to all possible references
Level convert_level(LevelData level, Checker c) {

    map[Coords, list[Object]] objects = ();
    tuple[Coords, str] player = <<0,0>, "">;
    map[str, str] player_name = resolve_player_name(c);
    int id = 0;

    for (int i <- [0..size(level.level)]) {

 		list[str] char_list = split("", level.level[i]);

        for (int j <- [0..size(char_list)]) {

            str char = toLowerCase(char_list[j]);

            if (char in player_name<0>) player = <<i,j>, player_name[char]>;

            if (char in c.references<0>) {

                list[str] all_references = get_all_references(char, c.references);
                LayerData ld = get_layer(all_references, c.game);
                str name = c.references[char][0];

                list[Object] object = [game_object(char, name, all_references, <i,j>, "", ld, id)];

                if (<i,j> in objects) objects[<i,j>] += object;
                else objects += (<i,j>: object);

                id += 1;

            }
            else if (char in c.combinations<0>) {
                
                for (str objectName <- c.combinations[char]) {

                    list[str] all_references = get_properties(objectName, c.all_properties);
                    LayerData ld = get_layer(all_references, c.game);

                    list[Object] object = [game_object(char, objectName, all_references, <i,j>, "", ld, id)];
                    if (<i,j> in objects) objects[<i,j>] += object;
                    else objects += (<i,j>: object);
                    id += 1;
                }
                
            }
            else {

                list[str] all_references = get_all_references(char, c.references);
                all_references += [ref | str ref <- get_all_references(char, c.combinations), !(ref in all_references)];
                LayerData ld = get_layer(all_references, c.game);
                str name = "";

                list[Object] object = [game_object(char, name, all_references, <i,j>, "", ld, id)];

                if (<i,j> in objects) objects[<i,j>] += object;
                else objects += (<i,j>: object);

                id += 1;
            }

        }
    }

    return Level::level(
        objects,
		player,
		level        
    );

}


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

bool directionalRule(list[RulePart] left, list[RulePart] right) {

    list[RulePart] left_parts = [rp | RulePart rp <- left, (rp is part)];
    list[RulePart] right_parts = [rp | RulePart rp <- right, (rp is part)];

    bool leftDir = any(int i <- [0..size(left_parts)], int j <- [0..size(left_parts[i].contents)], any(str content <- left_parts[i].contents[j].content, content in relativeDirections));
    bool rightDir = any(int i <- [0..size(right_parts)], int j <- [0..size(right_parts[i].contents)], any(str content <- right_parts[i].contents[j].content, content in relativeDirections));

    return (leftDir || rightDir);

}

// Expanding rules to accompany multiple directions
list[Rule] convert_rule(RuleData rd: rule_data(left, right, x, y), bool late, Checker checker) {

    list[Rule] new_rule_directions = [];
    list[Rule] new_rules = [];
    list[Rule] new_rules2 = [];
    list[Rule] new_rules3 = [];
    list[Rule] new_rules4 = [];

    list[RulePart] new_left = [rp | RulePart rp <- left, rp is part];
    list[RulePart] save_left = [rp | RulePart rp <- left, !(rp is part)];
    list[str] directions = [toLowerCase(rp.prefix) | rp <- save_left, rp is prefix && replaceAll(toLowerCase(rp.prefix), " ", "") != "late"];
    str direction = size(directions) > 0 ? directions[0] : "";

    list[RulePart] new_right = [rp | RulePart rp <- right, rp is part];
    list[RulePart] save_right = [rp | RulePart rp <- right, !(rp is part)];

    RuleData new_rd = rule_data(new_left, new_right, x, y);
    new_rd.src = rd.src;

    // Step 1
    new_rule_directions += extend_directions(new_rd, direction);
    for (Rule rule <- new_rule_directions) {
        Rule absolute_rule = convertRelativeDirsToAbsolute(rule);
        Rule atomized_rule = atomizeAggregates(checker, absolute_rule);
        // Rule synonym_rule = rephraseSynonyms(checker, atomized_rule);
        new_rules += [atomized_rule];
        // new_rules += [rephraseSynonyms(checker, atomized_rule)];
    }

    // Step 2
    for (Rule rule <- new_rules) {
        new_rules2 += concretizeMovingRule(checker, rule);
    }

    // Step 3
    for (Rule rule <- new_rules2) {
        new_rules3 += concretizePropertyRule(checker, rule);
    }

    for (Rule rule <- new_rules3) {
        rule.left += save_left;
        rule.right += save_right;
        new_rules4 += rule.late = late;
    }

    return new_rules4;


}

list[Rule] extend_directions (RuleData rd: rule_data(left, right, _, _), str direction) {

    list[Rule] new_rule_directions = [];
    Rule cloned_rule = new_rule(rd);

    list[RuleContent] lhs = get_rulecontent(left);
    list[RuleContent] rhs = get_rulecontent(right);

    // for (RulePart rp <- left) {
    //     if (rp is prefix && rp.prefix != "late") {

    if (direction in directionaggregates && directionalRule(left, right)) {
        list[str] directions = directionaggregates[toLowerCase(direction)];
        // list[str] directions = directionaggregates[toLowerCase(rp.prefix)];

        for (str direction <- directions) {
            cloned_rule = new_rule(rd, direction, left, right);
            new_rule_directions += cloned_rule;
        }
    }
    // else {
    //     cloned_rule = new_rule(rd, direction, left, right);
    //     new_rule_directions += cloned_rule; 
    // } 
    //     }        
    // }

    // No direction prefix was registered, meaning all directions apply
    if (cloned_rule.direction == "" && directionalRule(left, right)) {
        list[str] directions = directionaggregates["orthogonal"];
        for (str direction <- directions) {
            cloned_rule = new_rule(rd, direction, left, right);
            new_rule_directions += cloned_rule;
        }  
    } else if (cloned_rule.direction == "") {
        cloned_rule = new_rule(rd, "up", left, right);
        new_rule_directions += cloned_rule;

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

    list[RulePart] new_rp = [];
    list[RuleContent] new_rc = [];
    
    for (RulePart rp <- rule.left) {
        
        new_rc = [];

        if (!(rp is part)) {
            new_rp += rp; 
            continue;
        }

        for (RuleContent rc <- rp.contents) {

            list[str] new_content = [];

            if (size(rc.content) == 1) {
                rc.content = [""] + [rc.content[0]];
                new_rc += rc;
                continue;
            }

            str dir = "";
            bool skip = false;
            for (int i <- [0..size(rc.content)]) {
                
                if (skip) {
                    skip = false;
                    continue;
                }

                if (toLowerCase(rc.content[i]) in simpleAbsoluteDirections) {
                    new_content += [toLowerCase(rc.content[i])] + [rc.content[i + 1]];
                    skip = true;
                    continue;                    
                }

                int index = indexOf(relativeDirs, rc.content[i]);
                if (index >= 0) {
                    dir = relativeDict[direction][index];
                    new_content += [dir] + [rc.content[i + 1]];
                    skip = true;
                } else {
                    new_content += [""] + [rc.content[i]];
                }
                // new_rc += [dir] + [rc.content[i]];
            }
            rc.content = new_content;
            new_rc += rc;
        }

        rp.contents = new_rc;
        new_rp += rp;
    }
    rule.left = new_rp;

    new_rp = [];
    
    for (RulePart rp <- rule.right) {

        new_rc = [];

        if (!(rp is part)) {
            new_rp += rp; 
            continue;
        }  

        for (RuleContent rc <- rp.contents) {

            list[str] new_content = [];

            if (size(rc.content) == 1) {
                rc.content = [""] + [rc.content[0]];
                new_rc += rc;
                continue;
            }

            str dir = "";
            bool skip = false;
            for (int i <- [0..size(rc.content)]) {
                
                if (skip) {
                    skip = false;
                    continue;
                }

                int index = indexOf(relativeDirs, rc.content[i]);
                if (index >= 0) {
                    dir = relativeDict[direction][index];
                    new_content += [dir] + [rc.content[i + 1]];
                    skip = true;
                } else {
                    new_content += [""] + [rc.content[i]];
                }
                // new_rc += [dir] + [rc.content[i]];
            }
            rc.content = new_content;
            new_rc += rc;
        }

        rp.contents = new_rc;
        new_rp += rp;
    }
    
    rule.right = new_rp;

    return rule;

}

Rule atomizeAggregates(Checker c, Rule rule) {

    list[RuleContent] new_rc = [];
    list[RulePart] new_rp = [];

    for (RulePart rp <- rule.left) {

        new_rc = [];

        if (!(rp is part)) {
            new_rp += rp; 
            continue;
        }

        for (RuleContent rc <- rp.contents) {
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
        
        rp.contents = new_rc;
        new_rp += rp;       
    }
    rule.left = new_rp;

    new_rp = [];

    for (RulePart rp <- rule.right) {

        if (!(rp is part)) {
            new_rp += rp; 
            continue;
        }

        new_rc = [];
        for (RuleContent rc <- rp.contents) {
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

        rp.contents = new_rc;
        new_rp += rp;
    }
    rule.right = new_rp;

    return rule;

}

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

                RulePart rp = rule.left[j];

                if (!(rp is part)) continue;
                for (int k <- [0..size(rp.contents)]) {

                    RuleContent row = rp.contents[k];

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
                            
                            newrule.left[j].contents[k] = concretizeMovingInCell(newrule, newrule.left[j].contents[k], ambiguous_dir, name, concr_dir);
                            if (size(newrule.right[j].contents[k].content) > 0) {
                                newrule.right[j].contents[k] = concretizeMovingInCell(newrule, newrule.right[j].contents[k], ambiguous_dir, name, concr_dir);
                            }

                            // NOT SURE IF 0 HERE CAN BE LEFT HERE.
                            if (!movingReplacement[name+ambiguous_dir]?) {
                                newrule.movingReplacement[name+ambiguous_dir] = <concr_dir, 1, ambiguous_dir, name, k, 0>;
                            } else {
                                list[int] mr = newrule.movingReplacement[name+ambiguous_dir];

                                if (k != mr[4] || 0 != mr[5]){
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

                for (int l <- [0..size(cur_rule.left)]) {
                    if (!(cur_rule.left[l] is part)) continue;
                    for (int j <- [0..size(cur_rule.left[l].contents)]) {
                        RuleContent cellRow_rhs = cur_rule.right[l].contents[j];
                        for (int k <- [0..size(cellRow_rhs.content)]) {
                            RuleContent cell = cellRow_rhs;
                            cur_rule.right[l].contents[j] = concretizeMovingInCell(cur_rule, cell, ambiguousMovement, ambiguousMovement_attachedObject, concreteMovement);
                        }
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


list[Rule] concretizePropertyRule(Checker c, Rule rule) {

    // For later

    for (int i  <- [0..size(rule.left)]) {

        RulePart rp = rule.left[i];
        if (!(rp is part)) continue;

        for (int j <- [0..size(rp.contents)]) {
            rule.left[i].contents[j] = expandNoPrefixedProperties(c, rule, rule.left[i].contents[j]);
            if (size(rule.right) > 0) rule.right[i].contents[j] = expandNoPrefixedProperties(c, rule, rule.right[i].contents[j]);
        }
    }

    map [str, bool] ambiguous = ();

    for (int i <- [0..size(rule.right)]) {

        RulePart rp = rule.right[i];

        for (int j <- [0..size(rp.contents)]) {
            RuleContent rc_l = rule.left[i].contents[j];
            RuleContent rc_r = rule.right[i].contents[j];

            list[str] properties_left = [rc_l.content[k] | int k <- [0..size(rc_l.content)], rc_l.content[k] in c.all_properties<0>];
            list[str] properties_right = [rc_r.content[k] | int k <- [0..size(rc_r.content)], rc_r.content[k] in c.all_properties<0>];

            for (str property <- properties_right) {
                if (!(property in properties_left)) ambiguous += (property: true);
            }
        }
    }

    bool shouldRemove;
    list[Rule] result = [rule];
    bool modified = true;

    int begin = 0;

    while(modified) {

        modified = false;
        for (int i <- [begin..size(result)]) {

            Rule cur_rule = result[i];
            shouldRemove = false;

            for (int j <- [0..size(cur_rule.left)]) {

                RulePart rp = cur_rule.left[j];
                if (!(rp is part)) continue;

                for (int k <- [0..size(rp.contents)]) {
                    if (shouldRemove) break;

                    RuleContent rc = cur_rule.left[j].contents[k];

                    list[str] properties = [rc.content[l] | int l <- [0..size(rc.content)], rc.content[l] in c.all_properties<0>];

                    for (str property <- properties) {

                        if (!ambiguous[property]?) {
                            continue;
                        }

                        list[str] aliases = c.all_properties[property];

                        shouldRemove = true;
                        modified = true;

                        for (str concreteType <- aliases) {

                            newrule = new_rule(cur_rule.original, cur_rule.direction, cur_rule.left, cur_rule.right);
                            newrule.movingReplacement = cur_rule.movingReplacement;
                            newrule.aggregateDirReplacement = cur_rule.aggregateDirReplacement;

                            map[str, tuple[str, int]] propertyReplacement = ();

                            for (str property <- cur_rule.propertyReplacement<0>) {
                                
                                tuple[str, int] propDat = cur_rule.propertyReplacement[property];
                                newrule.propertyReplacement[property] = <propDat[0], propDat[1]>;

                            }

                            newrule.left[j].contents[k] = concretizePropertyInCell(newrule, newrule.left[j].contents[k], property, concreteType);
                            if (size(newrule.right) > 0) {
                                newrule.right[j].contents[k] = concretizePropertyInCell(newrule, newrule.right[j].contents[k], property, concreteType);
                            }

                            if (!newrule.propertyReplacement[property]?) {
                                newrule.propertyReplacement[property] = <concreteType, 1>;
                            } else {
                                newrule.propertyReplacement[property][1] = newrule.propertyReplacement[property][1] + 1;
                            }

                            result += [newrule];

                        }
                        break;

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
        
    }

    return result;
}

RuleContent concretizePropertyInCell(Rule rule, RuleContent rc, str property, str concreteType) {
    
    list[str] new_rc = [];    

    for (int j <- [0..size(rc.content)]) {

        if (j mod 2 == 1) continue;

        if (rc.content[j + 1] == property && rc.content[j] != "random") {
            new_rc += [rc.content[j]] + [concreteType];
        } else {
            new_rc += [rc.content[j]] + [rc.content[j + 1]];
        }
    }

    rc.content = new_rc;

    return rc;    
}

RuleContent expandNoPrefixedProperties(Checker c, Rule rule, RuleContent rc) {

    list[str] new_rc = [];

    for (int i <- [0..size(rc.content)]) {

        if (i mod 2 == 1) continue;
        str dir = rc.content[i];
        str name = rc.content[i + 1];

        if (dir == "no" && name in c.all_properties<0>) {

            for (str name <- c.all_properties[name]) {
                new_rc += [dir] + [name];
            }

        } else {
            new_rc += [dir] + [name];
        }
    }

    rc.content = new_rc;

    return rc;

}

LevelChecker get_moveable_objects(Engine engine, LevelChecker lc, Checker c, list[RuleContent] rule_side) {

    list[str] found_objects = ["player"];

    for (RuleContent rc <- rule_side) {
        for (int i <- [0..(size(rc.content))]) {
            if (i mod 2 == 1) continue;
            str dir = rc.content[i];
            str name = rc.content[i + 1];
            if (isDirection(dir)) {
                if (!(name in found_objects)) found_objects += [name];
                list[str] all_references = get_references(name, c.references);
                found_objects += [name | str name <- get_references(name, c.references), 
                    any(list[str] l_name <- lc.starting_objects_names, name in l_name)];
                found_objects += [name | str name <- get_references(name, c.combinations), 
                    any(list[str] l_name <- lc.starting_objects_names, name in l_name)];
            }
        }
    } 

    lc.moveable_objects += dup(found_objects);
    return lc;


}

LevelChecker moveable_objects_in_level(Engine engine, LevelChecker lc, Checker c, Level level) {

    for (list[Rule] lrule <- lc.applied_rules) {
        for (RulePart rp <- lrule[0].left) {
            if (rp is part) lc = get_moveable_objects(engine, lc, c, rp.contents);
        }
        for (RulePart rp <- lrule[0].right) {
            if (rp is part) lc = get_moveable_objects(engine, lc, c, rp.contents);
        }
    }

    lc.moveable_objects = dup(lc.moveable_objects);

    int amount_in_level = 0;

    for (Coords coord <- level.objects<0>) {
        for (Object obj <- level.objects[coord]) {
            if (obj.current_name in lc.moveable_objects) amount_in_level += 1;
        }
    }

    lc.moveable_amount_level = amount_in_level;

    return lc;

}

LevelChecker applied_rules(Engine engine, LevelChecker lc) {

    println("NEW LEVEL \n");

    bool new_objects = true;
    list[list[Rule]] applied_rules = [];
    list[list[Rule]] applied_late_rules = [];

    map[int, list[Rule]] indexed = ();
    map[int, list[Rule]] indexed_late = ();

    for (int i <- [0..size(engine.rules)]) {
        list[Rule] rulegroup = engine.rules[i];
        indexed += (i: rulegroup);
    }
    for (int i <- [0..size(engine.late_rules)]) {
        list[Rule] rulegroup = engine.late_rules[i];
        indexed_late += (i: rulegroup);
    }

    list[list[Rule]] current = engine.rules + engine.late_rules;

    list[list[str]] previous_objs = [];

    while(previous_objs != lc.starting_objects_names) {

        previous_objs = lc.starting_objects_names;

        for (list[Rule] lrule <- current) {
            
            // Each rewritten rule in rulegroup contains same objects so take one
            Rule rule = lrule[0];
            list[str] required = [];

            for (RulePart rp <- rule.left) {
                
                if (!(rp is part)) continue;

                for (RuleContent rc <- rp.contents) {
                    if ("..." in rc.content) continue;
                    required += [name | name <- rc.content, !(name == "no"), !(isDirection(name)), !(name == ""), !(name == "...")];
                }
            }

            int applied = 0;
            list[list[str]] placeholder = lc.starting_objects_names;
            
            for (int i <- [0..size(required)]) {

                str required_rc = required[i];
                if (any(int j <- [0..size(placeholder)], required_rc in placeholder[j])) {
                    applied += 1;
                } else break;

            }

            if (applied == size(required)) {

                // if (!(rule.right[0] is part)) {   
                //     if (rule.late && !(lrule in applied_late_rules)) applied_late_rules += [lrule];
                //     if (!(rule.late) && !(lrule in applied_rules)) {
                //         applied_rules += [lrule];
                //     }
                //     continue;
                // }

                list[list[RuleContent]] list_rc = [rulepart.contents | rulepart <- rule.right, rulepart is part];
                list[list[str]] new_objects_list = [];
                for (list[RuleContent] lrc <- list_rc) {

                    list[str] new_objects = [name | rc <- lrc, name <- rc.content, !(name == "no"), 
                        !(isDirection(name)), !(name == ""), !(name == "..."), 
                        !(any(list[str] objects <- lc.starting_objects_names, name in objects))];

                    if (size(new_objects) > 0) new_objects_list += [new_objects];

                }
                
                lc.starting_objects_names += new_objects_list;

                if (rule.late && !(lrule in applied_late_rules)) applied_late_rules += [lrule];
                if (!(rule.late) && !(lrule in applied_rules)) {
                    applied_rules += [lrule];
                }

            }
        }
    }

    list[list[Rule]] applied_rules_in_order = [];
    list[list[Rule]] applied_late_rules_in_order = [];

    for (int i <- [0..size(indexed<0>)]) {
        if (indexed[i] in applied_rules) applied_rules_in_order += [indexed[i]];
    }
    for (int i <- [0..size(indexed_late<0>)]) {
        if (indexed_late[i] in applied_late_rules) applied_late_rules_in_order += [indexed_late[i]];
    }

    lc.applied_late_rules = applied_late_rules_in_order;
    lc.applied_rules = applied_rules_in_order;

    return lc;

}


LevelChecker starting_objects(Level level, LevelChecker lc) {

    list[Object] all_objects = [];
    list[list[str]] object_names = [];

    for (Coords coords <- level.objects<0>) {
        for (Object obj <- level.objects[coords]) {
            if (!(obj in all_objects)) {
                
                all_objects += obj;
                object_names += [[obj.current_name] + obj.possible_names];
            }
        }
    }
    
    lc.starting_objects = all_objects;
    lc.starting_objects_names = object_names;

    return lc;

}



map[LevelData, LevelChecker] check_game_per_level(Engine engine, Checker c, bool debug=false) {

    map[LevelData, LevelChecker] allLevelData = ();
    PSGame g = engine.game;

    for (Level level <- engine.converted_levels) {

        LevelChecker lc = new_level_checker(level);

        lc.size = <size(level.original.level[0]), size(level.original.level)>;;
        lc = starting_objects(level, lc);
        lc = applied_rules(engine, lc);
        lc = moveable_objects_in_level(engine, lc, c, level);
        allLevelData += (level.original: lc);

    }
    return allLevelData;

}

map[RuleData, tuple[int, str]] index_rules(list[RuleData] rules) {

    map[RuleData, tuple[int, str]] indexed_rules = ();
    int index = 0;

    for (RuleData rd <- rules) {
        str rule_string = convert_rule(rd.left, rd.right);
        indexed_rules += (rd: <index, rule_string>);
        index += 1;
    }

    return indexed_rules;
}

str convert_rule(list[RulePart] left, list[RulePart] right) {

    str rule = "";
    if (any(RulePart rp <- left, rp is prefix)) rule += rp.prefix;

    for (int i <- [0..size(left)]) {
        RulePart rp = left[i];

        if (!(rp is part)) continue;
        rule += " [ ";
        for (RuleContent rc <- rp.contents) {
            for (str content <- rc.content) rule += "<content> ";
            if (i < size(left) - 1) rule += " | ";
        }
        rule += " ] ";
    }

    rule += " -\> ";

    for (int i <- [0..size(right)]) {
        RulePart rp = right[i];

        if (!(rp is part)) continue;
        rule += " [ ";
        for (RuleContent rc <- rp.contents) {
            for (str content <- rc.content) rule += "<content> ";
            if (i < size(right) - 1) rule += " | ";
        }
        rule += " ] ";
    }
    return rule;
}


Engine compile(Checker c) {

	Engine engine = new_engine(c.game);
	// engine.sounds = (x : c.sound_events[x].seeds | x <- c.sound_events);
	engine.conditions = c.conditions;
    engine.levels = c.game.levels;  
    engine.properties = c.all_properties;
    engine.references = c.references;

    for (LevelData ld <- engine.levels) {
        if (ld is level_data) engine.converted_levels += [convert_level(ld, c)];
    }

    engine.current_level = engine.converted_levels[2];

    list[RuleData] rules = c.game.rules;
    for (RuleData rule <- rules) {

        if ("late" in [toLowerCase(x.prefix) | x <- rule.left, x is prefix]) {
            list[Rule] rulegroup = convert_rule(rule, true, c);
            if (size(rulegroup) != 0) engine.late_rules += [rulegroup];
        }
        else {
            list[Rule] rulegroup = convert_rule(rule, false, c);
            if (size(rulegroup) != 0) engine.rules += [rulegroup];
        }

    }

    engine.level_data = check_game_per_level(engine, c);
    engine.indexed_rules = index_rules(engine.game.rules);

    // for (list[Rule] rule <- engine.level_data[engine.current_level.original].applied_late_rules) println(rule[0]);

	// engine.layers = [convert_layer(x, c) | x <- c.game.layers];

	// engine.objects = (x.coords : x | x <- c.game.objects);
	
	return engine;
}

