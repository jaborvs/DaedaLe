module PuzzleScript::AST

import List;

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

data PSGame (loc src = |unknown:///|)
  = game(list[Prelude] pr, list[Section] sections)
  | game(
      list[PreludeData] prelude, 
      list[ObjectData] objects,
      list[LegendData] legend,
      list[SoundData] sounds,
      list[LayerData] layers,
      list[RuleData] rules,
      list[ConditionData] conditions,
      list[LevelData] levels,
      list[Section] sections
  )
  | game_empty(str)
  ;
 	
data Prelude (loc src = |unknown:///|)
  = prelude(list[PreludeData] datas);

data PreludeData (loc src = |unknown:///|)
  = prelude_data(str key, str string, str)
  | prelude_empty(str);  
	
data Section (loc src = |unknown:///|)
  = s_objects(str sep1, str name, str sep2, list[ObjectData] objects)
  | s_legend(str sep1, str name, str sep2, list[LegendData] legend)
  | s_sounds(str sep1 , str name, str sep2, list[SoundData] sounds)
  | s_layers(str sep1, str name, str sep2, list[LayerData] layers)
  | s_rules(str sep1, str name, str sep2, list[RuleData] rules)
  | s_conditions(str sep1, str name, str sep2, list[ConditionData] conditions)
  | s_levels(str sep1, str name, str sep2, list[LevelData] levels)
  | s_empty(str sep1, str name, str sep2, str linebreaks)
  ;

data ObjectData (loc src = |unknown:///|)
  = object_data(str name, list[str] legend, str, list[str] colors, str, list[Sprite] spr)
  | object_data(str name, list[str] legend, list[str] colors, list[list[Pixel]] sprite, int id)
  | object_empty(str)
  ;
	
data Sprite 
  = sprite( 
      str line0, str,
      str line1, str,
      str line2, str, 
      str line3, str,
      str line4, str
  );
      
data Pixel
  = pixel(str pixel);

data LegendOperation
  = legend_or(str id)
  | legend_and(str id)
  ;

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
