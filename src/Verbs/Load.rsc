/*
 * @Name:   Load
 * @Desc:   Module to parse and implode the verb syntax
 * @Auth:   Borja Velasco -> code, comments
 */
module Verbs::Load

/******************************************************************************/
// --- General modules imports -------------------------------------------------
import ParseTree;
import IO;

/******************************************************************************/
// --- Own modules imports -----------------------------------------------------
import Verbs::Syntax;
import Verbs::AST;

/******************************************************************************/
// --- Public load functions ---------------------------------------------------

/*
 * @Name:   load
 * @Desc:   Function that reads a comment and parses the verb
 * @Param:  src -> String with the comment
 * @Ret:    Verb object
 */
Verb verb_load(str src) {
    start[Verb] v = verb_parse(src);
    Verb ast = verb_implode(v);
    return ast;
}

/******************************************************************************/
// --- Public parsing functions ------------------------------------------------

/*
 * @Name:   verb_parse
 * @Desc:   Function that reads a papyrus file and parses it
 * @Param:  path -> Location of the file
 * @Ret:    
 */
start[Verb] verb_parse(str src) {
    return parse(#start[Verb], src);
}

/*
 * @Name:   verb_implode
 * @Desc:   Function that takes a parse tree and builds the ast
 * @Param:  tree -> Parse tree
 * @Ret:    Verb object
 */
Verb verb_implode(start[Verb] parse_tree) {
    Verb v = implode(#Verb, parse_tree);
    return v;
}
