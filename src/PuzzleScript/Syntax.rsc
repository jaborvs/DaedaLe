module PuzzleScript::Syntax

lexical LAYOUT = [\t\r\ ];
layout LAYOUTLIST = LAYOUT* !>> [\t\r\ ];

lexical Newline = [\n];
lexical Newlines = Newline* !>> [\n];
lexical ID = [a-z0-9.A-Z]+ !>> [a-z0-9.A-Z] \ Keywords;
lexical SpecialChars = [.!@#$%&*];
lexical Pixel = [a-zA-Z.!@#$%&*0-9];
lexical LegendKey = [a-zA-Z.!@#$%&*0-9]+ !>> [a-zA-Z.!@#$%&*0-9];
lexical Spriteline = [0-9.]+ !>> [0-9.] \ Keywords;
lexical Levelline = Pixel+ !>> Pixel \ Keywords;

keyword SectionHeader =  'RULES' | 'OBJECTS' | 'LEGEND' | 'COLLISIONLAYERS' | 'WINCONDITIONS' | 'LEVELS';
keyword PreludeKeyword = 'title' | 'author' | 'homepage';
keyword LegendOperation = 'or' | 'and';

keyword Keywords = SectionHeader | PreludeKeyword | LegendOperation;

start syntax PSGame
 	= game:
 	;
 	
syntax Prelude
	= prelude: (PreludeData Newlines)*
	;
	
syntax PreludeData
	= prelude_data: PreludeKeyword ID*
	;

syntax Objects
	= objects: ObjectData*
	;
	
syntax Sprite 
    =  Spriteline Newline
       Spriteline Newline
       Spriteline Newline 
       Spriteline Newline
       Spriteline Newlines
    ;

syntax ObjectData
	= object_data: ID* Newline ID* Newline Sprite
	;

syntax Legend
	= legend: LegendData*
	;

syntax LegendData
	= legend_data: LegendKey '=' {ID LegendOperation}* Newlines
	;

// ambiguity
syntax Sounds
	= sounds: SoundData*
	;
	
syntax SoundData
	= sound_data: ID*
	;

syntax Layers
	= layers: LayerData*
	;

syntax LayerData
	= layer_data: {ID ','}* Newlines
	;

//not working
syntax Rules
	= rules: Rule*
	;

lexical Rule = ![\n]* >> [\n];

syntax RuleData
	= rule_data: Rule Newlines
	;
	
syntax WinConditions
	= conditions: ConditionData*
	;

syntax ConditionData
	= condition_data: ID* Newlines
	;

syntax Levels
	= levels: LevelData* 
	;

syntax LevelData
	= level_data: {Levelline Newline}* Newlines
	;