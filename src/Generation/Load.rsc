/*
 * @Module: Load
 * @Desc:   Module that contains all the functionality to parse and load a 
 *          tutorial for its generation
 * @Auth:   Borja Velasco -> code
 */

module Generation::Load

/******************************************************************************/
// --- General modules imports -------------------------------------------------
import ParseTree;
import IO;

/******************************************************************************/
// --- Own modules imports -----------------------------------------------------
import Generation::Syntax;
import Generation::AST;

/******************************************************************************/
// --- Public load functions ---------------------------------------------------

/*
 * @Name:   load
 * @Desc:   Function that reads a papyrus file and loads its contents
 * @Param:  path -> Location of the file
 * @Ret:    PapyrusData object
 */
PapyrusData papyrus_load(loc path) {
    str src = readFile(path);
    return papyrus_load(src);    
}

/*
 * @Name:   load
 * @Desc:   Function that reads a papyrus file contents and implodes it
 * @Param:  src -> String with the contents of the file
 * @Ret:    PapyrusData object
 */
PapyrusData papyrus_load(str src) {
    start[PapyrusData] pd = papyrus_parse(src);
    PapyrusData ast = papyrus_implode(pd);
    ast = papyrus_process(ast);
    return ast;
}

/******************************************************************************/
// --- Public parsing functions ------------------------------------------------

/*
 * @Name:   papyrus_parse
 * @Desc:   Function that reads a papyrus file and parses it
 * @Param:  path -> Location of the file
 * @Ret:    
 */
start[PapyrusData] papyrus_parse(loc path) {
    str src = readFile(path);
    start[PapyrusData] pd = papyrus_parse(src);
    return pd;
}

/*
 * @Name:   papyrus_parse
 * @Desc:   Function that reads a papyrus file and parses it
 * @Param:  path -> Location of the file
 * @Ret:    
 */
start[PapyrusData] papyrus_parse(loc path) {
    str src = readFile(path);
    start[PapyrusData] td = papyrus_parse(src);
    return pd;
}

/*
 * @Name:   papyrus_parse
 * @Desc:   Function that reads a papyrus file and parses it
 * @Param:  path -> Location of the file
 * @Ret:    
 */
start[PapyrusData] papyrus_parse(str src) {
    return parse(#start[PapyrusData], src + "\n\n\n");
}

/*
 * @Name:   papyrus_implode
 * @Desc:   Function that takes a parse tree and builds the ast for a Papyrus
 *          tutorial
 * @Param:  tree -> Parse tree
 * @Ret:    PapyrusData object
 */
PapyrusData papyrus_implode(start[PapyrusData] parse_tree) {
    PapyrusData papyrus = implode(#PapyrusData, parse_tree);
    return papyrus;
}

/******************************************************************************/
// --- Public Processing Functions ---------------------------------------------

/*
 * @Name:   papyrus_process
 * @Desc:   Function that processes (cleans) the ast to be compiled
 * @Params: pprs -> default parsing ast
 * @Ret:    Cleaned ast
 */
PapyrusData papyrus_process(PapyrusData pprs) {
    list[ConfigurationData] unprocessed_configs = [];
    list[PatternData] unprocessed_patterns = [];
    list[ModuleData] unprocessed_modules = [];
    list[LevelDraftData] unprocessed_level_drafts = [];

    PapyrusData pprs_no_empty = visit(pprs) {
        case list[ConfigurationData] config => [c | c <- config, !(configuration_empty(_) := c)]
        case list[PatternData] patterns => [p | p <- patterns, !(pattern_empty(_) := p)]
        case list[ModuleData] modules => [m | m <- modules, !(module_empty(_) := m)]
        case list[LevelDraftData] level_drafts => [ld | ld <- level_drafts, !(level_draft_empty(_) := ld)]
        case list[SectionData] sections => [s | s <- sections, !(section_empty(_,_,_,_) := s)]
    };

    visit(pprs_no_empty) {
        case SectionData s:section_configurations_data(): unprocessed_configs += [s.configs];
        case SectionData s:section_patterns_data(): unprocessed_patterns += [s.patterns];
        case SectionData s:section_modules_data(): unprocessed_modules += [s.modules];
        case SectionData s:section_level_drafts_data(): unprocessed_level_drafts += [s.level_drafts];
    };

    PapyrusData pprs_processed = papyrus_data(
        unprocessed_configs,
        unprocessed_patterns,
        unprocessed_modules,
        unprocessed_level_drafts
    );

    return pprs_processed;
}