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
    | papyrus_empty(str)
    ;

/******************************************************************************/
// --- Section structure defines -----------------------------------------------

/*
 * @Name:   SectionData
 * @Desc:   Data structure that models each of the sections of Papyrus
 */
data SectionData
    = section_configuration_data(str sep1, str name, str sep2, list[ConfigurationData] config)
    | section_pattern_data(str sep1, str name, str sep2, list[PatternData] patterns)
    | section_modules_data(str sep1, str name, str sep2, list[ModuleData] modules)
    | section_level_drafts_data(str sep1, str name, str sep2, list[LevelDraftData] level_drafts)
    | section_empty(str sep1, str name, str sep2, str)                          
    ;

/******************************************************************************/
// --- Configuration structure defines -----------------------------------------

/*
 * @Name:   ConfigurationData
 * @Desc:   Data structure that models each of the lines of the configuration
 *          section
 */
data ConfigurationData
    = configuration_data(str command, str params, str)  // Command keyword, parameters, separator (\n)
    | configuration_empty(str)                          // Empty line with only a separator (\n)
    ;

/******************************************************************************/
// --- Patterns structure defines ----------------------------------------------

/*
 * @Name:   PatternData
 * @Desc:   Data structure that models each of the patterns used for generation
 */
data PatternData
    = pattern_data(str name, str, TilemapData tilemap)          // Name, separator (\n), tilemap
    | pattern_empty(str)                                        // Empty line with only a separator (\n)
    ;

/*
 * @Name:   PatternData
 * @Desc:   Data structure that models a tilemap for patterns
 */
data TilemapData
    = tilemap_data(list[TilemapLineData] lines)                 // Tilemap lines
    ;

/*
 * @Name:   PatternData
 * @Desc:   Data structure that models a tilemap line for patterns
 */
data TilemapLineData
    = tilemap_line_data(list[str] objects, str)   // Tilemap line characters, separator (\)
    ;

/******************************************************************************/
// --- Module structure defines ------------------------------------------------

/*
 * @Name:   ModuleData
 * @Desc:   Data structure that models a module for generation
 */
data ModuleData
    = module_data(str name, str, list[RuleData] rules)  // Name, separator (\n), list of generation rules
    | module_empty(str)                                 // Empty line with only a separator (\n)
    ;

/*
 * @Name:   ModuleData
 * @Desc:   Data structure that models a rule for generation
 */
data RuleData
    = rule_data(str pattern1, str pattern2, str)        // Pattern 1, pattern 2, separator (\n)
    ;

/******************************************************************************/
// --- Level Draft structure defines -------------------------------------------

/*
 * @Name:   LevelDraftData
 * @Desc:   Data structure that models a high level representation of a level for
 *          generation
 */
data LevelDraftData
    = level_draft_data(str name, str, list[ChunkData] chunks)   // Name, separator (\n), list of chunks
    | level_draft_empty(str)                                    // Empty line with only a separator (\n)
    ;

/*
 * @Name:   ChunkData
 * @Desc:   Data structure that models a level's chunk
 */
data ChunkData
    = chunk_data(list[VerbData] verbs, str)                 // List of verbs to be used, separator (\n)
    ;

/*
 * @Name:   VerbData
 * @Desc:   Data structure that models a verb for generation
 */
data VerbData
    = verb_data(str name, str modifier)                     // Name, modifier
    ;
