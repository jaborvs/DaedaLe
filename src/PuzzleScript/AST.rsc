/*
 * @Module: AST
 * @Desc:   Module to parse the AST of a PuzzleScript game
 */
module PuzzleScript::AST

/*****************************************************************************/
// --- General modules imports ------------------------------------------------
import List;

/*****************************************************************************/
// --- Global defines ---------------------------------------------------------

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
 *  @Name:  PSGame
 *  @Desc:  Data structure for a PuzzleScript game AST
 */
data PSGame (loc src = |unknown:///|)
  = game(list[Prelude] pr, list[Section] sections)  // Game composed of a prelude and a list of sections
  | game(                                           // Game composed of several lists:
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
 *  @Name:  Prelude
 *  @Desc:  Data structure for the Prelude section
 */ 	
data Prelude (loc src = |unknown:///|)
  = prelude(list[PreludeData] datas);               // Prelude data

/*
 *  @Name:  PreludeData
 *  @Desc:  Data structure for the data of the Prelude section
 */ 	
data PreludeData (loc src = |unknown:///|)
  = prelude_data(str key, str string, str)          // Title, author and website
  | prelude_empty(str);                             // Emptu prelude
	
/*
 *  @Name:  Section
 *  @Desc:  Data structure for the remaining PuzzleScript sections
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
 *  @Name:  ObjectData
 *  @Desc:  Data structure for the game objects of the Objects section
 */ 
data ObjectData (loc src = |unknown:///|)
  = object_data(str name, list[str] legend, str, list[str] colors, str, list[Sprite] spr)           // Name, legend characters, (???), colors, (???), sprite
  | object_data(str name, list[str] legend, list[str] colors, list[list[Pixel]] sprite, int id)     // Name, legend characters, colors, sprite, identifier
  | object_empty(str)                                                                               // Empty object
  ;

/*
 *  @Name:  Sprite
 *  @Desc:  Data structure for an object's sprite
 */ 	
data Sprite 
  = sprite( 
      str line0, str,   // Line 0, (???)
      str line1, str,   // Line 1, (???)
      str line2, str,   // Line 2, (???)
      str line3, str,   // Line 3, (???)
      str line4, str    // Line 4, (???)
  );
      
/*
 *  @Name:  Pixel
 *  @Desc:  Data structure for an game pixel
 */ 
data Pixel
  = pixel(str pixel);   // Pixel

/*
 *  @Name:  LegendOperation
 *  @Desc:  Data structure for the game legend operations
 */ 
data LegendOperation
  = legend_or(str id)   // Or identifier
  | legend_and(str id)  // And identifier
  ;

/*
 *  @Name:  LegendData
 *  @Desc:  Data structure for the game legend data
 */ 
data LegendData (loc src = |unknown:///|)
  = legend_data(str legend, str first, list[LegendOperation] others, str)  
  | legend_alias(str legend, list[str] values)
  | legend_combined(str legend, list[str] values)
  | legend_error(str legend, list[str] values)
  | legend_empty(str)
  ;	

data SoundData (loc src = |unknown:///|)
  = sound_data(list[str] sound, str)
  | sound_empty(str)
  ;
	
data LayerData (loc src = |unknown:///|)
  = layer_data(list[str] layer, str)
  | layer_data(list[str] layer)
  | layer_empty(str)
  ;

data RuleData (loc src = |unknown:///|)
  = rule_data(list[RulePart] left, list[RulePart] right, list[str] message, str)
  | rule_loop(list[RuleData] rules, str)
  | rule_empty(str)
  ;

data RulePart (loc src = |unknown:///|)
  = part(list[RuleContent] contents)
  | command(str command)
  | sound(str sound)
  | prefix(str prefix)
  ;

data RuleContent (loc src = |unknown:///|)
  = content(list[str] content);

data ConditionData (loc src = |unknown:///|)
  = condition_data(list[str] condition, str)
  | condition_empty(str)
  ;

data LevelData (loc src = |unknown:///|)
  = level_data_raw(list[tuple[str,str]] lines, str)
  | level_data(list[str] level)
  | message(str message)
  | level_empty(str)
  ;

str toString(RuleContent _: content(list[str] cnt)){
  return intercalate(" ", cnt);
}
	
str toString(RulePart _: part(list[RuleContent] contents)){
  return "[ " + intercalate(" | ", [toString(x) | x <- contents]) + " ]";
}

str toString(RulePart _: command(str cmd)){
  return cmd;
}

str toString(RulePart _: sound(str snd)){
  return snd;
}

str toString(RulePart _: prefix(str pr)){
	return pr;
}
