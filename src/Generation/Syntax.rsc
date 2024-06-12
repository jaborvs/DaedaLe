/*
 * @Module: Syntax
 * @Desc:   Module that defined the syntax of Papyrus, a DSL to enable tutorial 
 *          generation for PuzzleScript. We tried to stay as loyal to PuzzleScript's
 *          original syntax as possible
 * @Author: Borja Velasco -> code, comments
 */
module Generation::Syntax

/******************************************************************************/
// --- Layout ------------------------------------------------------------------

layout LAYOUTLIST = LAYOUT* !>> [\t\ \r(];
lexical LAYOUT
    = [\t\ \r]
    | COMMENT
    ;

/******************************************************************************/
// --- Keywords ----------------------------------------------------------------

keyword Keywords 
    = SectionKeyword | ConfigurationKeyword | ModifierKeyword
    ;  

keyword SectionKeyword 
    = "configuration" | "patterns" | "modules" | "level drafts"
    ; 

keyword ConfigurationKeyword
    = "chunk_size"
    ;

keyword ModifierKeyword
    = "+" | "*" 
    ;

/******************************************************************************/
// --- Lexicals ----------------------------------------------------------------

lexical DELIMITER = [=]+;
lexical NEWLINE = [\n];
lexical COMMENT = "(" (![()]|COMMENT)* ")";

lexical STRING = ![\n]+ >> [\n];
lexical INT = [0-9]+ val;
lexical ID = [a-z0-9.A-Z_]+ !>> [a-z0-9.A-Z_] \ Keywords;
lexical PIXEL = [a-zA-Zぁ-㍿.!@#$%&*0-9\-,`\'~_\"§è!çàé;?:/+°£^{}|\>\<^v¬\[\]˅\\±←→↑↓];

/******************************************************************************/
// --- Syntax ------------------------------------------------------------------

start syntax PapyrusData
    = papyrus_data: SectionData+
    | papyrus_empty: NEWLINES
    ;

syntax NEWLINES = NEWLINE+ !>> [\n];
syntax SECTION_DELIMITER = DELIMITER NEWLINE;

/******************************************************************************/
// --- Section Syntax ----------------------------------------------------------

syntax SectionData
    = section_configuration_data: SECTION_DELIMITER 'CONFIGURATION' NEWLINE SECTION_DELIMITER ConfigurationData+
    | section_pattern_data: SECTION_DELIMITER 'PATTERNS' NEWLINE SECTION_DELIMITER PatternData+
    | section_modules_data: SECTION_DELIMITER 'MODULES' NEWLINE SECTION_DELIMITER ModuleData+
    | section_level_drafts_data: SECTION_DELIMITER 'LEVEL DRAFTS' NEWLINE SECTION_DELIMITER LevelDraftData+
    | section_empty: SECTION_DELIMITER SectionKeyword NEWLINE SECTION_DELIMITER
    ;

/******************************************************************************/
// --- Configuration Syntax ----------------------------------------------------

syntax ConfigurationData
    = configuration_data: ConfigurationKeyword STRING? NEWLINE
    | configuration_empty: NEWLINE
    ;

/******************************************************************************/
// --- Pattern Syntax ----------------------------------------------------------

syntax PatternData
    = pattern_data: ID NEWLINE TilemapData
    | pattern_empty: NEWLINE
    ;

syntax TilemapData
    = tilemap_data: TilemapLineData+
    ;

syntax TilemapLineData
    = tilemap_line_data: PIXEL+ NEWLINE
    ;

/******************************************************************************/
// --- Module Syntax -----------------------------------------------------------

syntax ModuleData
    = module_data: ID NEWLINE RuleData+
    | module_empty: NEWLINE
    ;

syntax RuleData
    = rule_data: '[' ID ']' '-\>' '[' ID ']' NEWLINE;

/******************************************************************************/
// --- Level Draft Syntax ------------------------------------------------------

syntax LevelDraftData
    = level_draft_data: ID NEWLINE ChunkData+
    | level_draft_empty: NEWLINE
    ;

syntax ChunkData
    = chunk_data: '[' {VerbData ','}+ ']' NEWLINE
    ;

syntax VerbData
    = verb_data: ID ModifierKeyword
    ;