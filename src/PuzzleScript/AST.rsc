module PuzzleScript::AST

data PRELUDEDATA 
	= prelude_data(str key, list[str] values, str)
	;
	
data PRELUDE
	= prelude(list[PRELUDEDATA] prelude)
	| empty(str)
	;

data PSGAME
 	= game(PRELUDE prelude, list[SECTION] sect)
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
	= object_data(list[str] id, str, list[str] colors, str, list[SPRITE] sprite)
	| object_empty(str)
	;
	
data SPRITE 
    =  sprite( 
       str, str,
       str, str,
       str, str, 
       str, str,
       str, str
      );
      
// issues with retaining separator to differentiate between a combined sprite and just an alias
data LEGEND
	= legend(str, str, str, list[LEGENDDATA])
	;

data LEGENDDATA
	= legend_data(str legend, list[str] values, str)
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
	= level_data(list[tuple[str, str]] level)
	| message(str message)
	;
