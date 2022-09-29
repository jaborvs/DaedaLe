module PuzzleScript::Syntax

lexical LAYOUT 
	= [\t\r\ ]
	| ^ Comment Newlines
	> Comment //nested in code
	;
	
layout LAYOUTLIST = LAYOUT* !>> [\t\r\ )];

lexical SectionDelimiter = [=]+ Newlines;
lexical Newlines = Newline+ !>> [\n];
lexical Comment = @lineComment @category="Comment" "(" (![()]|Comment)* ")";
lexical Newline = [\n];
lexical ID = [a-z0-9.A-Z#_+]+ !>> [a-z0-9.A-Z#_+] \ Keywords;
lexical Pixel = [a-zA-Zぁ-㍿.!@#$%&*0-9\-,`\'~_\"§è!çàé;?:/+°£^{}|\>\<^v¬\[\]˅\\±]; //rozen: added Japonse and several other characers
lexical LegendKey = @category="LegendKey" Pixel+ !>> Pixel \ Keywords;
lexical SpriteP = [0-9.];
lexical LevelPixel = @category="LevelPixel" Pixel;
lexical Levelline = LevelPixel+ !>> LevelPixel \ Keywords;
lexical String = @category="String" ![\n]+ >> [\n];
lexical SoundIndex = [0-9]|'10' !>> [0-9]|'10';
lexical KeywordID = @category="ID" [a-z0-9.A-Z_]+ !>> [a-z0-9.A-Z_] \ 'message';
lexical IDOrDirectional = @category="IDorDirectional" [\>\<^va-z0-9.A-Z#_+]+ !>> [\>\<^va-z0-9.A-Z#_+] \ Keywords;

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
	= Color+
	;
	
syntax ObjectName
	= @category="ObjectName" ID
	;

syntax ObjectData
	= @Foldable object_data: ObjectName LegendKey? Newline Colors Newline Sprite?
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
	= legend_or: 'or' ObjectName
	| legend_and: 'and' ObjectName
	;

syntax LegendData
	= legend_data: LegendKey '=' ObjectName LegendOperation*  Newlines
	;

syntax Sounds
	= sounds: SectionDelimiter? 'SOUNDS' Newlines SectionDelimiter? (SoundData Newlines)+
	;
	
syntax SoundID
	= @category="SoundID" ID
	;
	
syntax SoundData
	= sound_data: SoundID+
	;

syntax Layers
	= layers: SectionDelimiter? 'COLLISIONLAYERS' Newlines SectionDelimiter? LayerData+
	;

syntax LayerData
	= layer_data: (ObjectName ','?)+ Newlines
	;

syntax Rules
	= rules: SectionDelimiter? 'RULES' Newlines SectionDelimiter? RuleData+
	;
	
syntax RuleData
	= rule_data: (Prefix|RulePart)+ '-\>' (Command|RulePart)* Message? Newlines
	| @Foldable loop: 'startloop' Newlines RuleData+ 'endloop' Newlines	
	;

syntax RuleContent
	= content: IDOrDirectional*
	;
	
syntax RulePart
	= part: '[' {RuleContent '|'}+ ']'
	;

syntax Prefix
	= @category="Keyword" prefix: ID
	;

syntax Command
	= @category="Keyword" command: CommandKeyword
	| @category="Keyword" sound: Sound
	;

syntax WinConditions
	= conditions: SectionDelimiter? 'WINCONDITIONS' Newlines SectionDelimiter? ConditionData+
	;
	
syntax ConditionID
	= @category="ConditonID" ID
	;

syntax ConditionData
	= condition_data: ConditionID+ Newlines
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
