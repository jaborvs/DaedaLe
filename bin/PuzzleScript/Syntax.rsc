module PuzzleScript::Syntax

lexical LAYOUT 
	= [\t\r\ ]
	| @category="Comment" ^ Comment Newlines
	> @category="Comment" Comment //nested in code
	;
layout LAYOUTLIST = LAYOUT* !>> [\t\r\ )];


lexical Comment = @category="Comment" "(" (![()]|Comment)+ ")";
lexical Newline = [\n];
lexical Newlines = Newline+ !>> [\n];
lexical ID = @category="ID" id: [a-z0-9.A-Z]+ !>> [a-z0-9.A-Z] \ Keywords;
lexical SpecialChars = [.!@#$%&*];
lexical Pixel = [a-zA-Z.!@#$%&*0-9];
lexical LegendKey = [a-zA-Z.!@#$%&*0-9]+ !>> [a-zA-Z.!@#$%&*0-9] \ Keywords;
lexical Spriteline = [0-9.]+ !>> [0-9.] \ Keywords;
lexical Levelline = Pixel+ !>> Pixel \ Keywords;
lexical SectionDelimiter = [=]+ Newlines;
lexical String = ![\n]+ >> [\n];

keyword SectionKeyword =  'RULES' | 'OBJECTS' | 'LEGEND' | 'COLLISIONLAYERS' | 'SOUNDS' | 'WINCONDITIONS' | 'LEVELS';
keyword PreludeKeyword 
	= key: 'title' | 'author' | 'homepage' | 'color_palette' | 'again_interval' | 'background_color' 
	| 'debug' | 'flickscreen' | 'key_repeat_interval' | 'noaction' | 'norepeat_action' | 'noundo'
	| 'norestart' | 'realtime_interval' | 'require_player_movement' | 'run_rules_on_level_start' 
	| 'scanline' | 'text_color' | 'throttle_movement' | 'verbose_logging' | 'youtube ' | 'zoomscreen';
keyword LegendOperation = 'or' | 'and';

keyword Directional = 'up' | 'down' | 'right' | 'left' ;
keyword Moving = 'moving';
keyword Orientiation = 'vertical' | 'horizontal';
keyword No = 'no';

keyword Keywords = SectionKeyword | PreludeKeyword | LegendOperation;

start syntax PSGame
 	= game: Prelude Section+
 	| empty: Newlines
 	;
 	
syntax Section
 	= objects: Objects
 	| legend: Legend
 	| sounds: Sounds
 	| layers: Layers
 	| rules: Rules
 	| conditions: WinConditions
 	| levels: Levels
 	| empty: SectionDelimiter? SectionKeyword Newlines SectionDelimiter?
 	;
 	
syntax Prelude
	= prelude: PreludeData+
	| empty: Newlines
	;
	
syntax PreludeData
	= prelude_data: PreludeKeyword String* Newlines
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
	= object_data: ID+ Newline ID+ Newline Sprite?
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
	;

syntax Rules
	= rules: SectionDelimiter? 'RULES' Newlines SectionDelimiter? RuleData+
	;

lexical RuleContent 
	= content: ![\]|]+ >> [\]|] \ Keywords
	| empty: 
	;

syntax RulePart
	= part: '[' {RuleContent '|'}+ ']'
	;
	
syntax Prefix
	= prefix: ID*
	;

syntax Command
	= command: ID+
	;

syntax RuleData
	= rule_data: Prefix RulePart+ '-\>' (RulePart|Command)+ Newlines
	;

syntax WinConditions
	= conditions: SectionDelimiter? 'WINCONDITIONS' Newlines SectionDelimiter? ConditionData+
	;

syntax ConditionData
	= condition_data: ID+ Newlines
	;

syntax Levels
	= levels: SectionDelimiter? 'LEVELS' Newlines SectionDelimiter? {LevelData Newlines}+ Newlines?
	;
	
syntax Message
	=	'message' String+
	;

syntax LevelData
	= level_data: (Levelline Newline)+
	| message: Message
	;