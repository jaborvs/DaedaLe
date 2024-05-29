module PuzzleScript::Syntax

layout LAYOUTLIST = LAYOUT* !>> [\t\ \r(];
lexical LAYOUT
  = [\t\ \r]
  | Comment;

lexical Comment = @lineComment @category="Comment" "(" (![()]|Comment)* ")";
lexical Delimiter = [=]+;
lexical Newline = [\n];

lexical ID = [a-z0-9.A-Z#_+]+ !>> [a-z0-9.A-Z#_+] \ Keywords;
lexical String = @category="String" ![\n]+ >> [\n];

lexical SpritePixel = [0-9.];
lexical Pixel = [a-zA-Zぁ-㍿.!@#$%&*0-9\-,`\'~_\"§è!çàé;?:/+°£^{}|\>\<^v¬\[\]˅\\±];
lexical LegendKey = @category="LegendKey" Pixel+ !>> Pixel \ Keywords;
lexical LevelPixel = @category="LevelPixel" Pixel;
lexical LevelLine = LevelPixel+ !>> LevelPixel \ Keywords;

lexical SoundIndex = [0-9]|'10' !>> [0-9]|'10';
lexical IDOrDirectional = @category="IDorDirectional" [\>\<^va-z0-9.A-Z#_+]+ !>> [\>\<^va-z0-9.A-Z#_+] \ Keywords;

/******************************************************************************/
// --- Reserved Keywords -------------------------------------------------------
// (NOTE: We have omitted the SoundKeywords, since we are being more lenient for
//        accepting sounds)

keyword Keywords 
    = SectionKeyword | PreludeKeyword | LegendKeyword | CommandKeyword
    ;
keyword SectionKeyword 
    =  'RULES' | 'OBJECTS' | 'LEGEND' | 'COLLISIONLAYERS' | 'SOUNDS' 
    | 'WINCONDITIONS' | 'LEVELS'
    ;
keyword PreludeKeyword 
    = 'title' | 'author' | 'homepage' | 'color_palette' | 'again_interval' 
    | 'background_color' | 'debug' | 'flickscreen' | 'key_repeat_interval' 
    | 'noaction' | 'norepeat_action' | 'noundo' | 'norestart' | 'realtime_interval' 
    | 'require_player_movement' | 'run_rules_on_level_start' | 'scanline' 
    | 'text_color' | 'throttle_movement' | 'verbose_logging' | 'youtube ' 
    | 'zoomscreen'
    ;
keyword LegendKeyword 
    = 'or' | 'and'
    ;
keyword CommandKeyword 
    = 'again' | 'cancel' | 'checkpoint' | 'restart' | 'win'
    ;

/******************************************************************************/
// --- Game syntax -------------------------------------------------------------

start syntax PSGame
    = game_data: Prelude? Section+
    | game_empty: Newlines
    ;

syntax Newlines = Newline+ !>> [\n];
syntax SectionDelimiter = Delimiter Newline;

/******************************************************************************/
// --- Prelude syntax ----------------------------------------------------------

syntax Prelude
    = prelude: PreludeData+
    ;
    
syntax PreludeData
    = prelude_data: PreludeKeyword String* Newline
    | prelude_empty: Newline
    ;

/******************************************************************************/
// --- Sections syntax ---------------------------------------------------------

syntax Section
    = section_objects: SectionDelimiter? 'OBJECTS' Newlines SectionDelimiter? ObjectData+ objects
    | section_legend: SectionDelimiter? 'LEGEND' Newlines SectionDelimiter? LegendData+ legend
    | section_sounds: SectionDelimiter? 'SOUNDS' Newlines SectionDelimiter? SoundData+ sounds
    | section_layers: SectionDelimiter? 'COLLISIONLAYERS' Newlines SectionDelimiter? LayerData+ layers
    | section_rules: SectionDelimiter? 'RULES' Newlines SectionDelimiter? RuleData+ rules
    | section_conditions: SectionDelimiter? 'WINCONDITIONS' Newlines SectionDelimiter? ConditionData+ conditions
    | section_levels: SectionDelimiter? 'LEVELS' Newlines SectionDelimiter? LevelData+ levels
    | section_empty: SectionDelimiter? SectionKeyword Newlines SectionDelimiter?
    ;

/******************************************************************************/
// --- Objects syntax ----------------------------------------------------------

syntax ObjectData
    = object_data: ObjectName Newline Color+ Newline Sprite?
    | object_empty: Newline
    ;

syntax ObjectName
    = @category="ObjectName" ID;

syntax Color
    = @category="Color" ID;

syntax Sprite 
    = sprite: 
        SpritePixel+ Newline
        SpritePixel+ Newline
        SpritePixel+ Newline 
        SpritePixel+ Newline
        SpritePixel+ Newline
    ;

/******************************************************************************/
// --- Legends syntax ----------------------------------------------------------  

syntax LegendData
    = legend_data: LegendKey '=' ObjectName LegendOperation*  Newline
    | legend_empty: Newline
    ; 
    
syntax LegendOperation
    = legend_or: 'or' ObjectName
    | legend_and: 'and' ObjectName
    ;

/******************************************************************************/
// --- Sound syntax ------------------------------------------------------------

syntax SoundData
    = sound_data: SoundItem+ Newline
    | sound_empty: Newline
    ;

syntax SoundItem
    = @category="SoundItem" ID
    ;

/******************************************************************************/
// --- Layer syntax ------------------------------------------------------------ 

syntax LayerData
    = layer_data: (ObjectName ','?)+ Newline
    | layer_empty: Newline
    ;
    
/******************************************************************************/
// --- Rule syntax ------------------------------------------------------------- 

syntax RuleData
  = rule_data: (Prefix|RulePart)+ '-\>' (Command|RulePart)* Message? Newline
  | rule_loop: 'startloop' RuleData+ 'endloop' Newline
  | rule_empty: Newline
  ;

syntax RuleContent
  = content: IDOrDirectional*;
    
syntax RulePart
  = part: '[' {RuleContent '|'}+ ']';

syntax Prefix
  = @category="Keyword" prefix: ID;

syntax Command
  = @category="Keyword" command: CommandKeyword
  | @category="Keyword" sound: 'sfx' SoundIndex;
    
/******************************************************************************/
// --- Condition syntax --------------------------------------------------------

syntax ConditionData
  = condition_data: ConditionItem+ Newline
  | condition_empty: Newline;

syntax ConditionItem
  = @category="ConditonID" ID;

/******************************************************************************/
// --- Condition syntax --------------------------------------------------------

syntax LevelData
    = level_data: (LevelLine Newline)+ Newline
    | level_message: 'message' String*
    | level_empty: Newline;