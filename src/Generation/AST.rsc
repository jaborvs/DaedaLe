/*
 * @Module: AST
 * @Desc:   Module that defines the structures to parse the AST of Papyrus
 * @Author: Borja Velasco -> code, comments
 */
module Generation::AST

/******************************************************************************/
// --- Tutorial structure defines ----------------------------------------------

/*
 * @Name:   PapyrusData
 * @Desc:   Data structure that stores a parsed Tutorial for its generation
 */
data PapyrusData 
    = papyrus_data(list[SectionData] sections)
    | papyrus_data(list[CommandData] commands, list[PatternData] patterns, list[ModuleData] modules, list[LevelDraftData] level_drafts)
    | papyrus_empty(str)
    ;

/******************************************************************************/
// --- Section structure defines -----------------------------------------------

/*
 * @Name:   SectionData
 * @Desc:   Data structure that models each of the sections of Papyrus
 */
data SectionData
    = section_commands_data(str sep1, str name, str sep2, list[CommandData] commands)
    | section_patterns_data(str sep1, str name, str sep2, list[PatternData] patterns)
    | section_modules_data(str sep1, str name, str sep2, list[ModuleData] modules)
    | section_level_drafts_data(str sep1, str name, str sep2, list[LevelDraftData] level_drafts)
    | section_empty(str sep1, str name, str sep2, str)                          
    ;

/******************************************************************************/
// --- Configuration structure defines -----------------------------------------

/*
 * @Name:   CommandData
 * @Desc:   Data structure that models each of the lines of the configuration
 *          section
 */
data CommandData
    = command_data(str name, str params, str)   // Command keyword, parameters, separator (\n)
    | command_empty(str)                        // Empty line with only a separator (\n)
    ;

/******************************************************************************/
// --- Patterns structure defines ----------------------------------------------

/*
 * @Name:   PatternData
 * @Desc:   Data structure that models each of the patterns used for generation
 */
data PatternData
    = pattern_data(str name, str, TilemapData tilemap, str)     // Name, separator (\n), tilemap, separator(\n)
    | pattern_empty(str)                                        // Empty line with only a separator (\n)
    ;

/*
 * @Name:   PatternData
 * @Desc:   Data structure that models a tilemap for patterns
 */
data TilemapData
    = tilemap_data(list[TilemapRowData] row_dts)                 // Tilemap lines
    ;

/*
 * @Name:   TilemapRowData
 * @Desc:   Data structure that models a tilemap row for patterns
 */
data TilemapRowData
    = tilemap_row_data(list[str] objects, str)                  // Tilemap line characters, separator (\)
    ;

/******************************************************************************/
// --- Module structure defines ------------------------------------------------

/*
 * @Name:   ModuleData
 * @Desc:   Data structure that models a module for generation
 */
data ModuleData
    = module_data(str name, str, list[RuleData] rule_dts, str)  // Name, separator (\n), list of generation rules, separator (\n)
    | module_empty(str)                                         // Empty line with only a separator (\n)
    ;

/*
 * @Name:   ModuleData
 * @Desc:   Data structure that models a rule for generation
 */
data RuleData
    = rule_data(str left, str right, str, loc src = |unkown:///|, map[int,list[str]] comments = ()) // Pattern 1, pattern 2, separator (\n)
    ;

/******************************************************************************/
// --- Level Draft structure defines -------------------------------------------

/*
 * @Name:   LevelDraftData
 * @Desc:   Data structure that models a high level representation of a level for
 *          generation
 */
data LevelDraftData
    = level_draft_data(str name, str, list[ChunkData] chunk_dts, str)   // Name, separator (\n), list of chunks, separator (\n)
    | level_draft_empty(str)                                            // Empty line with only a separator (\n)
    ;

/*
 * @Name:   ChunkData
 * @Desc:   Data structure that models a level's chunk
 */
data ChunkData
    = chunk_data(
        WinPlaytraceData win_pt, 
        list[ChallengePlaytraceData] challenge_pt, 
        str, 
        loc src = |unknown:///|, 
        map[int,list[str]] comments = ()
        )   // List of verbs to be used, separator (\n)
    ;

/*
 * @Name:   WinPlaytraceData
 * @Desc:   Data structure that models a winning playtrace
 */
data WinPlaytraceData
    = win_playtrace_data(list[VerbExpressionData] verb_dts)
    ;

/*
 * @Name:   ChallengePlaytraceData
 * @Desc:   Data structure that models a challengeure playtrace
 */
data ChallengePlaytraceData
    = challenge_playtrace_data(list[VerbExpressionData] verb_dts)
    ;

/*
 * @Name:   VerbExpressionData
 * @Desc:   Data structure that models a verb for generation
 */
data VerbExpressionData
    = verb_expression_data(str name, list[ArgumentData] args, str modifier)                     // Name, modifier
    ;

/*
 * @Name:   ArgumentDat
 * @Desc:   Data structure that models an argument of a verb
 */
data ArgumentData
    = argument_data(str arg)
    ;
