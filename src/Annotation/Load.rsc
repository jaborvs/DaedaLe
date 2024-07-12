/*
 * @Name:   Load
 * @Desc:   Module to parse and implode the annotation syntax
 * @Auth:   Borja Velasco -> code, comments
 */
module Annotation::Load

/******************************************************************************/
// --- General modules imports -------------------------------------------------
import ParseTree;
import String;
import List;
import Set;

/******************************************************************************/
// --- Own modules imports -----------------------------------------------------
import Annotation::Syntax;
import Annotation::AST;

/******************************************************************************/
// --- Public load functions --------------------------------------------------

/*
 * @Name:   annotation_load
 * @Desc:   Function that reads a comment and parses the annotation
 * @Param:  src -> String with the comment
 * @Ret:    Annotation object
 */
Annotation annotation_load(map[int key, list[str] content] comments) {
    str comments_processed = comments[toList(comments.key)[0]][0];
    return annotation_load(comments_processed);
}

/*
 * @Name:   annotation_load
 * @Desc:   Function that reads a comment and parses the annotation
 * @Param:  src -> String with the comment
 * @Ret:    Annotation object
 */
Annotation annotation_load(str src) {
    start[Annotation] v = annotation_parse(src);
    Annotation ast = annotation_implode(v);
    ast = annotation_process(ast);
    return ast;
}

/******************************************************************************/
// --- Public parsing functions ------------------------------------------------

/*
 * @Name:   annotation_parse
 * @Desc:   Function that reads a papyrus file and parses it
 * @Param:  path -> Location of the file
 * @Ret:    
 */
start[Annotation] annotation_parse(str src) {
    return parse(#start[Annotation], src);
}

/*
 * @Name:   annotation_implode
 * @Desc:   Function that takes a parse tree and builds the ast
 * @Param:  tree -> Parse tree
 * @Ret:    Annotation object
 */
Annotation annotation_implode(start[Annotation] parse_tree) {
    Annotation v = implode(#Annotation, parse_tree);
    return v;
}

/******************************************************************************/
// --- Processing functions ----------------------------------------------------

/*
 * @Name:   annotation_implode
 * @Desc:   Function that processes an annotation
 * @Param:  tree -> Parse tree
 * @Ret:    Annotation object
 */
Annotation annotation_process(Annotation \anno) {
    if (size(\anno.args) == 2) \anno.args = insertAt(\anno.args, 0, argument_single("default"));
    if (size(\anno.args) == 3) \anno.args += [argument_tuple(
            reference("none", []),
            reference("none", [])
        )];

    return visit(\anno) {
        case str s => toLowerCase(s)
    };
}
