module PuzzleScript::Syntax

lexical LAYOUT 
	= [\t\r\ ]
	| @category="Comment" [(]![)]+[)]
	;
layout LAYOUTLIST = LAYOUT* !>> [\t\r\ ];

lexical Newline = [\n];
lexical Newlines = Newline+ !>> [\n];
lexical ID = [a-z0-9.A-Z]+ !>> [a-z0-9.A-Z] \ Keywords;
lexical SpecialChars = [.!@#$%&*];
lexical Pixel = [a-zA-Z.!@#$%&*0-9];
lexical LegendKey = [a-zA-Z.!@#$%&*0-9]+ !>> [a-zA-Z.!@#$%&*0-9] \ Keywords;
lexical Spriteline = [0-9.]+ !>> [0-9.] \ Keywords;
lexical Rule = ![\n=]+ >> [\n] \ Keywords;
lexical Levelline = Pixel+ !>> Pixel \ Keywords;
lexical SectionDelimiter = [=]+ Newlines;

keyword SectionKeyword =  'RULES' | 'OBJECTS' | 'LEGEND' | 'COLLISIONLAYERS' | 'WINCONDITIONS' | 'LEVELS';
keyword PreludeKeyword = 'title' | 'author' | 'homepage';
keyword LegendOperation = 'or' | 'and';

keyword Keywords = SectionKeyword | PreludeKeyword | LegendOperation;

start syntax PSGame
 	= game: Prelude Section+
 	;
 	
syntax Section
 	= objects: Objects
 	| legend: Legend
 	| sounds: Sounds
 	| layers: Layers
 	| rules: Rules
 	| conditions: WinConditions
 	| levels: Levels
 	;
 	
syntax Prelude
	= prelude: (PreludeData Newlines)+
	;
	
syntax PreludeData
	= prelude_data: PreludeKeyword ID+
	| prelude_empty: Newlines
	;

syntax Objects
	= objects: SectionDelimiter? 'OBJECTS' Newlines SectionDelimiter? ObjectData+
	;
	
syntax Sprite 
    =  Spriteline Newline
       Spriteline Newline
       Spriteline Newline 
       Spriteline Newline
       Spriteline Newline
    ;

syntax ObjectData
	= object_data: ID+ Newline ID+ Newline Sprite
	| object_empty: Newlines
	;

syntax Legend
	= legend: SectionDelimiter? 'LEGEND' Newlines SectionDelimiter? LegendData+
	;

syntax LegendData
	= legend_data: LegendKey '=' {ID LegendOperation}+ Newlines
	;

syntax Sounds
	= sounds: SectionDelimiter? 'SOUNDS' Newlines SectionDelimiter? (SoundData Newlines)+
	;
	
syntax SoundData
	= sound_data: ID+
	;

syntax Layers
	= layers: SectionDelimiter? 'COLLISIONLAYERS' Newlines SectionDelimiter? LayerData+
	;

syntax LayerData
	= layer_data: {ID ','}+ Newlines
	| layer_empty: Newlines
	;

syntax Rules
	= rules: SectionDelimiter? 'RULES' Newlines SectionDelimiter? RuleData+
	;

syntax RuleData
	= rule_data: Rule Newlines
	;
	
syntax WinConditions
	= conditions: SectionDelimiter? 'WINCONDITIONS' Newlines SectionDelimiter? ConditionData+
	;

syntax ConditionData
	= condition_data: ID+ Newlines
	| condition_empty: Newlines
	;

syntax Levels
	= levels: SectionDelimiter? 'LEVELS' Newlines SectionDelimiter? {LevelData Newlines}+
	;
	
syntax Message
	=	'message' ID*
	;

syntax LevelData
	= level_data: (Levelline Newline)+
	| message: Message
	;