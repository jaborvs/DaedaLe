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