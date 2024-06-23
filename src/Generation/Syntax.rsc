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
    = SectionKeyword | CommandKeyword | ModifierKeyword
    ;  

keyword SectionKeyword 
    = "configuration" | "patterns" | "modules" | "level drafts"
    ; 

keyword CommandKeyword
    = "chunk_size" | "objects_permanent"
    ;

keyword ModifierKeyword
    = "+" | "*" 
    ;

/******************************************************************************/
// --- Lexicals ----------------------------------------------------------------

lexical DELIMITER = [=]+;
lexical NEWLINE = [\n];
lexical COMMENT = @category="Comment" "(" (![()]|COMMENT)* ")";

lexical STRING = ![\n]+ >> [\n];
lexical INT = [0-9]+ val;
lexical ID = [a-z0-9A-Z_]+ !>> [a-z0-9A-Z_] \ Keywords;
lexical REP = [a-zA-Zぁ-㍿.!@#$%&0-9\-,`\'~_\"§è!çàé;?:/°£^{}|\>\<^v¬\[\]˅\\±←→↑↓]+ !>> [a-zA-Zぁ-㍿.!@#$%&0-9\-,`\'~_\"§è!çàé;?:/°£^{}|\>\<^v¬\[\]˅\\±←→↑↓] \ Keywords;

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
    = section_commands_data: SECTION_DELIMITER 'CONFIGURATION' NEWLINE SECTION_DELIMITER CommandData+
    | section_patterns_data: SECTION_DELIMITER 'PATTERNS' NEWLINE SECTION_DELIMITER PatternData+
    | section_modules_data: SECTION_DELIMITER 'MODULES' NEWLINE SECTION_DELIMITER ModuleData+
    | section_level_drafts_data: SECTION_DELIMITER 'LEVEL DRAFTS' NEWLINE SECTION_DELIMITER LevelDraftData+
    | section_empty: SECTION_DELIMITER SectionKeyword NEWLINE SECTION_DELIMITER
    ;

/******************************************************************************/
// --- Configuration Syntax ----------------------------------------------------

syntax CommandData
    = command_data: CommandKeyword '=' STRING NEWLINE
    | command_empty: NEWLINE
    ;

/******************************************************************************/
// --- Pattern Syntax ----------------------------------------------------------

syntax PatternData
    = pattern_data: ID NEWLINE TilemapData NEWLINE
    | pattern_empty: NEWLINE
    ;

syntax TilemapData
    = tilemap_data: TilemapRowData+
    ;

syntax TilemapRowData
    = tilemap_row_data: REP+ NEWLINE
    ;

/******************************************************************************/
// --- Module Syntax -----------------------------------------------------------

syntax ModuleData
    = module_data: ID NEWLINE RuleData+ NEWLINE
    | module_empty: NEWLINE
    ;

syntax RuleData
    = rule_data: '[' ID ']' '-\>' '[' ID ']' NEWLINE;

/******************************************************************************/
// --- Level Draft Syntax ------------------------------------------------------

syntax LevelDraftData
    = level_draft_data: ID NEWLINE ChunkData+ NEWLINE
    | level_draft_empty: NEWLINE
    ;

syntax ChunkData
    = chunk_data: '[' {VerbExpressionData ','}+ ']' NEWLINE
    ;

syntax VerbExpressionData
    = verb_expression_data: ID ModifierKeyword
    ;