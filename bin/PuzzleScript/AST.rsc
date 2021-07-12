module PuzzleScript::AST

data PRELUDEDATA 
	= prelude_data(str key, list[str] values, str)
	;
	
data PRELUDE
	= prelude(list[PRELUDEDATA] prelude)
	| empty(str)
	;

data PSGAME
 	= game(PRELUDE pr, list[SECTION] sect)
 	| empty(str)
 	;
 	
data SECTION
 	= objects(OBJECTS objects)
 	//| legend(LEGEND legend) // issues with retaining separator to differentiate between a combined sprite and just an alias
 	| sounds(SOUNDS sounds)
 	| layers(LAYERS layers)
 	//| rules(RULES rules)
 	| conditions(WINCONDITIONS conditions)
 	| levels(LEVELS levels)
 	| empty(str, str)
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
	
//data RULES
//	= rules(str, str, str, list[RULEDATA] rules)
//	;
//	
//data RULEDATA
//	= rule_data(list[str] prefix, list[RulePart] rules_right, list[RulePart, str], str)
//	;
//	
//data RULE

data WINCONDITIONS
	= conditions(str, str, str, list[CONDITIONDATA] conditions)
	;

data CONDITIONDATA
	= condition_data(list[str] condition, str)
	;
	
data LEVELS
	= levels(str, str, str, list[LEVELDATA] levels)
	;
	
data LEVELDATA
	= level_data(list[tuple[str, str]] level)
	| message(str message)
	;
