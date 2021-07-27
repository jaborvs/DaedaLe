module PuzzleScript::AST

anno loc PRELUDEDATA@location;
anno loc PRELUDE@location;
anno loc PSGAME@location;
anno loc SECTION@location;
anno loc OBJECTS@location;
anno loc RULEPART@location;
anno loc RULECONTENT@location;
anno loc OBJECTDATA@location;
anno loc LEGENDDATA@location;
anno loc SOUNDDATA@location;
anno loc RULEDATA@location;
anno loc CONDITIONDATA@location;
anno loc LEVELDATA@location;
anno loc LEGEND@location;
anno loc SOUNDS@location;
anno loc LAYERS@location;
anno loc RULES@location;
anno loc WINCONDITIONS@location;
anno loc LEVELS@location;
anno loc SPRITE@location;
anno loc LEGENDOPERATION@location;
anno loc LAYERDATA@location;
anno loc PSGAME@location;

data PRELUDEDATA 
	= prelude_data(str key, str string, str)
	;
	
data PRELUDE
	= prelude(list[PRELUDEDATA] datas)
	| empty(str)
	;

data PSGAME
 	= game(PRELUDE prelude, list[SECTION] sections)
 	| game(
 		PRELUDE prelude, 
 		list[OBJECTDATA] objects,
 		list[LEGENDDATA] legend,
 		list[SOUNDDATA sound] sounds,
 		list[LAYERDATA] layers,
 		list[RULEDATA] rules,
 		list[CONDITIONDATA] conditions,
 		list[LEVELDATA] levels,
 		list[SECTION] sections
 	)	
 	| empty(str)
 	;
 	
data SECTION
 	= objects(OBJECTS objects)
 	| legend(LEGEND legend)
 	| sounds(SOUNDS sounds)
 	| layers(LAYERS layers)
 	| rules(RULES rules)
 	| conditions(WINCONDITIONS conditions)
 	| levels(LEVELS levels)
 	| empty(str, str name, str, str)
 	;
 	
data OBJECTS
	= objects(str, str, str, list[OBJECTDATA] objects)
	;
	
data OBJECTDATA
	= object_data(str id, list[str] legend, str, list[str] colors, str, list[SPRITE] spr)
	| object_data(str id, list[str] legend, list[str] colors, list[list[str]] sprite)
	| object_empty(str)
	;
	
data SPRITE 
    =  sprite( 
       str line0, str,
       str line1, str,
       str line2, str, 
       str line3, str,
       str line4, str
      );
      
data LEGEND
	= legend(str, str, str, list[LEGENDDATA] legend)
	;
	
data LEGENDOPERATION
	= legend_or(str id)
	| legend_and(str id)
	;

data LEGENDDATA
	= legend_data(str legend, str first, list[LEGENDOPERATION] others, str)
	| legend_alias(str legend, list[str] values)
	| legend_combined(str legend, list[str] values)
	| legend_error(str legend, list[str] values)
	;	
	
data SOUNDS
	= sounds(str, str, str, list[tuple[SOUNDDATA sound, str lines]] sounds)
	;
	
data SOUNDDATA
	= sound_data(list[str])
	;

data LAYERS
	= layers(str, str, str, list[LAYERDATA] layers)
	;
	
data LAYERDATA
	= layer_data(list[str] layer, str)
	| layer_data(list[str] layer)
	;
	
data RULES
	= rules(str, str, str, list[RULEDATA] rules)
	;

data RULEDATA
	= rule_data(list[str] prefix, list[RULEPART] left, list[RULEPART] right, list[str] message, str)
	;
	
data RULEPART
	= part(list[RULECONTENT] contents)
	| command(str command)
	| sound(str sound)
	;

data RULECONTENT
	= content(list[str])
	;

data WINCONDITIONS
	= conditions(str, str, str, list[CONDITIONDATA] conditions)
	;

data CONDITIONDATA
	= condition_data(list[str] condition, str)
	;
	
data LEVELS
	= levels(str, str, str, list[LEVELDATA] levels, str)
	;
	
data LEVELDATA
	= level_data_raw(list[tuple[str, str]] lines)
	| level_data(list[str] level)
	| message(str message)
	;
