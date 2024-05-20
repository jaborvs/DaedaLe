/*
 * @Module: Compiler
 * @Desc:   Module that compiles the AST.
 * @Auth:   Dennis Vet    -> code
 *          Borja Velasco -> code, comments
 */
module PuzzleScript::Compiler

/*****************************************************************************/
// --- General modules imports ------------------------------------------------
import String;
import List;
import Type;
import Set;
import IO;

/*****************************************************************************/
// --- Own modules imports ----------------------------------------------------
import PuzzleScript::Checker;
import PuzzleScript::AST;
import PuzzleScript::Utils;
import PuzzleScript::Engine;

/*****************************************************************************/
// --- Data structures defines ------------------------------------------------

/*
 * @Name:   Object
 * @Desc:   Data structure to model a game object. Not to be mistaken by DataObject
 *          which models an AST node for an object
 */
data Object = game_object(
    str char,                   // Legend representation char
    str current_name,           // Current name of the object (for references objects)
    list[str] possible_names,   // All objects names (for references objects)
    Coords coords,              // Current position of the object
    str direction,              // Direction to be moved towards
    LayerData layer,            // Layer where it exists
    int id                      // Identifier
    );

/*
 * @Name:   Line
 * @Desc:   Data structure to model a line of a level representation from a 
 *          PuzzleScript file (???)
 */
alias Line = list[list[Object]];

/*
 * @Name:   Layer
 * @Desc:   Data structure to model a layer of PuzzleScript. It (???)
 */
alias Layer = list[Line];

/*
 * @Name:   Level
 * @Desc:   Data structure to model a level. Not to be mistaken by LevelData, 
 *          which represents an AST node of a level
 */
data Level (loc src = |unknown:///|)
    = level(
        map[Coords, list[Object]] objects,  // Coordinate and the list of objects (for different layers)
        tuple[Coords, str] player,          // Tuple: Coordinate of the player and the state (???)
        LevelData original                  // Original AST node
    )
	| message(str msg, LevelData original)  // In between level messages are considered levels
	;

/*
 * @Name:   Coords
 * @Desc:   Data structure to model coordinates
 */
alias Coords = tuple[
    int x,      // x-coordinate
    int y       // y-coordinate
    ];

/*
 * @Name:   Command
 * @Desc:   Data structure to model a command.
 */
data Command (loc src = |unknown:///|) 
	= message(str string)       // Message command
	| sound(str event)          // Sound command
	| cancel()                  // Cancel command
	| checkpoint()              // Checkpoint command
	| restart()                 // Restart command
	| win()                     // Win command
	| again()                   // Again command
	;

/*
 * @Name:   Rule
 * @Desc:   Data structure to model a rule. Not to be confused with RuleData,
 *          which models a Rule AST node
 */
alias Rule = tuple[
	bool late,                                                          // Boolean indicating if its a late rule
	set[Command] commands,                                              // Set of commands it includes
    str direction,                                                      // Direction to be applied: LEFT, RIGHT, UP, DOWN
	set[str] directions,                                                // Set of possible directions to be applied (???)
	list[RulePart] left,                                                // LHS of the rule
	list[RulePart] right,                                               // RHS of the rule
	int used,                                                           // Amount of times it has been used (???)
    map[str, tuple[str, int, str, str, int, int]] movingReplacement,    // Don't think we need this (DEL)
    map[str, tuple[str, int, str]] aggregateDirReplacement,             // Don't think we need this (DEL)
    map[str, tuple[str, int]] propertyReplacement,                      // Don't think we need this (DEL)
	RuleData original                                                   // Original AST node
];

/*
 * @Name:   Engine
 * @Desc:   Data structure modelling the engine for PuzzleScript games
 */
alias Engine = tuple[
    list[LevelData] levels,                             // Original level AST nodes
	list[Level] converted_levels,                       // Converted levels
    int all_objects,                                    // Number of total objects
    Level begin_level,                                  // First level
	Level current_level,                                // Current level
	list[Condition] conditions,                         // Win conditions   
	list[list[Rule]] rules,                             // Converted rules 
    list[list[Rule]] late_rules,                        // Converted late rules
    map[                                                // Map to keep the order of converted rules:
        RuleData,                                       //      Original rule AST node
        tuple[int, str]                                 //      Tuple: no. rule in code, rule string 
        ] indexed_rules,                                
	int index,                                          // Current step of the game
	map[str, ObjectData] objects,                       // Object Name: Original object AST node
    map[str, list[str]] properties,                     // Object Name: Properties of the object (resolved and unresolved references) (???)
    map[str, list[str]] references,                     // Object Name: References of the object (direct unresolved references) (???)
    map[LevelData, LevelChecker] level_data,            // How many moveable objects are in the game, how many rules will you be able to apply (???)
    map[LevelData, AppliedData] applied_data,           // What is used in the BFS (???)
    bool analyzed,                                      // Boolean indicating if analyzed
	PSGame game                                         // Original game AST node
];

/*
 * @Name:   LevelChecker
 * @Desc:   Data structure that models a level checker
 */
alias LevelChecker = tuple[
    list[Object] starting_objects,              // Starting objects
    list[list[str]] starting_objects_names,     // Starting objects names
    list[str] moveable_objects,                 // Moveable objects
    int moveable_amount_level,                  // Amount of moveable objects
    tuple[int width, int height] size,          // Level size: width x height
    list[LevelData] messages,                   // Messages (errors and warnings)
    list[list[Rule]] applied_rules,             // Applied rules
    list[list[Rule]] applied_late_rules,        // Applied late rules
    Level original                              // Original level object
];

/*
 * @Name:   AppliedData
 * @Desc:   Data structure to model the applied data during the analysis
 *          of a level
 */
alias AppliedData = tuple[
    list[Coords] travelled_coords,      // Travelled coordinates
    map[                                // Applied rules (without movement rules):
        int,                            //      No. rule (???)
        list[RuleData]                  //      rule AST nodes
        ] actual_applied_rules,             
    map[                                // Applied movement rules
        int,                            //      No. rule (???)
        list[str]                       //      Direction (???)
        ] applied_moves,
    list[list[str]] dead_ends,          // Dead ends: loosing playtraces using verbs
    list[str] shortest_path,            // Shortest path using verbs (???)
    Level original                      // Original level AST node
];

/*****************************************************************************/
// --- Public Constructor functions -------------------------------------------

/*
 * @Name:   new_rule
 * @Desc:   Constructor for a new rule
 * @Param:  
 *      r   Original rule AST node
 * @Rule:   Rule object
 */
Rule new_rule(RuleData r)
	= <
		false,  // Late boolean
		{},     // Commands set
        "",     // Direction to be applied to
		{},     // Directions it can be applied to (???)
		[],     // LHS
		[],     // RHS
		0,      // No. times applied
        (),     // movingReplacement
        (),     // aggregateDirReplacement
        (),     // propertyReplacement
		r       // Original AST node
	>;

/*
 * @Name:   new_rule
 * @Desc:   Constructor for a new rule
 * @Param:  
 *      r           Original rule AST node
 *      direction   Direction to be next applied to (???)
 *      left        LHS of the rule
 *      right       RHS of the rule
 * @Rule:   Rule object
 */
Rule new_rule(RuleData r, str direction, list[RulePart] left, list[RulePart] right)
	= <
		false,      // Late boolean
		{},         // Commands set
        direction,  // Direction to be applied to
		{},         // Directions it can be applied to (???)
		left,       // LHS
		right,      // RHS
		0,          // No. times applied
        (),         // movingReplacement
        (),         // aggregateDirReplacement
        (),         // propertyReplacement
		r           // Original AST node
	>;

/*
 * @Name:   new_engine
 * @Desc:   Constructor for a new game engine
 * @Param:
 *      game    Game AST node
 * @Ret:    Engine object
 */
Engine new_engine(PSGame game)		
	= < 
		[],                             // Original level AST nodes
        [],                             // Converted levels
        0,                              // Number of total objects
		message("", level_data([])),    // First level
        message("", level_data([])),    // Current level
        [],                             // Win conditions   
		[],                             // Converted rules 
		[],                             // Converted late rules
        (),                             // Map to keep the order of converted rules
		0,                              // Current step of the game
		(),                             // Object Name: Original object AST node
		(),                             // Object Name: Properties of the object (resolved and unresolved references) (???)
        (),                             // Object Name: References of the object (direct unresolved references) (???)
        (),                             // How many moveable objects are in the game, how many rules will you be able to apply (???)
        (),                             // What is used in the BFS (???)
        false,                          // Boolean indicating if analyzed
		game                            // Original game AST node
	>;

/*
 * @Name:   new_level_checker
 * @Desc:   Constructor for a level checker
 * @Param:  
 *      level   Level object to get a new checker
 * @Ret:    LevelChecker object
 */
LevelChecker new_level_checker(Level level) 
    = <
        [],         // Starting objects
        [],         // Starting objects names
        [],         // Moveable objects
        0,          // Amount of moveable objects
        <0,0>,      // Level size: width x height
        [],         // Messages (errors and warnings)
        [],         // Applied rules
        [],         // Applied late rules
        level       // Original level object
    >;

/*
 * @Name:   new_applied_data
 * @Desc:   Constructor function for applied data
 * @Param:
 *      level   Original level AST node
 * @Red:    AppliedData object
 */
AppliedData new_applied_data(Level level)
    = <
        [],     // Travelled coordinates
        (),     // Applied rules (without movement rules)
        (),     // Applied movement rules
        [],     // Dead end playtraces using verbs
        [],     // Shortest path using verbs
        level   // Original level AST node
    >;

/*****************************************************************************/
// --- Public Getter functions -------------------------------------------

/*
 * @Name:
 *
 */
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

alias RulePartContents = list[RuleContent];

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

// Go over each character in the level and convert the character to all possible references
Level convert_level(LevelData level, Checker c) {
    map[Coords, list[Object]] objects = ();
    tuple[Coords, str] player = <<0,0>, "">;
    map[str, str] player_name = resolve_player_name(c);
    int id = 0;

    str background_char = "";
    for (str bg_char <- c.references<0>){
        if ("background" in c.references[bg_char]) {
            background_char = bg_char;
        }
    }
    list[str] background_references = get_all_references(background_char, c.references);
    LayerData background_ld = get_layer(background_references, c.game);
    str background_name = c.references[background_char][0];

    for (int i <- [0..size(level.level)]) {
 		list[str] char_list = split("", level.level[i]);

        for (int j <- [0..size(char_list)]) {

            str char = toLowerCase(char_list[j]);

            if (char in player_name<0>) player = <<i,j>, player_name[char]>;

            if (char in c.references<0>) {
                list[str] all_references = get_all_references(char, c.references);
                LayerData ld = get_layer(all_references, c.game);
                str name = c.references[char][0];

                
                list[Object] background = [game_object(background_char, background_name, background_references,<i,j>, "", background_ld, id)];
                id += 1;

                list[Object] new_object = [];
                if (char != background_char) {
                    new_object = [game_object(char, name, all_references, <i,j>, "", ld, id)];
                    id += 1;
                }

                list[Object] object = background + new_object;
                if (<i,j> in objects) objects[<i,j>] += object;
                else objects[<i,j>] = object;

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

    println("Concretizing rules...");

    // Step 1
    new_rule_directions += extend_directions(new_rd, direction);
    for (Rule rule <- new_rule_directions) {
        Rule absolute_rule = convertRelativeDirsToAbsolute(rule);
        Rule atomized_rule = atomizeAggregates(checker, absolute_rule);
        new_rules += [atomized_rule];
    }

    // Step 2
    for (Rule rule <- new_rules) {
        println("Concretizing moving rule...");
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

    if (direction in directionaggregates && directionalRule(left, right)) {
        list[str] directions = directionaggregates[toLowerCase(direction)];

        for (str direction <- directions) {
            cloned_rule = new_rule(rd, direction, left, right);
            new_rule_directions += cloned_rule;
        }
    }

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

                            println("Rule movingReplacement:");
                            ipritnln(rule.movingReplacement);
                            println("Rule aggregateDirReplacement");
                            iprintln(rule.aggregateDirReplacement);

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
            if (obj.current_name in lc.moveable_objects) {
                amount_in_level += 1;
            }
            else if (any(str name <- obj.possible_names, name in lc.moveable_objects)) {
                amount_in_level += 1;
            }
        }
    }

    lc.moveable_amount_level = amount_in_level;
    return lc;
}

LevelChecker applied_rules(Engine engine, LevelChecker lc) {

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

map[LevelData, LevelChecker] check_size_per_level(Engine engine, Checker c, bool debug=false) {

    map[LevelData, LevelChecker] allLevelData = ();
    PSGame g = engine.game;

    for (Level level <- engine.converted_levels) {

        LevelChecker lc = new_level_checker(level);

        lc.size = <size(level.original.level[0]), size(level.original.level)>;
        allLevelData += (level.original: lc);
    }
    return allLevelData;

}

Engine check_game_per_level(Engine engine, Checker c, bool debug=false) {

    for (LevelData ld <- engine.level_data<0>) {

        LevelChecker lc = engine.level_data[ld];

        lc = starting_objects(lc.original, lc);
        lc = applied_rules(engine, lc);
        lc = moveable_objects_in_level(engine, lc, c, lc.original);
        engine.level_data[ld] = lc;
        
    }
    return engine;

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
	engine.conditions = c.conditions;
    engine.levels = c.game.levels;  
    engine.properties = c.all_properties;
    engine.references = c.references;

    for (LevelData ld <- engine.levels) {
        if (ld is level_data) engine.converted_levels += [convert_level(ld, c)];
    }

    engine.current_level = engine.converted_levels[0];
    Level begin_level = engine.current_level;
    engine.begin_level = begin_level;

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

    engine.level_data = check_size_per_level(engine, c);
    engine = check_game_per_level(engine, c);
    for (Level level <- engine.converted_levels) {
        engine.applied_data[level.original] = new_applied_data(level);
    }
    engine.analyzed = true;
    engine.indexed_rules = index_rules(engine.game.rules);
	engine.objects = (toLowerCase(x.name) : x | x <- c.game.objects);
	
	return engine;
}