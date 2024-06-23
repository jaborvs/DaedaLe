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
import String;
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
    list[CommandData] processed_commands = [];
    list[PatternData] processed_patterns = [];
    list[ModuleData] processed_modules = [];
    list[LevelDraftData] processed_level_drafts = [];

    pprs = visit(pprs) {
        case list[CommandData] commands => [c | c <- commands, !(command_empty(_) := c)]
        case list[PatternData] patterns => [p | p <- patterns, !(pattern_empty(_) := p)]
        case list[ModuleData] modules => [m | m <- modules, !(module_empty(_) := m)]
        case list[LevelDraftData] level_drafts => [ld | ld <- level_drafts, !(level_draft_empty(_) := ld)]
        case list[SectionData] sections => [s | s <- sections, !(section_empty(_,_,_,_) := s)]
    };

    pprs = visit(pprs) {
        case str s => toLowerCase(s)
    }

    visit(pprs) {
        case SectionData s:section_commands_data(_,_,_,_): processed_commands += s.commands;
        case SectionData s:section_patterns_data(_,_,_,_): processed_patterns += s.patterns;
        case SectionData s:section_modules_data(_,_,_,_): processed_modules += s.modules;
        case SectionData s:section_level_drafts_data(_,_,_,_): processed_level_drafts += s.level_drafts;
    };

    PapyrusData pprs_processed = papyrus_data(
        processed_commands,
        processed_patterns,
        processed_modules,
        processed_level_drafts
    );

    return pprs_processed;
}