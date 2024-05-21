/*
 * @Module: AST
 * @Desc:   Module to parse the AST of a PuzzleScript game. It contains all the 
 *          AST node data structure definitions and some toString methods for 
 *          them
 * @Auth:   Dennis Vet    -> code
 *          Borja Velasco -> code, comments
 */
module PuzzleScript::AST

/*****************************************************************************/
// --- General modules imports ------------------------------------------------
import List;

/*****************************************************************************/
// --- Data structure defines -------------------------------------------------

/*
 * @Name:   PSGame
 * @Desc:   AST of a PuzzleScript game
 */
data PSGame
    = game(list[Prelude] pr, list[Section] sections)   // Unprocessed version: Game composed of a prelude, a list of sections and its file location
    | game(                                                     // Processed version:
        list[PreludeData] prelude,                              //      Prelude list
        list[ObjectData] objects,                               //      Objects list
        list[LegendData] legend,                                //      Legend list
        list[SoundData] sounds,                                 //      Sounds list
        list[LayerData] layers,                                 //      Layers list
        list[RuleData] rules,                                   //      Rules list
        list[ConditionData] conditions,                         //      Conditions list
        list[LevelData] levels                                  //      Levels list
    )
    | game_empty(str)                                       // Empty game
    ;

/*
 * @Name:   Prelude
 * @Desc:   AST node for the Prelude section
 */     
data Prelude
    = prelude(list[PreludeData] datas);         // List of PreludeData

/*
 * @Name:   PreludeData
 * @Desc:   AST node for the data of the Prelude. The last not name str refers
 *          to the separator (a \n in this case)
 */     
data PreludeData
    = prelude_data(str key, str val, str)       // Key, value
    | prelude_empty(str);                       // Empty prelude section
    
/*
 * @Name:   Section
 * @Desc:   AST node for the remaining PuzzleScript sections. Note that the 
 *          Prelude cannot be included here since it does not have a separator
 */ 
data Section
    = s_objects(str sep1, str name, str sep2, list[ObjectData] objects)             // Objects section
    | s_legend(str sep1, str name, str sep2, list[LegendData] legend)               // Legend section
    | s_sounds(str sep1 , str name, str sep2, list[SoundData] sounds)               // Sounds section
    | s_layers(str sep1, str name, str sep2, list[LayerData] layers)                // Layers section
    | s_rules(str sep1, str name, str sep2, list[RuleData] rules)                   // Rules section
    | s_conditions(str sep1, str name, str sep2, list[ConditionData] conditions)    // Win Conditions section
    | s_levels(str sep1, str name, str sep2, list[LevelData] levels)                // Levels section 
    | s_empty(str sep1, str name, str sep2, str linebreaks)                         // Empty section
    ;

/*
 * @Name:   ObjectData
 * @Desc:   AST node for game objects
 */ 
data ObjectData
    = object_data(str name, str, list[str] colors, str, list[Sprite] spr)   // Unprocessed object: Name, separator (\n), colors, separator (\n), sprite
    | object_data(str name, list[str] colors, list[list[Pixel]] sprite)     // Processed object:   Name, colors, sprite 
    | object_empty(str)                                                     // Empty object
    ;

/*
 * @Name:   Sprite
 * @Desc:   AST node for object's sprite. Defined as a 5x5 matrix.
 */     
data Sprite 
  = sprite(str line0, str, str line1, str, str line2, str, str line3, str, str line4, str   // Line i, separator (\n) 
  );
      
/*
 * @Name:   Pixel
 * @Desc:   AST node for pixels (numbers and .s in object's sprites)
 */ 
data Pixel
  = pixel(str color_number);   // Color number

/*
 * @Name:   LegendOperation
 * @Desc:   AST node for the game legend operations
 */ 
data LegendOperation
  = legend_or(str id)   // Or identifier
  | legend_and(str id)  // And identifier
  ;

/*
 * @Name:   LegendData
 * @Desc:   AST node for the game legend
 */ 
data LegendData
  = legend_data(str legend, str first, list[LegendOperation] others, str)   // (???)
  | legend_reference(str legend, list[str] values)                              // (???)
  | legend_combined(str legend, list[str] values)                           // (???)
  | legend_error(str legend, list[str] values)                              // (???)
  | legend_empty(str)                                                       // Empty legend section
  ;    

/*
 * @Name:   SoundData
 * @Desc:   AST node for the game sounds
 */ 
data SoundData
  = sound_data(list[str] sound, str)    // List of sounds, Comment (???)
  | sound_empty(str)                    // Empty sound section
  ;
    
/*
 * @Name:   LayerData
 * @Desc:   AST node for the game layers
 */ 
data LayerData
  = layer_data(list[str] layer, str)    // List of layers, Comment (???)
  | layer_data(list[str] layer)         // List of layers
  | layer_empty(str)                    // Empty layers section
  ;

/*
 * @Name:   RuleData
 * @Desc:   AST node for the game rules
 */ 
data RuleData
  = rule_data(list[RulePart] left, list[RulePart] right, list[str] message, str)    // Single rule:   LHS, RHS, Message, Comment (???)
  | rule_loop(list[RuleData] rules, str)                                            // Looped rules: Rules List, Comment 
  | rule_empty(str)                                                                 // Empty rules section
  ;

/*
 * @Name:   RulePart
 * @Desc:   AST node for the rule parts
 */ 
data RulePart
  = part(list[RuleContent] contents)    // Rule part
  | command(str command)                // Rule command
  | sound(str sound)                    // Rule sound
  | prefix(str prefix)                  // Rule prefix
  ;

/*
 * @Name:   RuleContent
 * @Desc:   AST node for the rule parts
 */ 
data RuleContent
  = content(list[str] content);     // Content of the rule

/*
 * @Name:   ConditionData
 * @Desc:   AST node for the win conditions
 */ 
data ConditionData
  = condition_data(list[str] condition, str)    // Win condition, Comment (???)
  | condition_empty(str)                        // Empty win condition section
  ;

/*
 * @Name:   LevelData
 * @Desc:   AST node for the game levels
 */ 
data LevelData
  = level_data_raw(list[tuple[str,str]] lines, str)     // (???)
  | level_data(list[str] level)                         // (???)
  | message(str message)                                // Message in between levels
  | level_empty(str)                                    // Empty levels section
  ;

/*****************************************************************************/
// --- Public functions -------------------------------------------------------

/*
 * @Name:   toString
 * @Desc:   converts a RuleContent into a string
 * @Ret:    string containing the RuleContent
 */ 
str toString(RuleContent _: content(list[str] cnt)){
  return intercalate(" ", cnt);
}

/*
 * @Name:   toString
 * @Desc:   converts a RulePart (part(list[RuleContent] contents)) into a string
 * @Ret:    string containing the RulePart
 */ 
str toString(RulePart _: part(list[RuleContent] contents)){
  return "[ " + intercalate(" | ", [toString(x) | x <- contents]) + " ]";
}

/*
 * @Name:   toString
 * @Desc:   converts a RulePart (command(str cmd)) into a string
 * @Ret:    string containing the RulePart
 */ 
str toString(RulePart _: command(str cmd)){
  return cmd;
}

/*
 * @Name:   toString
 * @Desc:   converts a RulePart (sound(str snd)) into a string
 * @Ret:    string containing the RulePart
 */ 
str toString(RulePart _: sound(str snd)){
  return snd;
}

/*
 * @Name:   toString
 * @Desc:   converts a RulePart (prefix(str pr)) into a string
 * @Ret:    string containing the RulePart
 */ 
str toString(RulePart _: prefix(str pr)){
    return pr;
}
