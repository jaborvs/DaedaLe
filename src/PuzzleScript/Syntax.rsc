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
lexical ID = @category="ID" [a-z0-9.A-Z#_+]+ !>> [a-z0-9.A-Z#_+] \ Keywords;
lexical Pixel = [a-zA-Z.!@#$%&*0-9\-,`\'~_\"§è!çàé;?:/+°£^{}|\>\<^v¬\[\]];
lexical LegendKey = Pixel+ !>> [a-zA-Z.!@#$%&*\-,`\'~_\"§è!çàé;?:/+°0-9£^{}|\>\<^v¬\[\]] \ Keywords;
lexical SpriteP = [0-9.];
lexical Levelline = Pixel+ !>> Pixel \ Keywords;
lexical String = ![\n]+ >> [\n];
lexical SoundIndex = [0-9]|'10' !>> [0-9]|'10';
lexical KeywordID = @category="Keyword" [a-z0-9.A-Z_]+ !>> [a-z0-9.A-Z_] \ 'message';
lexical IDOrDirectional = @category="ID" [\>\<^va-z0-9.A-Z#_+]+ !>> [\>\<^va-z0-9.A-Z#_+] \ Keywords;


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
	
syntax Color
	= @category="Color" ID
	;

syntax Colors
	= @category="Colors" Color+
	;

syntax ObjectData
	= @Foldable @category="Object" object_data: ID LegendKey? Newline Colors colors Newline Sprite?
	| object_empty: Newlines
	;
	
syntax SpritePixel
	= @category="SpritePixel" SpriteP
	;

syntax Sprite 
    =  @Foldable sprite: 
       SpritePixel+ Newline
       SpritePixel+ Newline
       SpritePixel+ Newline 
       SpritePixel+ Newline
       SpritePixel+ Newline
    ;

syntax Legend
	= legend: SectionDelimiter? 'LEGEND' Newlines SectionDelimiter? LegendData+
	;
	
syntax LegendOperation
	= legend_or: 'or' ID
	| legend_and: 'and' ID
	;

syntax LegendData
	= @category="Legend" legend_data: LegendKey '=' ID LegendOperation*  Newlines
	;

syntax Sounds
	= sounds: SectionDelimiter? 'SOUNDS' Newlines SectionDelimiter? (SoundData Newlines)+
	;
	
syntax SoundData
	= @category="Sound" sound_data: ID+
	;

syntax Layers
	= layers: SectionDelimiter? 'COLLISIONLAYERS' Newlines SectionDelimiter? LayerData+
	;

syntax LayerData
	= @category="Layer" layer_data: (ID ','?)+ Newlines
	;

syntax Rules
	= rules: SectionDelimiter? 'RULES' Newlines SectionDelimiter? (RuleData|Loop)+
	;
	
syntax Loop
	= @Foldable 'startloop' Newlines RuleData+ 'endloop' Newlines
	;
	
syntax RuleData
	= @category="Rule" rule_data: (Prefix|RulePart)+ '-\>' (Command|RulePart)* Message? Newlines
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
	= @category="Condition" @doc="All|Some|No Object On Object" condition_data: ID+ Newlines
	;

syntax Levels
	= levels: SectionDelimiter? 'LEVELS' Newlines SectionDelimiter? {LevelData Newlines}+ Newlines?
	;
	
syntax Message
	=	'message' String*
	;

syntax LevelData
	= @Foldable @category="Level" level_data_raw: (Levelline Newline)+
	| @category="Message" message: Message
	;
