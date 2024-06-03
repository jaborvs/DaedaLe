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
 * @Name:   Engine
 * @Desc:   Data structure modelling the engine for PuzzleScript games
 */
data Engine 
    = game_engine(
        list[Level] levels,                                 // Converted levels
        Level first_level,                                  // First level
        Level current_level,                                // Current level 
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
        map[LevelData, LevelChecker] level_checkers,            // How many moveable objects are in the game, how many rules will you be able to apply (???)
        map[LevelData, LevelAppliedData] level_applied_data,           // What is used in the BFS (???)
        PSGame game                                         // Original game AST node
        )
    | game_engine_empty()
    ;

/*
 * @Name:   Object
 * @Desc:   Data structure to model a game object. Not to be mistaken by DataObject
 *          which models an AST node for an object
 */
data Object 
    = game_object (
            str char,                   // Legend representation char
            str current_name,           // Current name of the object (for references objects)
            list[str] possible_names,   // All objects names (for references objects)
            Coords coords,              // Current position of the object
            str direction,              // Direction to be moved towards
            LayerData layer,            // Layer where it exists
            int id                      // Identifier
        )
    | game_object_empty()
    ;

/*
 * @Name:   Rule
 * @Desc:   Data structure to model a rule. Not to be confused with RuleData,
 *          which models a Rule AST node
 */
data Rule 
    = game_rule(
        bool late,              // Boolean indicating if its a late rule
        str direction,          // Direction to be applied: LEFT, RIGHT, UP, DOWN
        list[RulePart] left,    // LHS of the rule
        list[RulePart] right,   // RHS of the rule
        RuleData original       // Original AST node
        )
    | game_rule_empty()              // Empty rule
    ;

/*
 * @Name:   Level
 * @Desc:   Data structure to model a level. Not to be mistaken by LevelData, 
 *          which represents an AST node of a level
 */
data Level 
    = game_level(
            map[Coords coords, list[Object] objects] objects, // Coordinate and the list of objects (for different layers)
            tuple[Coords coords, str current_name] player,  // Tuple: Coordinate of the player and the state (???)
            LevelData original                              // Original AST node
        )
	| game_level_message(str msg, LevelData original)       // In between level messages are considered levels
    | game_level_empty()                                    // Empty game level
	;

/*
 * @Name:   LevelChecker
 * @Desc:   Data structure that models a level checker
 */
data LevelChecker 
    = game_level_checker(
        tuple[int width, int height] size,          // Level size: width x height
        list[Object] starting_objects,              // Starting objects
        list[list[str]] starting_objects_names,     // Starting objects names
        list[str] moveable_objects,                 // Moveable objects
        list[list[Rule]] can_be_applied_rules,      // Rules that can be applied in the level
        list[list[Rule]] can_be_applied_late_rules, // Late rules that can be applied in the level
        Level original                              // Original level object
        )
    | game_level_checker_empty()
    ;

/*
 * @Name:   LevelAppliedData
 * @Desc:   Data structure to model the applied data during the analysis
 *          of a level
 */
data LevelAppliedData 
    = game_applied_data(
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
        )
    | game_applied_data_empty()
    ;


/*
 * @Name:   Coords
 * @Desc:   Data structure to model coordinates
 */
alias Coords = tuple[
    int x,  // x-coordinate
    int y   // y-coordinate
];

/*****************************************************************************/
// --- Directions structures defines ------------------------------------------
// (Note: this was reproduced from PuzzleScript github)

/* 
 * @Name:   absoluteDirections
 * @Desc:   Absolute directions
 */
list[str] absoluteDirections = ["up", "down", "left", "right"];

/* 
 * @Name:   relativeDirections
 * @Desc:   Relative direction modifiers
 */
list[str] relativeDirections = ["^", "v", "\<", "\>", "parallel", "perpendicular"];

/* 
 * @Name:   relativeDict
 * @Desc:   Dictionary for relative rules
 */
map[str, list[str]] relativeDict = (
    "right": ["up", "down", "left", "right", "horizontal_par", "vertical_perp"],
    "up": ["left", "right", "down", "up", "vertical_par", "horizontal_perp"],
    "down": ["right", "left", "up", "down", "vertical_par", "horizontal_perp"],
    "left": ["down", "up", "right", "left", "horizontal_par", "vertical_perp"]
);

/*
 * @Name:   directionAggregates
 * @Desc:   Map to translate relative direction modifiers to specif ones
 */
map[str, list[str]] directionAggregates = (
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

/******************************************************************************/
// --- Compilation functions ---------------------------------------------------

/*
 * @Name:   compile
 * @Desc:   Function that compiles a whole game
 * @Param:  c -> Checker
 * @Ret:    Engine object
 */
Engine compile(Checker c) {
	Engine engine = game_engine(
        [],                             // Converted levels
		game_level_empty(),             // First level
        game_level_empty(),             // Current level  
		[],                             // Converted rules 
		[],                             // Converted late rules
        (),                             // Map to keep the order of converted rules
		0,                              // Current step of the game
		(),                             // Object Name: Original object AST node
		(),                             // Object Name: Properties of the object (resolved and unresolved references) (???)
        (),                             // Object Name: References of the object (direct unresolved references) (???)
        (),                             // How many moveable objects are in the game, how many rules will you be able to apply (???)
        (),                             // What is used in the BFS (???)
		c.game                            // Original game AST node
    ); 

    engine = compile_properties(engine, c);
    engine = compile_references(engine, c);
    engine = compile_levels(engine, c);
    engine = compile_rules(engine, c);
    engine = compile_level_checkers(engine, c);
    engine = compile_applied_data(engine, c);
    engine = compile_indexed_rules(engine, c);
    engine = compile_objects(engine, c);	
	
	return engine;
}

/******************************************************************************/
// --- Public compile object functions -----------------------------------------

/*
 * @Name:   compile_objects
 * @Desc:   Function to compile the objects
 * @Param:  engine -> Engine
 * @Ret:    Updated engine with the compiled objects
 */
Engine compile_objects(Engine engine, Checker c) {
    engine.objects = (toLowerCase(x.name) : x | x <- c.game.objects);
    return engine;
}

/******************************************************************************/
// --- Public compile indexed rules functions ----------------------------------

/*
 * @Name:   compile_indexed_rules
 * @Desc:   Function to index the rules
 * @Param:  engine -> Engine
 * @Ret:    Updated engine with the indexed rules
 */
Engine compile_indexed_rules(Engine engine, Checker c) {
    int index = 0;

    for (RuleData rd <- engine.game.rules) {
        str rule_string = stringify_rule(rd.left, rd.right);
        engine.indexed_rules += (rd: <index, rule_string>);
        index += 1;
    }

    return engine;
}

/******************************************************************************/
// --- Public compile applied data functions -----------------------------------

/*
 * @Name:   compile_applied_data
 * @Desc:   Function to add the applied data 
 * @Param:  engine -> engine
 * @Ret:    Updated engine with the applied data 
 */
Engine compile_applied_data(Engine engine, Checker c) {
    for (Level level <- engine.levels) {
        engine.level_applied_data[level.original] = game_applied_data(
            [],     // Travelled coordinates
            (),     // Applied rules (without movement rules)
            (),     // Applied movement rules
            [],     // Dead end playtraces using verbs
            [],     // Shortest path using verbs
            level   // Original level AST node
        );
    }

    return engine;
}

/******************************************************************************/
// --- Public compile properties functions -------------------------------------

/*
 * @Name:   compile_properties
 * @Desc:   Function to compile all the properties from the legend of a game
 * @Param:  engine -> Engine
 * @Ret:    Updated engine witht the properties
 */
Engine compile_properties(Engine engine, Checker c) {
    engine.properties = c.resolved_references;
    return engine;
}

/******************************************************************************/
// --- Public compile references functions -------------------------------------

/*
 * @Name:   compile_references
 * @Desc:   Function to compile all the references from the legend of a game
 * @Param:  engine -> Engine
 * @Ret:    Updated engine witht the references
 */
Engine compile_references(Engine engine, Checker c) {
    engine.references = c.references;
    return engine;
}

/******************************************************************************/
// --- Public convert levels functions -----------------------------------------

/*
 * @Name:   compile_levels
 * @Desc:   Function to convert all the levels into a new level structure with 
 *          more information
 * @Param:  engine -> Engine
 *          c      -> Checker
 * @Ret:    Updated engine with the new converted levels
 */
Engine compile_levels(Engine engine, Checker c) {
    for (LevelData lvl <- c.game.levels) {
        if (lvl is level_data) engine.levels += [compile_level(lvl, c)];
    }
    engine.current_level = engine.levels[0];
    engine.first_level = engine.current_level;

    return engine;
}

/******************************************************************************/
// --- Public convert rules functions ------------------------------------------

/*
 * @Name:   compile_rules
 * @Desc:   Function to convert all the rules into a new rule structure with 
 *          more information
 * @Param:  engine -> Engine
 *          c      -> Checker
 * @Ret:    Updated engine with the new converted rules
 */
Engine compile_rules(Engine engine, Checker c) {
    for (RuleData rule <- c.game.rules) {
        if ("late" in [toLowerCase(lhs.prefix) | lhs <- rule.left, lhs is rule_prefix]) {
            list[Rule] rule_group = compile_rule(rule, true, c);
            if (size(rule_group) != 0) engine.late_rules += [rule_group];
        }
        else {
            list[Rule] rule_group = compile_rule(rule, false, c);
            if (size(rule_group) != 0) engine.rules += [rule_group];
        }
    }
    return engine;
}

/******************************************************************************/
// --- Public convert level checker functions ----------------------------------

/*
 * @Name:   compile_level_checkers
 * @Desc:   Function to init and complete all the information inside the level 
 *          checkers
 * @Param:  engine -> Engine
 *          c      -> Checker
 * @Ret:    Updated engine with the level checkers
 */
 Engine compile_level_checkers(Engine engine, Checker c) {
    engine.level_checkers = ();
    for(Level level <- engine.levels) {
        LevelChecker lc = game_level_checker(
            <0,0>,      // Level size: width x height
            [],         // Starting objects
            [],         // Starting objects names
            [],         // Moveable objects
            [],         // Applied rules
            [],         // Applied late rules
            level       // Original level object
        );

        lc = _compile_level_checker_size(lc, level);
        lc = _compile_level_checker_starting_objects(lc, level);
        lc = _compile_level_checker_to_be_applied_rules(lc, engine.rules, engine.late_rules);
        lc = _compile_level_checker_moveable_objects(lc, c, level);
        
        engine.level_checkers[level.original] = lc;
    }

    return engine;
}

/******************************************************************************/
// --- Private convert level checker functions ---------------------------------

/*
 * @Name:   _compile_level_checker_size
 * @Desc:   Function that completes the size of a level chekcer
 * @Param:  engine -> Engine
 *          level  -> Level to get the size from
 * @Ret:    Updated map of level data and level checker
 */
LevelChecker _compile_level_checker_size(LevelChecker lc, Level level) {
    lc.size = <size(level.original.level[0]), size(level.original.level)>;
    return lc;
}

/*
 * @Name:   _compile_level_checker_starting_objects
 * @Desc:   Function to store the starting objects of a level on its level 
 *          checker
 * @Param:  lc    -> Level checker
 *          level -> Level
 * @Ret:    Updated level checker
 */
LevelChecker _compile_level_checker_starting_objects(LevelChecker lc, Level level){
    list[Object] all_objects = [];
    list[list[str]] object_names = [];

    for (Coords coords <- level.objects.coords) {
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

/*
 * @Name:   _compile_level_checker_to_be_applied_rules
 * @Desc:   Function to find those rules that can be applied per level
 * @Param:  lc         -> Level checker
 *          rules      -> Engine rules
 *          late_rules -> Engie late rules
 * @Ret:    Updated level checker
 */
LevelChecker _compile_level_checker_to_be_applied_rules(LevelChecker lc, list[list[Rule]] rules, list[list[Rule]] late_rules) {
    bool new_objects = true;
    list[list[Rule]] applied_rules = [];
    list[list[Rule]] applied_late_rules = [];

    map[int, list[Rule]] indexed = ();
    map[int, list[Rule]] indexed_late = ();

    for (int i <- [0..size(rules)]) {
        list[Rule] rule_group = rules[i];
        indexed += (i: rule_group);
    }
    for (int i <- [0..size(late_rules)]) {
        list[Rule] rule_group = late_rules[i];
        indexed_late += (i: rule_group);
    }

    list[list[Rule]] current = rules + late_rules;

    list[list[str]] previous_objs = [];

    while(previous_objs != lc.starting_objects_names) {
        previous_objs = lc.starting_objects_names;

        for (list[Rule] lrule <- current) {
            // Each rewritten rule in rule_group contains same objects so take one
            Rule rule = lrule[0];
            list[str] required = [];

            for (RulePart rp <- rule.left) {
                if (!(rp is rule_part)) continue;

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
                } 
                else break;
            }

            if (applied == size(required)) {
                list[list[RuleContent]] list_rc = [rulepart.contents | rulepart <- rule.right, rulepart is rule_part];
                list[list[str]] new_objects_list = [];

                for (list[RuleContent] lrc <- list_rc) {
                    list[str] new_objects = [name | rc <- lrc, name <- rc.content, !(name == "no"), 
                        !(isDirection(name)), !(name == ""), !(name == "..."), 
                        !(any(list[str] objects <- lc.starting_objects_names, name in objects))];

                    if (size(new_objects) > 0) new_objects_list += [new_objects];

                }
                
                lc.starting_objects_names += new_objects_list;

                if (rule.late && !(lrule in applied_late_rules)) applied_late_rules += [lrule];
                if (!(rule.late) && !(lrule in applied_rules)) applied_rules += [lrule];
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

    lc.can_be_applied_late_rules = applied_late_rules_in_order;
    lc.can_be_applied_rules = applied_rules_in_order;

    return lc;
}

/*
 * @Name:   _compile_level_checker_moveable_objects
 * @Desc:   Function to set all the moveable objects in a level checker
 * @Param:  lc    -> Level checker
 *          level -> Level
 * @Ret:    Updated level checker
 */
LevelChecker _compile_level_checker_moveable_objects(LevelChecker lc, Checker c, Level level) {
    for (list[Rule] lrule <- lc.can_be_applied_rules) {
        for (RulePart rp <- lrule[0].left) {
            if (rp is rule_part) lc = _compile_level_checker_get_moveable_objects(lc, c, rp.contents);
        }
        for (RulePart rp <- lrule[0].right) {
            if (rp is rule_part) lc = _compile_level_checker_get_moveable_objects(lc, c, rp.contents);
        }
    }

    lc.moveable_objects = dup(lc.moveable_objects);
    return lc;
}

LevelChecker _compile_level_checker_get_moveable_objects(LevelChecker lc, Checker c, list[RuleContent] rule_side) {
    list[str] found_objects = ["player"];

    for (RuleContent rc <- rule_side) {
        for (int i <- [0..(size(rc.content))]) {
            if (i mod 2 == 1) continue;
            
            str dir = rc.content[i];
            str name = rc.content[i + 1];
            
            if (isDirection(dir)) {
                if (!(name in found_objects)) found_objects += [name];
                list[str] all_references = get_resolved_references(name, c.references);
                found_objects += [name | str name <- get_resolved_references(name, c.references), 
                    any(list[str] l_name <- lc.starting_objects_names, name in l_name)];
                found_objects += [name | str name <- get_resolved_references(name, c.combinations), 
                    any(list[str] l_name <- lc.starting_objects_names, name in l_name)];
            }
        }
    } 
    lc.moveable_objects += dup(found_objects);
    return lc;
}

/*****************************************************************************/
// --- Public Getter functions ------------------------------------------------

/*
 * @Name:   get_object
 * @Desc:   Getter function of object by id
 * @Param:
 *      id      Object id
 *      engine  Engine
 * @Ret:    Original object AST node
 */
ObjectData get_object(int id, Engine engine) 
	= [x | x <- engine.game.objects, x.id == id][0];

/*
 * @Name:   get_object
 * @Desc:   Getter function of object by name
 * @Param:
 *      name    Object name
 *      engine  Engine
 * @Ret:    Original object AST node
 */
ObjectData get_object(str name, Engine engine) 
	= [x | x <- engine.game.objects, toLowerCase(x.name) == name][0];

/*
 * @Name:   get_layer
 * @Desc:   Function to get the layer of a list of objects
 * @Param:  
 *      object  List of object names
 *      game    Original game AST node 
 * @Ret:    Layer object (empty if not found)
 */
LayerData get_layer(list[str] object, PSGame game) {
    for (LayerData layer <- game.layers) {
        if (layer is layer_data) {
            for (str layer_item <- layer.items) {
                if (toLowerCase(layer_item) in object) {
                    return layer;
                }
            }
        }
    }
    return layer_empty("");
}

/*****************************************************************************/
// --- Public Translating functions -------------------------------------------

/*
 * @Name:   generate_directions
 * @Desc:   Function to translate directional modifiers to actual directions 
 *          (UP, DOWN, LEFT, RIGHT)
 * @Param:  
 *      modifiers   List of modifiers to be translated
 * @Ret:    Set of directions (all if empty directions)
 */
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

/******************************************************************************/
// --- Convert level functions -------------------------------------------------

/*
 * @Name:   compile_level
 * @Desc:   Function to convert an level AST node to an level object. We go over
 *          each character in the level and convert the character to all 
 *          possible references
 * @Param:  level -> Original level AST node
 *          c     -> Checker
 * @Ret:    Level object
 */
Level compile_level(LevelData lvl, Checker c) {
    map[Coords, list[Object]] objects = ();
    tuple[Coords, str] player = <<0,0>, "">;
    int id = 0;

    // We resolve all the needed player object information
    tuple[str rep_char, str name] player_resolved = _compile_level_resolve_player(c);

    // We resolve all the needed background object information
    tuple[str rep_char, str name] background_resolved = _compile_level_resolve_background(c);
    list[str] background_properties = get_properties_rep_char(background_resolved.rep_char, c.references);
    LayerData background_layer = get_layer(background_properties, c.game);

    for (int i <- [0..size(lvl.level)]) {
        for (int j <- [0..size(lvl.level[i])]) {
            // We create a background object and add it
            Object new_background_object = game_object(background_resolved.rep_char, background_resolved.name, background_properties, <i,j>, "", background_layer, id);
            objects = _compile_level_add_object(objects, <i,j>, new_background_object);
            id += 1;

            // Now we add our new object. We have different steps:
            str rep_char = toLowerCase(lvl.level[i][j]);

            // Step 1: if it is a background object, we skip it since we have
            //         already added one
            if(rep_char == background_resolved.rep_char) continue;

            // Step 2: if its a player object we store 
            if (rep_char == player_resolved.rep_char) {
                player = <<i,j>, player_resolved.name>;
            }

            // Step 3.1: the object to represent is a key in the references, that
            //           is, it representes several objects (or several states of
            //           the same object). We get the properties of the char
            if (rep_char in c.references.key) {
                list[str] all_properties = get_properties_rep_char(rep_char, c.references);
                LayerData layer = get_layer(all_properties, c.game);
                str name = c.references[rep_char][0];

                Object new_object = game_object(rep_char, name, all_properties, <i,j>, "", layer, id);
                objects = _compile_level_add_object(objects, <i,j>, new_object);
                id += 1;
            } 
            // Step 3.2: the rep_char is represents a combination of objects.
            else if (rep_char in c.combinations.key) {
                for (str name <- c.combinations[rep_char]) {
                    list[str] all_properties = get_properties_name(name, c.references);  
                    LayerData ld = get_layer(all_properties, c.game);

                    Object new_object = game_object(rep_char, name, all_properties, <i,j>, "", ld, id);
                    objects = _compile_level_add_object(objects, <i,j>, new_object);
                    id += 1;
                }
            }
            // Step 3.3: Representation char included in the object definition 
            //           (FIX: need to loop over the objects to find it)
        }
    }

    new_level = game_level(
        objects,
		player,
		lvl        
    );

    return new_level;
}

/*
 * @Name:   _compile_level_resolve_player
 * @Desc:   Function that resolves the name and representation character of the 
 *          given object 
 * @Param:  c           -> Checker
 *          object_name -> Name of the object to resolve
 * @Ret:    Map with representation char as key and name as value
 */
tuple[str, str] _compile_level_resolve_object(Checker c, str object_name) {
    list[str] possible_names = [object_name];

    // Add the direct references of the "object_name" key 
    if (object_name in c.references.key) possible_names += c.references[object_name];

    // Search for a character that represents any of the possible player names in the references
    for (str key <- c.references.key) {
        if(size(key) == 1, any(str name <- possible_names, name in c.references[key])) return <key, name>;
    }

    // Search for a character that represents any of the possible player names in the references
    for (str key <- c.combinations.key) {
        if (size(key) == 1, any(str name <- possible_names, name in c.combinations[key])) return <key, name>;
    }

    return <"","">;
}

/*
 * @Name:   _compile_level_resolve_player
 * @Desc:   Function that resolves the name and representation character of the 
 *          player
 * @Param:  c -> Checker
 * @Ret:    Map with representation char as key and name as value
 */
tuple[str, str] _compile_level_resolve_player(Checker c) {
    return _compile_level_resolve_object(c, "player");
}

/*
 * @Name:   _compile_level_resolve_background
 * @Desc:   Function that resolves the representation char and name of the
 *          background
 * @Param:  c -> Checker
 * @Ret:    Map with representation char as key and name as value
 */
tuple[str,str] _compile_level_resolve_background (Checker c) {
    return _compile_level_resolve_object(c, "background");
}

/*
 * @Name:   _compile_level_add_object
 * @Desc:   Function that adds an object to the given object coord map
 * @Param:  objects    -> Current map of coordinates and objects
 *          coords     -> Coordinates of the new object
 *          new_object -> New object to add
 * @Ret:    Updated map with the new object
 */
map[Coords, list[Object]] _compile_level_add_object(map[Coords, list[Object]] objects, tuple[int x, int y] coords, Object new_object) {
    if (coords in objects) objects[coords] += [new_object];
    else objects[coords] = [new_object];
    return objects;
}







/*
 * @Name:   isDirection
 * @Desc:   Function to check if a string is a valid direction
 * @Param:  
 *      dir     string to be checked
 * @Ret:    Boolean indicating if valid
 */
bool isDirection (str dir) {
    return (dir in relativeDict["right"] || dir in relativeDirections);
}

/******************************************************************************/
// --- Public convert rule functions -------------------------------------------

list[Rule] compile_rule(RuleData rd: rule_data(left, right, message, separator), bool late, Checker checker) {
    list[Rule] new_rule_directions = [];
    list[Rule] new_rules = [];
    list[Rule] new_rules2 = [];

    list[RulePart] new_left = [rp | RulePart rp <- left, rp is rule_part];
    list[RulePart] save_left = [rp | RulePart rp <- left, !(rp is rule_part)];
    list[str] directions = [toLowerCase(rp.prefix) | rp <- save_left, rp is rule_prefix && replaceAll(toLowerCase(rp.prefix), " ", "") != "late"];

    list[RulePart] new_right = [rp | RulePart rp <- right, rp is rule_part];
    list[RulePart] save_right = [rp | RulePart rp <- right, !(rp is rule_part)];

    RuleData new_rd = rule_data(new_left, new_right, message, separator);

    new_rule_directions = _compile_rule_extend_directions(new_rd, directions);

    for (Rule rule <- new_rule_directions) {
        Rule absolute_rule = _compile_rule_relative_directions_to_absolute(rule);
        Rule atomized_rule = _compile_rule_atomize_aggregates(checker, absolute_rule);
        new_rules += [atomized_rule];
    }

    for (Rule rule <- new_rules) {
        rule.left += save_left;
        rule.right += save_right;
        new_rules2 += rule.late = late;
    }

    return new_rules2;
}

/******************************************************************************/
// --- Prive convert rule extend direction functions ---------------------------

/*
 * @Name:   _compile_rule_extend_directions
 * @Desc:   Function to extend the directions of a rule. It calls extend_direction
 *          which contains the exact extension functionality
 * @Param:  rd         -> Rule AST node to be extended
 *          directions -> Directions to be extended
 * @Ret:    Extended list of rules
 */
list[Rule] _compile_rule_extend_directions(RuleData rd: rule_data(left, right, message, _), list[str] directions) {
    list[Rule] new_rule_directions = [];

    if(directions == []) directions = [""];

    for (direction <- directions) {
        new_rule_directions += _compile_rule_extend_direction(rd, direction);
    }
    return new_rule_directions;
}

/*
 * @Name:   _compile_rule_extend_direction
 * @Desc:   Function to extend the directions of a rule. This means we extend the
 *          directional prefixes of a rule. There are different cases:
 *          1. If a rule has a relative direction (e.g., horizontal), we need to
 *          extend it to right and left.
 *          2. If a rule has an absolute direction, then we just need to stick to
 *          that direction.
 *          3. If a rule has no direction specified, all directions apply (i.e.,
 *          implicit orthogonal prefix).
 * @Param:  rd -> Rule AST node to be extended
 *          direction -> Direction to be extended
 * @Ret:    Extended list of rules
 */
list[Rule] _compile_rule_extend_direction (RuleData rd: rule_data(left, right, message, _), str direction) {
    list[Rule] new_rule_directions = [];
    Rule cloned_rule = game_rule_empty();

    if (direction in directionAggregates) {
        list[str] directions = directionAggregates[toLowerCase(direction)];

        for (str direction <- directions) {
            cloned_rule = game_rule(
                false,      // Late boolean
                direction,  // Direction to be applied to
                left,       // LHS
                right,      // RHS
                rd          // Original AST node
            );
            new_rule_directions += cloned_rule;
        }
    }
    else if (direction in absoluteDirections) {
        cloned_rule = game_rule(
            false,      // Late boolean
            direction,  // Direction to be applied to
            left,       // LHS
            right,      // RHS
            rd          // Original AST node
        );
        new_rule_directions += cloned_rule;
    }
    else {
        list[str] directions = directionAggregates["orthogonal"];

        for (str direction <- directions) {
            cloned_rule = game_rule(
                false,      // Late boolean
                direction,  // Direction to be applied to
                left,       // LHS
                right,      // RHS
                rd          // Original AST node
            );
            new_rule_directions += cloned_rule;
        }
    }

    return new_rule_directions;
}

/******************************************************************************/
// --- Private convert rule relative dirs to absolute functions ----------------

/*
 * @Name:   _compile_rule_relative_directions_to_absolute
 * @Desc:   Function to convert the relative directios of a rule to absolute. 
 *          This means that if a rule has a direction UP, the relativeDirections
 *          get translated to their according absolute direction. It calls the 
 *          _compile_rule_part_relative_directions_to_absolute function.
 * @Param:  rule -> Rule to have its relative directions converted
 * @Ret:    New rule with converted relative directions
 */
Rule _compile_rule_relative_directions_to_absolute(Rule rule) {
    rule.left = _compile_rule_part_relative_directions_to_absolute(rule.left, rule.direction);
    rule.right = _compile_rule_part_relative_directions_to_absolute(rule.right, rule.direction);

    return rule;
}

/*
 * @Name:   _compile_rule_part_relative_directions_to_absolute
 * @Desc:   Function to convert the relative directions of a rule part to
 *          absolute ones. We now for a fact that the rule contents need to be 
 *          one direction, other keyword modifiers (e.g., no) and then the name
 * @Param:  rule_parts -> rule parts to convert to absoute directions
 *          direction  -> direction of the rule
 * @Ret:    Converted rule parts to absolute directions
 */
list[RulePart] _compile_rule_part_relative_directions_to_absolute(list[RulePart] rule_parts, str direction) {
    list[RulePart] new_rp = [];
    
    for (RulePart rp <- rule_parts) {
        list[RuleContent] new_rc = [];

        if (!(rp is rule_part)) {
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

                int index = indexOf(relativeDirections, rc.content[i]);
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
    
    return new_rp;
}

/******************************************************************************/
// --- Private convert rule atomize aggregates functions -----------------------

/*
 * @Name:   _compile_rule_atomize_aggregates
 * @Desc:   Function to atomize the name aggregates used in a rule. For instance,
 *          this is used to change Obstacle by Wall, PlayerBodyH, PlayerBodyV...
 *          This calls _compile_rule_part_atomize_rule_aggregates.
 * @Param:  c    -> Checker
 *          rule -> Rule to be atomized
 * @Ret:    Atomized rule
 */
Rule _compile_rule_atomize_aggregates(Checker c, Rule rule) {
    list[RuleContent] new_rc = [];
    list[RulePart] new_rp = [];

    rule.left = _compile_rule_part_atomize_aggregates(c, rule.left);
    rule.right = _compile_rule_part_atomize_aggregates(c, rule.right);

    return rule;
}

/*
 * @Name:   _compile_rule_part_atomize_aggregates
 * @Desc:   Function to atomize the name aggregates used in a rule part. We now 
 *          that the rule contents have an even length, since it is always a
 *          direction and a name (object, or another keyword)
 * @Param:  c    -> Checker
 *          rule_parts -> Rule parts to be atomized
 * @Ret:    Atomized rule
 */
list[RulePart] _compile_rule_part_atomize_aggregates(Checker c, list[RulePart] rule_parts) {
    list[RuleContent] new_rc = [];
    list[RulePart] new_rp = [];

    for (RulePart rp <- rule_parts) {
        new_rc = [];

        if (!(rp is rule_part)) {
            new_rp += rp; 
            continue;
        }

        for (RuleContent rc <- rp.contents) {
            list[str] new_content = [];
            for (int i <- [0..size(rc.content)]) {
                if (i mod 2 == 1) continue;

                str direction = rc.content[i];
                str object = toLowerCase(rc.content[i+1]);

                if (object in c.combinations.key) {
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

    return new_rp;
}

/******************************************************************************/

str stringify_rule(list[RulePart] left, list[RulePart] right) {
    str rule = "";
    if (any(RulePart rp <- left, rp is rule_prefix)) rule += rp.prefix;

    for (int i <- [0..size(left)]) {
        RulePart rp = left[i];

        if (!(rp is rule_part)) continue;
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

        if (!(rp is rule_part)) continue;
        rule += " [ ";
        for (RuleContent rc <- rp.contents) {
            for (str content <- rc.content) rule += "<content> ";
            if (i < size(right) - 1) rule += " | ";
        }
        rule += " ] ";
    }
    return rule;
}