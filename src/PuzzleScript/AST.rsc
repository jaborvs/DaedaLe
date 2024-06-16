/*
 * @Module: AST
 * @Desc:   Module to parse the AST of a PuzzleScript game. It contains all the 
 *          AST node data structure definitions and some toString methods for 
 *          them
 * @Auth:   Dennis Vet    -> code
 *          Borja Velasco -> code, comments
 */
module PuzzleScript::AST

/******************************************************************************/
// --- Game structure defines --------------------------------------------------

/*
 * @Name:   GameData
 * @Desc:   AST of a PuzzleScript game
 */
data GameData
    = game_data(list[Prelude] pr, list[Section] sections)   // Unprocessed version: Game composed of a prelude, a list of sections and its file location
    | game_data(                                            // Processed version:
        list[PreludeData] prelude,                          //      Prelude list
        list[ObjectData] objects,                           //      Objects list
        list[LegendData] legend,                            //      Legend list
        list[SoundData] sounds,                             //      Sounds list
        list[LayerData] layers,                             //      Layers list
        list[RuleData] rules,                               //      Rules list
        list[ConditionData] conditions,                     //      Conditions list
        list[LevelData] levels                              //      Levels list
    )
    | game_empty(str)                                       // Empty game
    ;

/******************************************************************************/
// --- Prelude structure defines -----------------------------------------------

/*
 * @Name:   Prelude
 * @Desc:   AST node for the Prelude section
 */     
data Prelude
    = prelude(list[PreludeData] datas);         // List of PreludeData

/*
 * @Name:   PreludeData
 * @Desc:   AST node for the data of the Prelude.
 */     
data PreludeData
    = prelude_data(str keywrd, str params, str) // Unprocessed prelude item: keyword, params separator (\n)
    | prelude_data(str keywrd, str params)      // Processed prelude item: keyword, params
    | prelude_empty(str);                       // Empty prelude section

/******************************************************************************/
// --- Section structure defines -----------------------------------------------

/*
 * @Name:   Section
 * @Desc:   AST node for the remaining PuzzleScript sections. Note that the 
 *          Prelude cannot be included here since it does not have a separator
 */ 
data Section
    = section_objects(str sep1, str name, str sep2, list[ObjectData] objects)             // Objects section
    | section_legend(str sep1, str name, str sep2, list[LegendData] legend)               // Legend section
    | section_sounds(str sep1 , str name, str sep2, list[SoundData] sounds)               // Sounds section
    | section_layers(str sep1, str name, str sep2, list[LayerData] layers)                // Layers section
    | section_rules(str sep1, str name, str sep2, list[RuleData] rules)                   // Rules section
    | section_conditions(str sep1, str name, str sep2, list[ConditionData] conditions)    // Win Conditions section
    | section_levels(str sep1, str name, str sep2, list[LevelData] levels)                // Levels section 
    | section_empty(str sep1, str name, str sep2, str linebreaks)                         // Empty section
    ;

/******************************************************************************/
// --- Object structure defines ------------------------------------------------

/*
 * @Name:   ObjectData
 * @Desc:   AST node for game objects
 */ 
data ObjectData
    = object_data(str name, str rep_char, str, list[str] colors, str, list[Sprite] spr)    // Unprocessed object: Name, separator (\n), colors, separator (\n), sprite
    | object_data(str name, str rep_char, list[str] colors, list[list[Pixel]] sprite)           // Processed object:   Name, colors, sprite 
    | object_empty(str)                                                                         // Empty object
    ;

/*
 * @Name:   Sprite
 * @Desc:   AST node for object's sprite. Defined as a 5x5 matrix.
 */     
data Sprite 
    = sprite(
        str line0, str, // Line 1, separator (\n) 
        str line1, str, // Line 2, separator (\n)
        str line2, str, // Line 3, separator (\n)
        str line3, str, // Line 4, separator (\n)
        str line4, str  // Line 5, separator (\n) 
    );
      
/*
 * @Name:   Pixel
 * @Desc:   AST node for pixels (numbers and .s in object's sprites)
 */ 
data Pixel
    = pixel(str color_number);  // Color number

/******************************************************************************/
// --- Legend structure defines ------------------------------------------------

/*
 * @Name:   LegendData
 * @Desc:   AST node for the game legend
 */ 
data LegendData
    = legend_data(str key, str first_item, list[LegendOperation] other_items, str)    // Unprocessed legend element: key, first (object name or legend key), rest (objects or legend elements)
    | legend_reference(str key, list[str] items)                                      // Processed legend element: comes from an element joined by ORs
    | legend_combined(str key, list[str] items)                                       // Processed legend element: comes from an element joined by ANDs
    | legend_error(str key, list[str] items)                                          // Processed legend element: comes from an element joined by ORs and ANDs
    | legend_empty(str)                                                               // Empty legend element
    ;    

/*
 * @Name:   LegendOperation
 * @Desc:   AST node for the rest of the elements of game legend
 */ 
data LegendOperation
    = legend_or(str item)      // OR ckeyase: object name or legend element key
    | legend_and(str item)     // AND case: object name legend element key
    ;

/******************************************************************************/
// --- Sound structure defines ------------------------------------------------

/*
 * @Name:   SoundData
 * @Desc:   AST node for the game sounds
 */ 
data SoundData
    = sound_data(list[str] sound, str)  // Unprocessed sound: list of items, separator (\n)
    | sound_data(list[str] sound)       // Processed sound: list of items   
    | sound_empty(str)                  // Empty sound
    ;

/******************************************************************************/
// --- Layer structure defines -------------------------------------------------
    
/*
 * @Name:   LayerData
 * @Desc:   AST node for the game layers
 */ 
data LayerData
    = layer_data(list[str] items, str)    // Unprocessed layer: items (object names or legend keys), separator (\n)
    | layer_data(list[str] items)         // Processed layer: items (object names or legend keys)
    | layer_empty(str)                    // Empty layer
    ;

/******************************************************************************/
// --- Rule structure defines --------------------------------------------------

/*
 * @Name:   RuleData
 * @Desc:   AST node for the game rules
 */ 
data RuleData
    = rule_data(list[RulePart] left, list[RulePart] right, list[str] message, str, loc src =  |unknown:///|, map[int, list[str]] comments = ())  // Unprocessed single rule: lhs, rhs, message, separator (\n)
    | rule_data(list[RulePart] left, list[RulePart] right, list[str] message)       // Processed single rule: lhs, rhs, message
    | rule_loop(list[RuleData] rules, str)                                          // Unprocessed looped rules: rule list, separator (\n)
    | rule_loop(list[RuleData] rules)                                               // Processed rules: rule list
    | rule_empty(str)                                                               // Empty rule
    ;

/*
 * @Name:   RulePart
 * @Desc:   AST node for the rule parts
 */ 
data RulePart
    = rule_part(list[RuleContent] contents)    // Rule part: contents list
    | rule_command(str command)                // Rule command: command
    | rule_sound(str sound)                    // Rule sound: sound
    | rule_prefix(str prefix)                  // Rule prefix: prefix
    ;

/*
 * @Name:   RuleContent
 * @Desc:   AST node for the rule parts
 */ 
data RuleContent
    = rule_content(list[str] content)     // Content of the rule
    ;

/******************************************************************************/
// --- Win condition structure defines -----------------------------------------

/*
 * @Name:   ConditionData
 * @Desc:   AST node for the win conditions
 */ 
data ConditionData
    = condition_data(list[str] items, str)  // Unprocessed win condition: items, separator (\n)
    | condition_data(list[str] items)       // Processed win condition: items
    | condition_empty(str)                  // Empty win condition
    ;

/******************************************************************************/
// --- Level structure defines -------------------------------------------------

/*
 * @Name:   LevelData
 * @Desc:   AST node for the game levels
 */ 
data LevelData
    = level_data(list[tuple[str,str]] lines, str)   // Unprocessed level: list of lines (tuple of the actual object representation chars and separator \n), separator (\n)
    | level_data(list[str] level)                   // Processed level
    | level_message(str message)                    // Message in between levels
    | level_empty(str)                              // Empty level
    ;
