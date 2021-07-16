module PuzzleScript::Syntax

lexical LAYOUT 
	= [\t\r\ ]
	| ^ Comment Newlines
	> Comment //nested in code
	;
layout LAYOUTLIST = LAYOUT* !>> [\t\r\ )];

lexical SectionDelimiter = [=]+ Newlines;
lexical Newlines = Newline+ !>> [\n];
lexical Comment = @category="Comment" "(" (![()]|Comment)+ ")";
lexical Newline = [\n];
lexical ID = [a-z0-9.A-Z]+ !>> [a-z0-9.A-Z] \ Keywords;
lexical SpecialChars = [.!@#$%&*];
lexical Pixel = [a-zA-Z.!@#$%&*0-9];
lexical LegendKey = [a-zA-Z.!@#$%&*0-9]+ !>> [a-zA-Z.!@#$%&*0-9] \ Keywords;
lexical Spriteline = [0-9.]+ !>> [0-9.] \ Keywords;
lexical Levelline = Pixel+ !>> Pixel \ Keywords;
lexical String = ![\n]+ >> [\n];
lexical SoundIndex = [0-9]|'10';
lexical Directional = [\>\<^v] !>> [a-z0-9.A-Z];

keyword SectionKeyword =  'RULES' | 'OBJECTS' | 'LEGEND' | 'COLLISIONLAYERS' | 'SOUNDS' | 'WINCONDITIONS' | 'LEVELS';
keyword PreludeKeyword 
	= 'title' | 'author' | 'homepage' | 'color_palette' | 'again_interval' | 'background_color' 
	| 'debug' | 'flickscreen' | 'key_repeat_interval' | 'noaction' | 'norepeat_action' | 'noundo'
	| 'norestart' | 'realtime_interval' | 'require_player_movement' | 'run_rules_on_level_start' 
	| 'scanline' | 'text_color' | 'throttle_movement' | 'verbose_logging' | 'youtube ' | 'zoomscreen';

keyword LegendOperation = 'or' | 'and';
keyword CommandKeyword = 'again' | 'cancel' | 'checkpoint' | 'restart' | 'win';

keyword Keywords = SectionKeyword | PreludeKeyword | LegendOperation | CommandKeyword;

syntax Sound
	= sound: 'sfx' SoundIndex
	;

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

syntax ObjectData
	= object_data: ID+ Newline ID+ Newline Sprite?
	| object_empty: Newlines
	;

syntax Sprite 
    =  sprite: 
       Spriteline Newline
       Spriteline Newline
       Spriteline Newline 
       Spriteline Newline
       Spriteline Newline
    ;

syntax Legend
	= legend: SectionDelimiter? 'LEGEND' Newlines SectionDelimiter? LegendData+
	;

syntax LegendData
	= legend_data: LegendKey '=' {ID LegendOperation}+ Newlines
	;

// ideal solution, doesn't currently work because of ambiguity issues	
//syntax LegendData
//	= legend_data_or: LegendKey '=' {ID 'or'}+ Newlines
//	> legend_data_and: LegendKey '=' {ID 'and'}+ Newlines
//	;

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
	
syntax RuleData
	= rule_data: ID* RulePart+ '-\>' (Command|RulePart)+ Message? Newlines
	;

syntax RuleContent
	= content: (ID|Directional)*
	;
	
syntax RulePart
	= part: '[' {RuleContent '|'}+ ']'
	;

syntax Command
	= command: CommandKeyword
	| sound: Sound
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