module PuzzleScript::Syntax

lexical LAYOUT 
	= [\t\r\ ]
	| ^ Comment Newlines
	> Comment //nested in code
	;
layout LAYOUTLIST = LAYOUT* !>> [\t\r\ )];

lexical SectionDelimiter = [=]+ Newlines;
lexical Newlines = Newline+ !>> [\n];
lexical Comment = @Category="Comment" "(" (![()]|Comment)+ ")";
lexical Newline = [\n];
lexical ID = @Category="ID" [a-z0-9.A-Z#_+]+ !>> [a-z0-9.A-Z#_+] \ Keywords;
lexical SpecialChars = [.!@#$%&*];
lexical Pixel = [a-zA-Z.!@#$%&*0-9\-,`\'~_\"§è!çàé;?:/+°£^{}|\>\<^v¬\[\]];
lexical LegendKey = Pixel+ !>> [a-zA-Z.!@#$%&*\-,`\'~_\"§è!çàé;?:/+°0-9£^{}|\>\<^v¬\[\]] \ Keywords;
lexical Spriteline = [0-9.]+ !>> [0-9.] \ Keywords;
lexical Levelline = Pixel+ !>> Pixel \ Keywords;
lexical String = ![\n]+ >> [\n];
lexical SoundIndex = [0-9]|'10' !>> [0-9]|'10';
lexical KeywordID = @Category="Key"[a-z0-9.A-Z_]+ !>> [a-z0-9.A-Z_] \ 'message';
lexical IDOrDirectional = @Category="ID" [\>\<^va-z0-9.A-Z#_+]+ !>> [\>\<^va-z0-9.A-Z#_+] \ Keywords;


keyword SectionKeyword =  'RULES' | 'OBJECTS' | 'LEGEND' | 'COLLISIONLAYERS' | 'SOUNDS' | 'WINCONDITIONS' | 'LEVELS';
keyword PreludeKeyword 
	= 'title' | 'author' | 'homepage' | 'color_palette' | 'again_interval' | 'background_color' 
	| 'debug' | 'flickscreen' | 'key_repeat_interval' | 'noaction' | 'norepeat_action' | 'noundo'
	| 'norestart' | 'realtime_interval' | 'require_player_movement' | 'run_rules_on_level_start' 
	| 'scanline' | 'text_color' | 'throttle_movement' | 'verbose_logging' | 'youtube ' | 'zoomscreen';

keyword LegendKeyword = 'or' | 'and';
keyword CommandKeyword = 'again' | 'cancel' | 'checkpoint' | 'restart' | 'win';

keyword Keywords = SectionKeyword | PreludeKeyword | LegendKeyword | CommandKeyword;

syntax Sound
	= sound: 'sfx' SoundIndex
	;

start syntax PSGame
 	= @Foldable game: Prelude? Section+
 	| empty: Newlines
 	;
 	
syntax Section
 	= @Foldable objects: Objects
 	| @Foldable legend: Legend
 	| @Foldable sounds: Sounds
 	| @Foldable layers: Layers
 	| @Foldable rules: Rules
 	| @Foldable conditions: WinConditions
 	| @Foldable levels: Levels
 	| empty: SectionDelimiter? SectionKeyword Newlines SectionDelimiter?
 	;
 	
syntax Prelude
	= prelude: PreludeData+
	| empty: Newlines
	;
	
syntax PreludeData
	= prelude_data: KeywordID String* Newlines
	;

syntax Objects
	= objects: SectionDelimiter? 'OBJECTS' Newlines SectionDelimiter? ObjectData+
	;

syntax ObjectData
	= @Foldable @Category="Object" object_data: ID LegendKey? Newline ID+ Newline Sprite?
	| object_empty: Newlines
	;

syntax Sprite 
    =  @Foldable sprite: 
       Spriteline Newline
       Spriteline Newline
       Spriteline Newline 
       Spriteline Newline
       Spriteline Newline
    ;

syntax Legend
	= legend: SectionDelimiter? 'LEGEND' Newlines SectionDelimiter? LegendData+
	;
	
syntax LegendOperation
	= legend_or: 'or' ID
	| legend_and: 'and' ID
	;

syntax LegendData
	= legend_data: LegendKey '=' ID LegendOperation*  Newlines
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
	= layer_data: (ID ','?)+ Newlines
	;

syntax Rules
	= rules: SectionDelimiter? 'RULES' Newlines SectionDelimiter? (RuleData|Loop)+
	;
	
syntax Loop
	= 'startloop' Newlines RuleData+ 'endloop' Newlines
	;
	
syntax RuleData
	= rule_data: (Prefix|RulePart)+ '-\>' (Command|RulePart)* Message? Newlines
	;

syntax RuleContent
	= content: IDOrDirectional*
	;
	
syntax RulePart
	= part: '[' {RuleContent '|'}+ ']'
	;

syntax Prefix
	= prefix: ID
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
	=	'message' String*
	;

syntax LevelData
	= @Foldable level_data_raw: (Levelline Newline)+
	| message: Message
	;
