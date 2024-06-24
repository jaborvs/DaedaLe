/*
 * @Module: Compiler
 * @Desc:   Module that compiles the AST.
 *          NOTE: This module could potentially be refactored to be shorter and
 *                to use a better notation for data structures.
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

/******************************************************************************/
// --- Own modules imports -----------------------------------------------------
import Utils;
import PuzzleScript::AST;

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
// --- Data structures defines -------------------------------------------------

/*
 * @Name:   Engine
 * @Desc:   Data structure modelling the engine for PuzzleScript games
 */
data Engine 
    = game_engine(
        int index,                                                                                      // Index indicating in which level we are
        map[str name, ObjectData od] objects,                                                           // Map with object name as key and the object AST node as value                                                                                    // Current step of the game
        list[Level] levels,                                                                             // Levels
        Level first_level,                                                                              // First level
        Level current_level,                                                                            // Current level 
        list[list[Rule]] rules,                                                                         // Rules
        list[list[Rule]] late_rules,                                                                    // Late rules
        map[RuleData original_rule, tuple[int index, str stringified_rule] indexed_rule] indexed_rules, // Map to keep rules in order (This was only needed for the verbs and is surely a quickfix) (FIX)
        map[str key, list[str] list_references] references,                                             // References: object name/rep_char -> list of names
        map[str key, list[str] list_combinations] combinations,                                         // Combinations: object name/rep_char -> list of names    
        map[str key, list[str] list_properties] properties,                                             // Properties: object name (only) -> list of names   
        map[LevelData, LevelChecker] level_checkers,                                                    // Level checkers
        map[LevelData, LevelAppliedData] level_applied_data,                                            // What is used in the BFS (???)
        GameData game                                                                                   // Original game AST node
        )
    | game_engine_empty()
    ;

/*
 * @Name:   Object
 * @Desc:   Data structure to model a game object. Not to be mistaken by DataObject
 *          which models an AST node for an object
 */
data Object 
    = game_object(
            int id,                     // Identifier
            str char,                   // Legend representation char
            str current_name,           // Current name of the object (for references objects)
            list[str] possible_names,   // All objects names (for references objects)
            Coords coords,              // Current position of the object
            str direction,              // Direction to be moved towards
            LayerData layer             // Layer where it exists
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
        bool movement,          // Boolean indicating if the rule is a movement rule
        RuleData original       // Original AST node
        )
    | game_rule_empty()         // Empty rule
    ;

/*
 * @Name:   Level
 * @Desc:   Data structure to model a level. Not to be mistaken by LevelData, 
 *          which represents an AST node of a level
 */
data Level 
    = game_level(
            map[Coords coords, list[Object] list_objects] objects,  // Coordinate and the list of objects (for different layers)
            tuple[Coords coords, str current_name] player,          // Tuple: Coordinate of the player and the state (???)
            LevelData original                                      // Original AST node
        )
	| game_level_message(str msg, LevelData original)               // In between level messages are considered levels
    | game_level_empty()                                            // Empty game level
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
        list[Coords] travelled_coords,          // Travelled coordinates
        map[                                    // Applied rules (without movement rules):
            int index,                          //      Index (turn of the game)
            list[RuleData] list_applied_rules   //      Applied rules AST nodes
            ] actual_applied_rules,             
        map[                                    // Applied movement rules
            int index,                          //      Index (turn of the game)
            list[str] list_moves                //      Direction
            ] applied_moves,
        list[list[str]] dead_ends,              // Dead ends: loosing playtraces using verbs
        list[str] shortest_path,                // Shortest path
        Level original                          // Original level object
        )
    | game_applied_data_empty()
    ;

/******************************************************************************/
// --- Compilation functions ---------------------------------------------------

/*
 * @Name:   ps_compile
 * @Desc:   Function that compiles a whole game
 * @Param:  game_data -> Parsed game
 * @Ret:    Engine object
 */
Engine ps_compile(GameData game_data) {
	Engine engine = game_engine(
        0,                  // Current step of the game
        (),                 // Objects
        [],                 // Levels
        game_level_empty(), // First level
        game_level_empty(), // Current level  
        [],                 // Rules 
        [],                 // Late rules
        (),                 // Map to keep the order of converted rules
        (),                 // References
        (),                 // Combinations
        (),                 // Properties
        (),                 // Level checkers
        (),                 // What is used in the BFS (???)
        game_data           // Original game AST node
    ); 

    engine = _ps_compile_objects(engine);	
    engine = _ps_compile_references(engine);
    engine = _ps_compile_combinations(engine);
    engine = _ps_compile_properties(engine);
    engine = _ps_compile_levels(engine);
    engine = _ps_compile_rules(engine);
    engine = _ps_compile_level_checkers(engine);
    engine = _ps_compile_applied_data(engine);
	
	return engine;
}

/******************************************************************************/
// --- Public compile object functions -----------------------------------------

/*
 * @Name:   _ps_compile_objects
 * @Desc:   Function to compile the objects. Note that in this case the objects
 *          are AST nodes, and not the new object data structure
 * @Param:  engine -> Engine
 * @Ret:    Updated engine with the objects AST nodes
 */
Engine _ps_compile_objects(Engine engine) {
    engine.objects = (toLowerCase(x.name) : x | x <- engine.game.objects);
    return engine;
}

/******************************************************************************/
// --- Public compile references functions -------------------------------------

/*
 * @Name:   _ps_compile_references
 * @Desc:   Function to compile all the references from the legend of a game
 * @Param:  engine -> Engine
 * @Ret:    Updated engine witht the references
 */
Engine _ps_compile_references(Engine engine) {
    for (LegendData l <- engine.game.legend) {
        if (l is legend_reference) {
            for (str object <- l.items) {
                if (toLowerCase(l.key) in engine.references) engine.references[toLowerCase(l.key)] += [toLowerCase(object)];
                else engine.references[toLowerCase(l.key)] = [toLowerCase(object)];
            }
        }
    }

    return engine;
}

/******************************************************************************/
// --- Public compile combinations functions -------------------------------------

/*
 * @Name:   _ps_compile_combinations
 * @Desc:   Function to compile all the references from the legend of a game
 * @Param:  engine -> Engine
 * @Ret:    Updated engine witht the references
 */
Engine _ps_compile_combinations(Engine engine) {
    for(LegendData l <- engine.game.legend) {
        if (l is legend_combined) {
            for (str object <- l.items) {
                if (toLowerCase(l.key) in engine.combinations) engine.combinations[toLowerCase(l.key)] += [toLowerCase(object)];
                else engine.combinations[toLowerCase(l.key)] = [toLowerCase(object)];
            }
        }
    }

    return engine;
}

/******************************************************************************/
// --- Public compile properties functions -------------------------------------

/*
 * @Name:   _ps_compile_properties
 * @Desc:   Function to compile all the properties from the legend of a game
 * @Param:  engine -> Engine
 * @Ret:    Updated engine witht the properties
 */
Engine _ps_compile_properties(Engine engine) {
    for(str key <- engine.references.key) {
        if (size(engine.references[key]) == 1) continue;
        engine.properties[key] = get_resolved_references(key, engine.references);
    }

    return engine;
}

/******************************************************************************/
// --- Public compile applied data functions -----------------------------------

/*
 * @Name:   _ps_compile_applied_data
 * @Desc:   Function to add the applied data 
 * @Param:  engine -> engine
 * @Ret:    Updated engine with the applied data 
 */
Engine _ps_compile_applied_data(Engine engine) {
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
// --- Public convert levels functions -----------------------------------------

/*
 * @Name:   _ps_compile_levels
 * @Desc:   Function to convert all the levels into a new level structure with 
 *          more information. It also sets the first level and the current level
 * @Param:  engine -> Engine
 * @Ret:    Updated engine with the new converted levels
 */
Engine _ps_compile_levels(Engine engine) {
    for (LevelData lvld <- engine.game.levels) {
        if (lvld is level_data) engine.levels += [_ps_compile_level(engine, lvld)];
    }
    engine.current_level = engine.levels[0];
    engine.first_level = engine.current_level;

    return engine;
}

/*
 * @Name:   _ps_compile_level
 * @Desc:   Function to convert an level AST node to an level object. We go over
 *          each character in the level and convert the character to all 
 *          possible references
 * @Param:  engine -> Engine
 *          level  -> Original level AST node
 * @Ret:    Level object
 */
Level _ps_compile_level(Engine engine, LevelData lvl) {
    map[Coords, list[Object]] objects = ();
    tuple[Coords, str] player = <<0,0>, "">;
    int id = 0;

    // We resolve all the needed player object information
    tuple[str rep_char, str name] player_resolved = _ps_compile_level_resolve_player(engine);

    // We resolve all the needed background object information
    tuple[str rep_char, str name] background_resolved = _ps_compile_level_resolve_background(engine);
    list[str] background_properties = get_properties_rep_char(background_resolved.rep_char, engine.references);
    LayerData background_layer = get_layer(engine, background_properties);

    for (int i <- [0..size(lvl.level)]) {
        for (int j <- [0..size(lvl.level[i])]) {
            // Every object must have a background, so we create a background 
            // object and add it
            Object new_background_object = game_object(id, background_resolved.rep_char, background_resolved.name, background_properties, <i,j>, "", background_layer);
            objects = _ps_compile_level_add_object(objects, <i,j>, new_background_object);
            id += 1;

            // Now we add our actual new object. We have different steps:
            // Step 1: if it is a background object, we skip it since we have
            //         already added one
            str rep_char = toLowerCase(lvl.level[i][j]);
            if(rep_char == background_resolved.rep_char) continue;

            // Step 2: if its a player object we store its coordinates and name
            if (rep_char == player_resolved.rep_char) {
                player = <<i,j>, player_resolved.name>;
            }

            // Step 3.1: the rep_char is in the references. We add only the first
            //           object of its possible options
            if (rep_char in engine.references.key) {
                list[str] all_properties = get_properties_rep_char(rep_char, engine.references);
                LayerData layer = get_layer(engine, all_properties);
                str name = engine.references[rep_char][0]; // Out of all the possible names we give the first one

                Object new_object = game_object(id, rep_char, name, all_properties, <i,j>, "", layer);
                objects = _ps_compile_level_add_object(objects, <i,j>, new_object);
                id += 1;
            } 
            // Step 3.2: the rep_char is represents a combination of objects. We
            //           add each of the objects it refers to
            else if (rep_char in engine.combinations.key) {
                for (str name <- engine.combinations[rep_char]) {
                    list[str] all_properties = get_properties_name(name, engine.references);  
                    LayerData ld = get_layer(engine, all_properties);

                    Object new_object = game_object(id, rep_char, name, all_properties, <i,j>, "", ld);
                    objects = _ps_compile_level_add_object(objects, <i,j>, new_object);
                    id += 1;
                }
            }
            // Step 3.3: Representation char included in the object definition 
            else {
                for (str name <- engine.objects.name) {
                    if(toLowerCase(engine.objects[name].rep_char) == rep_char) {
                        list[str] all_properties = get_properties_name(name, engine.references);  
                        LayerData ld = get_layer(engine, all_properties);

                        Object new_object = game_object(id, rep_char, name, all_properties, <i,j>, "", ld);
                        objects = _ps_compile_level_add_object(objects, <i,j>, new_object);
                        id += 1;
                    }
                }
            }
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
 * @Name:   _ps_compile_level_resolve_object
 * @Desc:   Function that resolves the name and representation character of the 
 *          given object 
 * @Param:  engine      -> Engine
 *          object_name -> Name of the object to resolve (note it cannot be a 
 *                         representation char in this case)
 * @Ret:    Tuple with representation char and object property name
 */
tuple[str, str] _ps_compile_level_resolve_object(Engine engine, str object_name) {
    list[str] possible_names = [object_name];

    // Case where the representation char is included in the object definition
    if (object_name in engine.objects && engine.objects[object_name].rep_char != "") return <toLowerCase(engine.objects[object_name].rep_char), object_name>;

    // Add the direct references of the "object_name" key 
    if (object_name in engine.references.key) possible_names += engine.references[object_name];

    // Search for a character that represents any of the possible object names in the references
    for (str key <- engine.references.key) {
        if(size(key) == 1, any(str name <- possible_names, name in engine.references[key])) return <toLowerCase(key), name>;
    }

    // Search for a character that represents any of the possible object names in the references
    for (str key <- engine.combinations.key) {
        if (size(key) == 1, any(str name <- possible_names, name in engine.combinations[key])) return <toLowerCase(key), name>;
    }

    return <"","">;
}

/*
 * @Name:   _ps_compile_level_resolve_player
 * @Desc:   Function that resolves the name and representation character of the 
 *          player
 * @Param:  engine -> Engine
 * @Ret:    Map with representation char as key and name as value
 */
tuple[str, str] _ps_compile_level_resolve_player(Engine engine) {
    return _ps_compile_level_resolve_object(engine, "player");
}

/*
 * @Name:   _ps_compile_level_resolve_background
 * @Desc:   Function that resolves the representation char and name of the
 *          background
 * @Param:  engine -> Engine
 * @Ret:    Map with representation char as key and name as value
 */
tuple[str,str] _ps_compile_level_resolve_background (Engine engine) {
    return _ps_compile_level_resolve_object(engine, "background");
}

/*
 * @Name:   _ps_compile_level_add_object
 * @Desc:   Function that adds an object to the given object coord map
 * @Param:  objects    -> Current map of coordinates and objects
 *          coords     -> Coordinates of the new object
 *          new_object -> New object to add
 * @Ret:    Updated map with the new object
 */
map[Coords, list[Object]] _ps_compile_level_add_object(map[Coords, list[Object]] objects, Coords coords, Object new_object) {
    if (coords in objects) objects[coords] += [new_object];
    else objects[coords] = [new_object];
    return objects;
}

/******************************************************************************/
// --- Public convert rules functions ------------------------------------------

/*
 * @Name:   _ps_compile_rules
 * @Desc:   Function to convert all the rules into a new rule structure with 
 *          more information. Additionally, we also index the rules to now their
 *          prior order
 * @Param:  engine -> Engine
 * @Ret:    Updated engine with the new converted rules
 */
Engine _ps_compile_rules(Engine engine) {
    int index = 0;
    for (RuleData rule <- engine.game.rules) {
        str rule_string = stringify_rule(rule.left, rule.right);
        engine.indexed_rules += (rule: <index, rule_string>);
        index += 1;

        if ("late" in [toLowerCase(lhs.prefix) | lhs <- rule.left, lhs is rule_prefix]) {
            list[Rule] rule_group = _ps_compile_rule(engine, rule, true);
            if (size(rule_group) != 0) engine.late_rules += [rule_group];
        }
        else {
            list[Rule] rule_group = _ps_compile_rule(engine, rule, false);
            if (size(rule_group) != 0) engine.rules += [rule_group];
        }
    }

    return engine;
}

/******************************************************************************/
// --- Public compile rule functions -------------------------------------------

/*
 * @Name:   _ps_compile_rule
 * @Desc:   Function to compile a rule
 * @Param:  engine -> engine
 *          rd     -> Rule AST node to be compiled
 *          late   -> Boolean indicating if it is a late rule
 * @Ret:    List witht the compiled rules. Bear in mind one rule compiles into 
 *          one or more rulesps_compile_rule(
 */
list[Rule] _ps_compile_rule(Engine engine, RuleData rd: rule_data(left, right, message, separator), bool late) {
    list[Rule] new_rule_directions = [];
    list[Rule] new_rules = [];
    list[Rule] new_rules2 = [];

    // We take the left part, the left prefixes and the left directions
    list[RulePart] new_left = [rp | RulePart rp <- left, rp is rule_part];
    list[RulePart] save_left = [rp | RulePart rp <- left, !(rp is rule_part)];
    list[str] directions = [toLowerCase(rp.prefix) | rp <- save_left, rp is rule_prefix && replaceAll(toLowerCase(rp.prefix), " ", "") != "late"];

    // We do the same for the right part
    list[RulePart] new_right = [rp | RulePart rp <- right, rp is rule_part];
    list[RulePart] save_right = [rp | RulePart rp <- right, !(rp is rule_part)];

    // We generate one new rule AST node with only the information we want
    RuleData new_rd = rule_data(new_left, new_right, message, separator);

    // Step 1: we extend the directions
    new_rule_directions = _ps_compile_rule_extend_directions(new_rd, directions);

    // Step 2: we translate the object relative directions to absolute ones
    for (Rule rule <- new_rule_directions) {
        Rule absolute_rule = _ps_compile_rule_relative_directions_to_absolute(rule);
        new_rules += [absolute_rule];
    }

    // Step 3: we add the prefixes and other commands we took out initially
    for (Rule rule <- new_rules) {
        rule.left += save_left;
        rule.right += save_right;
        new_rules2 += rule.late = late;
    }

    return new_rules2;
}

/*
 * @Name:   _ps_compile_rule_extend_directions
 * @Desc:   Function to extend the directions of a rule. It calls extend_direction
 *          which contains the exact extension functionality
 * @Param:  rd         -> Rule AST node to be extended
 *          directions -> Directions to be extended
 * @Ret:    Extended list of rules
 */
list[Rule] _ps_compile_rule_extend_directions(RuleData rd: rule_data(left, right, message, _), list[str] directions) {
    list[Rule] new_rule_directions = [];

    if(directions == []) directions = [""];

    for (direction <- directions) {
        new_rule_directions += _ps_compile_rule_extend_direction(rd, direction);
    }
    return new_rule_directions;
}

/*
 * @Name:   _ps_compile_rule_extend_direction
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
list[Rule] _ps_compile_rule_extend_direction(RuleData rd: rule_data(left, right, message, _), str direction) {
    list[Rule] new_rule_directions = [];
    Rule cloned_rule = game_rule_empty();

    // This direction modifiers are only accepted for objects
    if (direction == "perpendicular" || direction == "parallel") return [];

    if (direction in directionAggregates) { 
        list[str] directions = directionAggregates[toLowerCase(direction)];

        for (str direction <- directions) {
            cloned_rule = game_rule(
                false,      // Late boolean
                direction,  // Direction to be applied to
                left,       // LHS
                right,      // RHS
                false,      // Movement boolan
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
            false,      // Movement boolean
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
                false,      // Movement boolean
                rd          // Original AST node
            );
            new_rule_directions += cloned_rule;
        }
    }

    return new_rule_directions;
}

/*
 * @Name:   _ps_compile_rule_relative_directions_to_absolute
 * @Desc:   Function to convert the relative directios of a rule to absolute. 
 *          This means that if a rule has a direction UP, the relativeDirections
 *          get translated to their according absolute direction. It calls the 
 *          _ps_compile_rule_part_relative_directions_to_absolute function.
 * @Param:  rule -> Rule to have its relative directions converted
 * @Ret:    New rule with converted relative directions
 */
Rule _ps_compile_rule_relative_directions_to_absolute(Rule rule) {
    rule.movement = _ps_compile_rule_part_movement(rule.left);
    rule.left = _ps_compile_rule_part_relative_directions_to_absolute(rule.left, rule.direction);
    rule.right = _ps_compile_rule_part_relative_directions_to_absolute(rule.right, rule.direction);

    return rule;
}

bool _ps_compile_rule_part_movement(list[RulePart] rule_parts) {
    if (rule_parts == [] || rule_parts[0].contents == [] || rule_parts[0].contents[0].content == []) return false;
    return isDirection(rule_parts[0].contents[0].content[0]);
}

/*
 * @Name:   _ps_compile_rule_part_relative_directions_to_absolute
 * @Desc:   Function to convert the relative directions of a rule part to
 *          absolute ones. We now for a fact that the rule contents need to be 
 *          one direction, other keyword modifiers (e.g., no) and then the name.
 *          Additionally it sets all the names to lowercase
 * @Param:  rule_parts -> rule parts to convert to absoute directions
 *          direction  -> direction of the rule
 * @Ret:    Converted rule parts to absolute directions
 */
list[RulePart] _ps_compile_rule_part_relative_directions_to_absolute(list[RulePart] rule_parts, str direction) {
    list[RulePart] new_rp = [];
    
    for (RulePart rp <- rule_parts) {
        list[RuleContent] new_rc = [];

        // Step 1: If it is not a rule part we directly add it 
        if (!(rp is rule_part)) {
            new_rp += rp; 
            continue;
        }  

        // Step 2: If it is a rule part we need a bit more work
        for (RuleContent rc <- rp.contents) {
            list[str] new_content = [];

            // Step 2.1: If its size its 1 it means there is no direction, so 
            //           we leave the direction empty ""
            if (size(rc.content) == 1) {
                rc.content = [""] + [toLowerCase(rc.content[0])];
                new_rc += rc;
                continue;
            }
            


            // Step 2.2: If the size its bigger, either we have a given direction
            //           or we have a command. We need to figure it out
            str dir = "";
            bool skip = false;
            for (int i <- [0..size(rc.content)]) {
                if (skip) {
                    skip = false;
                    continue;
                }

                int index = indexOf(relativeDirections, rc.content[i]);
                // Step 2.2.1: We have a direction. 
                if (index >= 0) {
                    dir = relativeDict[direction][index];  
                    
                    new_content += [dir] + [toLowerCase(rc.content[i + 1])];
                    skip = true;
                // Step 2.2.2: We have a different keyword (e.g., no)
                } else {
                    new_content += [""] + [toLowerCase(rc.content[i])];
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
// --- Public convert level checker functions ----------------------------------

/*
 * @Name:   _ps_compile_level_checkers
 * @Desc:   Function to init and complete all the information inside the level 
 *          checkers
 * @Param:  engine -> Engine
 * @Ret:    Updated engine with the level checkers
 */
 Engine _ps_compile_level_checkers(Engine engine) {
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

        lc = _ps_compile_level_checker_size(lc, level);
        lc = _ps_compile_level_checker_starting_objects(lc, level);
        lc = _ps_compile_level_checker_to_be_applied_rules(lc, engine.rules, engine.late_rules);
        lc = _ps_compile_level_checker_moveable_objects(engine, lc, level);
        
        engine.level_checkers[level.original] = lc;
    }

    return engine;
}

/******************************************************************************/
// --- Private convert level checker functions ---------------------------------

/*
 * @Name:   _ps_compile_level_checker_size
 * @Desc:   Function that completes the size of a level chekcer
 * @Param:  engine -> Engine
 *          level  -> Level to get the size from
 * @Ret:    Updated map of level data and level checker
 */
LevelChecker _ps_compile_level_checker_size(LevelChecker lc, Level level) {
    lc.size = <size(level.original.level[0]), size(level.original.level)>;
    return lc;
}

/*
 * @Name:   _ps_compile_level_checker_starting_objects
 * @Desc:   Function to store the starting objects of a level on its level 
 *          checker
 * @Param:  lc    -> Level checker
 *          level -> Level
 * @Ret:    Updated level checker
 */
LevelChecker _ps_compile_level_checker_starting_objects(LevelChecker lc, Level level){
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
 * @Name:   _ps_compile_level_checker_to_be_applied_rules
 * @Desc:   Function to find those rules that can be applied per level
 * @Param:  lc         -> Level checker
 *          rules      -> Engine rules
 *          late_rules -> Engie late rules
 * @Ret:    Updated level checker
 */
LevelChecker _ps_compile_level_checker_to_be_applied_rules(LevelChecker lc, list[list[Rule]] rules, list[list[Rule]] late_rules) {
    list[list[Rule]] can_be_applied_rules = [];
    list[list[Rule]] can_be_applied_late_rules = [];

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

            // Step 1: We loop over the parts and get the objects from its contents
            for (RulePart rp <- rule.left) {
                if (!(rp is rule_part)) continue;

                for (RuleContent rc <- rp.contents) {
                    if ("..." in rc.content) continue;

                    required += [name | name <- rc.content, !(name == "no"), !(isDirection(name)), !(name == ""), !(name == "...")];
                }
            }

            int applied = 0;
            list[list[str]] placeholder = lc.starting_objects_names;
            
            // Step 2: We check if each required object of the left part rule is in the 
            //         starting objects of the level.
            for (int i <- [0..size(required)]) {
                str required_rc = required[i];

                if (any(int j <- [0..size(placeholder)], required_rc in placeholder[j])) {
                    applied += 1;
                } 
                else break;
            }

            // Step 3: If the applied is the same to size(required) it means that
            //         all objects of the left rule part are present in the level
            //         Therefore, this rule could be called and we need to do a 
            //         bit of work on the right side
            if (applied == size(required)) {
                list[list[RuleContent]] list_rc = [rulepart.contents | rulepart <- rule.right, rulepart is rule_part];

                // Step 3.1: We check if the right side calls an object that does 
                //           not exist on the level and add it to the starting 
                //           objects list
                for (list[RuleContent] lrc <- list_rc) {
                    list[str] new_objects = [
                        name | 
                        rc <- lrc, 
                        name <- rc.content, 
                        !(name == "no"), !(isDirection(name)), !(name == ""), !(name == "..."), 
                        !(any(list[str] objects <- lc.starting_objects_names, name in objects))
                        ];

                    if (size(new_objects) > 0) lc.starting_objects_names += [new_objects];
                }
                
                // Step 3.2: We now add the rule to the can be applied late rules
                //           or can be applied rules lists
                if (rule.late && !(lrule in can_be_applied_late_rules)) can_be_applied_late_rules += [lrule];
                if (!(rule.late) && !(lrule in can_be_applied_rules)) can_be_applied_rules += [lrule];
            }
        }
    }

    // Now we place them in order into the actual level checker lists
    list[list[Rule]] can_be_applied_rules_in_order = [];
    list[list[Rule]] can_be_applied_late_rules_in_order = [];

    for (int i <- [0..size(indexed<0>)]) {
        if (indexed[i] in can_be_applied_rules) can_be_applied_rules_in_order += [indexed[i]];
    }

    for (int i <- [0..size(indexed_late<0>)]) {
        if (indexed_late[i] in can_be_applied_late_rules) can_be_applied_late_rules_in_order += [indexed_late[i]];
    }

    lc.can_be_applied_late_rules = can_be_applied_late_rules_in_order;
    lc.can_be_applied_rules = can_be_applied_rules_in_order;

    return lc;
}

/*
 * @Name:   _ps_compile_level_checker_moveable_objects
 * @Desc:   Function to set all the moveable objects in a level checker
 * @Param:  lc    -> Level checker
 *          level -> Level
 * @Ret:    Updated level checker
 */
LevelChecker _ps_compile_level_checker_moveable_objects(Engine engine, LevelChecker lc, Level level) {
    for (list[Rule] lrule <- lc.can_be_applied_rules) {
        for (RulePart rp <- lrule[0].left) {
            if (rp is rule_part) lc = _ps_compile_level_checker_get_moveable_objects(engine, lc, rp.contents);
        }
        for (RulePart rp <- lrule[0].right) {
            if (rp is rule_part) lc = _ps_compile_level_checker_get_moveable_objects(engine, lc, rp.contents);
        }
    }

    return lc;
}

/*
 * @Name:   _ps_compile_level_checker_get_moveable_objects
 * @Desc:   Function to get the moveable objects of a level. We loop over the 
 *          rule side and add those objects that have a valid direction and that
 *          are starting objects of our level
 * @Param:  engine    -> Engine
 *          lc        -> Level checker to store the moveable objects
 *          rule_side -> Side of the rule to check
 */
LevelChecker _ps_compile_level_checker_get_moveable_objects(Engine engine, LevelChecker lc, list[RuleContent] rule_side) {
    list[str] found_objects = ["player"];

    for (RuleContent rc <- rule_side) {
        for (int i <- [0..(size(rc.content))]) {
            if (i mod 2 == 1) continue;
            
            str dir = rc.content[i];
            str name = rc.content[i + 1];
            
            if (isDirection(dir)) {
                if (!(name in found_objects)) found_objects += [name];
                if (name in engine.properties) {
                    found_objects += [
                        name | str name <- engine.properties[name],
                        any(list[str] l_name <- lc.starting_objects_names, name in l_name)
                        ];
                }
            }
        }
    } 
    lc.moveable_objects += found_objects;
    return lc;
}

/******************************************************************************/
// --- Public stringify functions ----------------------------------------------

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

/*****************************************************************************/
// --- Public Getter functions ------------------------------------------------

/*
 * @Name:   get_representation_char
 * @Desc:   Function to get the representation char of a given object
 * @Param:
 *      name        Object name 
 *      references  Map of all game object references
 * @Ret:    Representation char of the object
 */
str get_representation_char(str name, map[str, list[str]] references) {
    for (str char <- references<0>) {
        if (size(char) == 1 && name in references[char]) {  
            return toLowerCase(char);
        }
    }

    return "";
}

/*
 * @Name:   get_resolved_references (list version)
 * @Desc:   Function to get the references of a key of the legend in a 
 *          map of references.
 *          Generally used with the keys of the game legend. For this purpose,
 *          remember that keys in the legend can be a representation char
 *          or an alias (such as Player, Obstacle...)
 * @Param:
 *      keys         Legend key elements
 *      references  Map of references on which to search
 * @Ret:    List of non duped references of the key (including the actual keys)
 */
list[str] get_resolved_references(list[str] keys, map[str, list[str]] references) {
    list[str] resolved_references = [];

    for(str key <- keys){
        resolved_references += get_resolved_references(key, references);
    }

    return toList(toSet(resolved_references));
}

/*
 * @Name:   get_resolved_references (single key version)
 * @Desc:   Function to get the references of a key of the legend in a 
 *          map of references.Used with the keys of the game legend. For this,
 *          remember that keys in the legend can be a representation char,
 *          object name (Player) or an alias (Obstacle = Wall, Crate)
 * @Param:  key        -> Legend key element (usuarlly a name, alias or a
 *                        representation char)
 *          references -> Map of references on which to search
 * @Ret:    List of non duped references of the key (including the actual keys)
 */
list[str] get_resolved_references(str key, map[str, list[str]] references) {
    list[str] resolved_references = [];

    if (!(key in references<0>)) return resolved_references;

    for (str rf <- references[key]) {
        new_references = get_resolved_references(rf, references);
        if (isEmpty(new_references)) resolved_references += [rf];
        else resolved_references += new_references;
    }

    return toList(toSet(resolved_references));
}

/*
 * @Name:   get_properties_rep_char
 * @Desc:   Function to get the properties of a representatio char. This are the 
 *          properties of each of the object names it references.
 * @Param:  rep_char   -> Representation char of the references dictionary 
 *          references -> Map of all game object references
 * @Ret:    References of the representation char
 */
list[str] get_properties_rep_char(str rep_char, map[str, list[str]] references) {
    if (!(rep_char in references<0>)) return [];

    list[str] all_properties = [];
    list[str] unresolved_references = references[rep_char];
    all_properties += unresolved_references;

    for (str rf <- unresolved_references) {
        if (size(rf) == 1) all_properties += get_propeties_rep_char(rf, references);
        else all_properties += get_properties_name(rf, references);
    }

    return toList(toSet(all_properties));
}

/*
 * @Name:   get_properties_name
 * @Desc:   Function to get the all properties of a given object name.
 *          A property refers to the non-sized 1 keys of the legend that contain
 *          the object name
 * @Param:  name       -> Object name (or alias of object names)
 *          references -> Map of all references
 * @Ret:    Properties of the reference
 */
list[str] get_properties_name(str name, map[str, list[str]] references) {
    list[str] all_properties = [name];

    for (str rf <- references) {
        if (size(rf) == 1) continue;

        if (name in references[rf]) {
            all_properties += rf;
            all_properties += get_properties_name(rf, references);
        }
    }

    return toList(toSet(all_properties));
}

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
 * @Param:  engine -> Engine
 *          object -> List of object names
 * @Ret:    Layer object (empty if not found)
 */
LayerData get_layer(Engine engine, list[str] object) {
    for (LayerData layer <- engine.game.layers) {
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