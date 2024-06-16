/*
 * @Name:   Load
 * @Desc:   Module to parse and implode the extension syntax
 * @Auth:   Borja Velasco -> code, comments
 */
module Extension::Load

/******************************************************************************/
// --- General modules imports -------------------------------------------------
import ParseTree;
import String;
import List;
import Set;
import IO;

/******************************************************************************/
// --- Own modules imports -----------------------------------------------------
import Extension::Syntax;
import Extension::AST;

/******************************************************************************/
// --- Public load functions ---------------------------------------------------

Extension extension_load(map[int key, list[str] content] comments) {
    str comments_processed = comments[toList(comments.key)[0]][0];
    return extension_load(comments_processed);
}

/*
 * @Name:   load
 * @Desc:   Function that reads a comment and parses the extension
 * @Param:  src -> String with the comment
 * @Ret:    Extension object
 */
Extension extension_load(str src) {
    start[Extension] v = extension_parse(src);
    Extension ast = extension_implode(v);
    return ast;
}

/******************************************************************************/
// --- Public parsing functions ------------------------------------------------

/*
 * @Name:   extension_parse
 * @Desc:   Function that reads a papyrus file and parses it
 * @Param:  path -> Location of the file
 * @Ret:    
 */
start[Extension] extension_parse(str src) {
    return parse(#start[Extension], src);
}

/*
 * @Name:   extension_implode
 * @Desc:   Function that takes a parse tree and builds the ast
 * @Param:  tree -> Parse tree
 * @Ret:    Extension object
 */
Extension extension_implode(start[Extension] parse_tree) {
    Extension v = implode(#Extension, parse_tree);
    return v;
}
