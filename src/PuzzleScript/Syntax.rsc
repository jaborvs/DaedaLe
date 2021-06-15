module PuzzleScript::Syntax

lexical LAYOUT = [\t\r\ =];
layout LAYOUTLIST = LAYOUT* !>> [\t\r\ =];

lexical Newline = [\n];
syntax Blankline = ^[\n];
lexical String = [a-z0-9.A-Z]+ !>> [a-z0-9.A-Z] \ Keywords;
// ID
lexical Pixel = [a-zA-Z.!@#$%&*0-9];
lexical Spriteline = [0-9.]+ !>> [0-9.] \ Keywords;
lexical Levelline = Pixel+ !>> Pixel \ Keywords;
lexical LegendPixel = Pixel >> '=';
lexical LegendString = String >> '=';
//lexical SectionDelimiter = [=]+ !>> [=];

keyword SectionHeader =  'RULES' | 'OBJECTS' | 'LEGEND' | 'COLLISIONLAYERS' | 'WINCONDITIONS' | 'LEVELS';
keyword PreludeKeyword = 'title' | 'author' | 'homepage';
keyword LegendOperation = 'or' | 'and';

keyword Keywords = SectionHeader | PreludeKeyword | LegendOperation;

start syntax PSGame
 	= game: Prelude? ObjectS? Legend? ;
 	
syntax Prelude
	= prelude: {PreludeData Newline}+
	;
	
syntax PreludeData
	= prelude_data: PreludeKeyword String*
	| prelude_empty:
	;

syntax Objects
	= objects: 'OBJECTS' Newline* {ObjectData Newline}*
	;

syntax ObjectData
	= object_data: String* Newline String* Newline {Spriteline Newline}*
	;

syntax Legend
	= legend: 'LEGEND' Newline* {LegendData Newline*}*
	;
	
syntax LegendData
	= legend_data:
	;
	
// ugly hack for "temporary" fix
syntax LegendData
	= legend_data: LegendPixel String 
	| legend_combined: LegendPixel String 'and' {String 'and'}+
	| legend_alias: LegendString String 'or' {String 'or'}+
	// | legend_empty: 
	;

// original code minus the "elegant" fix	
//syntax LegendData
//	= legend_data: Pixel '=' String
//	| combined: Pixel '=' {String 'and'}+
//	| aliases: String '=' {String 'or'}+
//	;


//ambiguious
syntax Sounds
	= sounds: 'SOUNDS' {SoundData Newline*}*
	;
	
syntax SoundData
	= sound_data: String+
	;

syntax Layers
	= empty:
	;

syntax LayerData
	= legend_data: {String ','}*
	;


syntax Rules
	= empty:
	;

lexical Rule = ![\n]*;

syntax RuleData
	= rule_data: Rule
	;

	
syntax WinConditions
	= empty:
	;

syntax ConditionData
	= condition_data: String*
	;

	
syntax Levels
	= empty:
	;

syntax LevelData
	= level_data: {Levelline Newline}*
	;