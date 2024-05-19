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

// Section annotation (Deprecated in 2024 rascal)
anno loc PreludeData@location;
anno loc PSGame@location;
anno loc Section@location;
anno loc RulePart@location;
anno loc RuleContent@location;
anno loc ObjectData@location;
anno loc LegendData@location;
anno loc SoundData@location;
anno loc RuleData@location;
anno loc ConditionData@location;
anno loc LevelData@location;
anno loc Sprite@location;
anno loc LegendOperation@location;
anno loc LayerData@location;

anno str PreludeData@label;
anno str Section@label;
anno str ObjectData@label;
anno str LegendData@label;
anno str SoundData@label;
anno str RuleData@label;
anno str ConditionData@label;
anno str LayerData@label;
anno str LevelData@label;
anno str Pixel@color;

/*
 * @Name:   PSGame
 * @Desc:   AST of a PuzzleScript game
 */
data PSGame (loc src = |unknown:///|)
  = game(list[Prelude] pr, list[Section] sections)  // Game composed of a prelude and a list of sections (???)
  | game(                                           // Game composed of several lists: (???)
      list[PreludeData] prelude,                    // Prelude list
      list[ObjectData] objects,                     // Objects list
      list[LegendData] legend,                      // Legend list
      list[SoundData] sounds,                       // Sounds list
      list[LayerData] layers,                       // Layers list
      list[RuleData] rules,                         // Rules list
      list[ConditionData] conditions,               // Conditions list
      list[LevelData] levels,                       // Levels list
      list[Section] sections                        // Sections list
  )
  | game_empty(str)                                 // Empty game
  ;

/*
 * @Name:   Prelude
 * @Desc:   AST node for the Prelude section
 */ 	
data Prelude (loc src = |unknown:///|)
  = prelude(list[PreludeData] datas);               // Prelude data (???)

/*
 * @Name:   PreludeData
 * @Desc:   AST node for the data of the Prelude
 */ 	
data PreludeData (loc src = |unknown:///|)
  = prelude_data(str key, str string, str)          // Title, author and website
  | prelude_empty(str);                             // Empty prelude section
	
/*
 * @Name:   Section
 * @Desc:   AST node for the remaining PuzzleScript sections
 */ 
data Section (loc src = |unknown:///|)
  = s_objects(str sep1, str name, str sep2, list[ObjectData] objects)               // Objects section
  | s_legend(str sep1, str name, str sep2, list[LegendData] legend)                 // Legend section
  | s_sounds(str sep1 , str name, str sep2, list[SoundData] sounds)                 // Sounds section
  | s_layers(str sep1, str name, str sep2, list[LayerData] layers)                  // Layers section
  | s_rules(str sep1, str name, str sep2, list[RuleData] rules)                     // Rules section
  | s_conditions(str sep1, str name, str sep2, list[ConditionData] conditions)      // Win Conditions section
  | s_levels(str sep1, str name, str sep2, list[LevelData] levels)                  // Levels section 
  | s_empty(str sep1, str name, str sep2, str linebreaks)                           // Empty section
  ;

/*
 * @Name:   ObjectData
 * @Desc:   AST node for game objects
 */ 
data ObjectData (loc src = |unknown:///|)
  = object_data(str name, list[str] legend, str, list[str] colors, str, list[Sprite] spr)           // Name, legend characters, (???), colors, (???), sprite
  | object_data(str name, list[str] legend, list[str] colors, list[list[Pixel]] sprite, int id)     // Name, legend characters, colors, sprite, identifier
  | object_empty(str)                                                                               // Empty object
  ;

/*
 * @Name:   Sprite
 * @Desc:   AST node for object's sprite. Defined as a 5x5 matrix.
 */ 	
data Sprite 
  = sprite( 
      str line0, str,   // Line 0,
      str line1, str,   // Line 1,
      str line2, str,   // Line 2,
      str line3, str,   // Line 3,
      str line4, str    // Line 4,
  );
      
/*
 * @Name:   Pixel
 * @Desc:   AST node for pixel
 */ 
data Pixel
  = pixel(str pixel);   // Pixel

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
data LegendData (loc src = |unknown:///|)
  = legend_data(str legend, str first, list[LegendOperation] others, str)   // (???)
  | legend_alias(str legend, list[str] values)                              // (???)
  | legend_combined(str legend, list[str] values)                           // (???)
  | legend_error(str legend, list[str] values)                              // (???)
  | legend_empty(str)                                                       // Empty legend section
  ;	

/*
 * @Name:   SoundData
 * @Desc:   AST node for the game sounds
 */ 
data SoundData (loc src = |unknown:///|)
  = sound_data(list[str] sound, str)    // List of sounds, Comment (???)
  | sound_empty(str)                    // Empty sound section
  ;
	
/*
 * @Name:   LayerData
 * @Desc:   AST node for the game layers
 */ 
data LayerData (loc src = |unknown:///|)
  = layer_data(list[str] layer, str)    // List of layers, Comment (???)
  | layer_data(list[str] layer)         // List of layers
  | layer_empty(str)                    // Empty layers section
  ;

/*
 * @Name:   RuleData
 * @Desc:   AST node for the game rules
 */ 
data RuleData (loc src = |unknown:///|)
  = rule_data(list[RulePart] left, list[RulePart] right, list[str] message, str)    // Single rule:   LHS, RHS, Message, Comment (???)
  | rule_loop(list[RuleData] rules, str)                                            // Looped rules: Rules List, Comment 
  | rule_empty(str)                                                                 // Empty rules section
  ;

/*
 * @Name:   RulePart
 * @Desc:   AST node for the rule parts
 */ 
data RulePart (loc src = |unknown:///|)
  = part(list[RuleContent] contents)    // Rule part
  | command(str command)                // Rule command
  | sound(str sound)                    // Rule sound
  | prefix(str prefix)                  // Rule prefix
  ;

/*
 * @Name:   RuleContent
 * @Desc:   AST node for the rule parts
 */ 
data RuleContent (loc src = |unknown:///|)
  = content(list[str] content);     // Content of the rule

/*
 * @Name:   ConditionData
 * @Desc:   AST node for the win conditions
 */ 
data ConditionData (loc src = |unknown:///|)
  = condition_data(list[str] condition, str)    // Win condition, Comment (???)
  | condition_empty(str)                        // Empty win condition section
  ;

/*
 * @Name:   LevelData
 * @Desc:   AST node for the game levels
 */ 
data LevelData (loc src = |unknown:///|)
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
