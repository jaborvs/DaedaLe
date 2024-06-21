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
import Extension::ADT::Verb;
import Extension::ADT::Module;

/******************************************************************************/
// --- Public load functions --------------------------------------------------

/*
 * @Name:   extension_load_verb
 * @Desc:   Function that reads a comment and parses the verb
 * @Param:  src -> String with the comment
 * @Ret:    Verb object
 */
Verb extension_load_verb(map[int key, list[str] content] comments) {
    Extension ext = extension_load(comments);

    if (size(ext.args) == 2) ext.args = insertAt(ext.args, 0, argument_single("default"));    // Specification
    if (size(ext.args) == 3) ext.args += [argument_tuple(
            reference_none("none"),
            reference_none("none")
        )];                  // Dependency

    tuple[
        tuple[str name, str specification] prev, 
        tuple[str name, str specification] next
        ] dependencies = <<"","">,<"","">>;
    if (ext.args[3].prev is reference_none) dependencies.prev = <ext.args[3].prev.val,"_">;
    else                                    dependencies.prev = <ext.args[3].prev.verb_name, ext.args[3].prev.verb_specification>;
    if (ext.args[3].next is reference_none) dependencies.next = <ext.args[3].next.val,"_">;
    else                                    dependencies.next = <ext.args[3].next.verb_name, ext.args[3].next.verb_specification>;

    Verb v = verb(
        toLowerCase(ext.name),
        toLowerCase(ext.args[0].val),   // Specification: low, medium, large
        toLowerCase(ext.args[1].val),   // Direction: up, down, right
        toInt(ext.args[2].val),         // Size
        dependencies                    // Dependencies: <previous_verb, next_verb>
        );
    return v;
}

/*
 * @Name:   extension_load_module
 * @Desc:   Function that reads a comment and parses the module
 * @Param:  src -> String with the comment
 * @Ret:    Module object
 */
Module extension_load_module(map[int key, list[str] content] comments) {
    Extension ext = extension_load(comments);
    Module v = \module(
        ext.name
        );
    return v;
}


/*
 * @Name:   extension_load
 * @Desc:   Function that reads a comment and parses the extension
 * @Param:  src -> String with the comment
 * @Ret:    Extension object
 */
Extension extension_load(map[int key, list[str] content] comments) {
    str comments_processed = comments[toList(comments.key)[0]][0];
    return extension_load(comments_processed);
}

/*
 * @Name:   extension_load
 * @Desc:   Function that reads a comment and parses the extension
 * @Param:  src -> String with the comment
 * @Ret:    Extension object
 */
Extension extension_load(str src) {
    start[Extension] v = extension_parse(src);
    Extension ast = extension_implode(v);
    ast = extension_process(ast);
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

/******************************************************************************/
// --- Processing functions ----------------------------------------------------

Extension extension_process(Extension ext) {
    return visit(ext) {
        case str s => toLowerCase(s)
    };
}
