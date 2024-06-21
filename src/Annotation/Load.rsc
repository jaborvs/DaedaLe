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
import IO;

/******************************************************************************/
// --- Own modules imports -----------------------------------------------------
import Annotation::Syntax;
import Annotation::AST;
import Annotation::ADT::Verb;
import Annotation::ADT::Chunk;

/******************************************************************************/
// --- Public load functions --------------------------------------------------

/*
 * @Name:   annotation_load_verb
 * @Desc:   Function that reads a comment and parses the verb
 * @Param:  src -> String with the comment
 * @Ret:    Verb object
 */
Verb annotation_load_verb(map[int key, list[str] content] comments) {
    Annotation \anno = annotation_load(comments);

    // Specification
    if (size(\anno.args) == 2) \anno.args = insertAt(\anno.args, 0, argument_single("default"));
    
    // Dependency
    if (size(\anno.args) == 3) \anno.args += [argument_tuple(
            reference_none("none"),
            reference_none("none")
        )];                  

    tuple[
        tuple[str name, str specification] prev, 
        tuple[str name, str specification] next
        ] dependencies = <<"","">,<"","">>;
    if (\anno.args[3].prev is reference_none) dependencies.prev = <\anno.args[3].prev.val,"_">;
    else                                    dependencies.prev = <\anno.args[3].prev.verb_name, \anno.args[3].prev.verb_specification>;
    if (\anno.args[3].next is reference_none) dependencies.next = <\anno.args[3].next.val,"_">;
    else                                    dependencies.next = <\anno.args[3].next.verb_name, \anno.args[3].next.verb_specification>;

    Verb v = verb(
        toLowerCase(\anno.name),
        toLowerCase(\anno.args[0].val),   // Specification: low, medium, large
        toLowerCase(\anno.args[1].val),   // Direction: up, down, right
        toInt(\anno.args[2].val),         // Size
        dependencies                    // Dependencies: <previous_verb, next_verb>
        );
    return v;
}

/*
 * @Name:   annotation_load_module
 * @Desc:   Function that reads a comment and parses the module
 * @Param:  src -> String with the comment
 * @Ret:    Module object
 */
ChunkAnnotation annotation_load_module(map[int key, list[str] content] comments) {
    Annotation \anno = annotation_load(comments);
    ChunkAnnotation v = chunk_annotation(
        \anno.name,
        \anno.args[0].val
        );
    return v;
}


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

Annotation annotation_process(Annotation \anno) {
    return visit(\anno) {
        case str s => toLowerCase(s)
    };
}
