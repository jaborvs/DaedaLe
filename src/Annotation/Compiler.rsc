/*
 * @Module: AST
 * @Desc:   Module that compiles annotations
 * @Auth:   Borja Velasco -> code, comments
 */
module Annotation::Compiler

// --- General modules imports -------------------------------------------------
import String;
import List;
import Set;

/******************************************************************************/
// --- Own modules imports -----------------------------------------------------
import Annotation::AST;
import Annotation::Exception;
import Annotation::ADT::Verb;
import Annotation::ADT::Chunk;


/******************************************************************************/
// --- Public compile verb annotation functions --------------------------------

VerbAnnotation compile_verb_annotation(Annotation \anno) {
    VerbAnnotation verb_anno = verb_annotation_empty();
    str verb_name = "";
    str verb_specification = "";
    str verb_direction = "";
    int verb_size = -1;
    tuple[
        tuple[str name, str specification, str direction] prev, 
        tuple[str name, str specification, str direction] next
        ] verb_dependencies = <<"","","">,<"","","">>;

    verb_name          = compile_verb_annotation_name(\anno);
    verb_specification = compile_verb_annotation_specification(\anno);
    verb_direction     = compile_verb_annotation_direction(\anno);
    verb_size          = compile_verb_annotation_size(\anno);
    verb_dependencies  = compile_verb_annotation_dependencies(\anno);
    
    verb_anno = verb_annotation(
        verb_name,
        verb_specification,
        verb_direction,
        verb_size,
        verb_dependencies
        );

    return verb_anno;
}

/*
 * @Name:   compile_verb_annotation_name
 * @Desc:   Function that compiles the name of a verb annotation
 * @Param:  \anno -> Annotation
 * @Ret:    String with the name
 */
str compile_verb_annotation_name(Annotation \anno) {
    return \anno.name;
}

/*
 * @Name:   compile_verb_annotation_specification
 * @Desc:   Function that compiles the specification of a verb annotation. It 
 *          checks the length of the args to see if it has been specified. In 
 *          case not, it adds it
 * @Param:  \anno -> Annotation
 * @Ret:    String with the specification
 */
str compile_verb_annotation_specification(Annotation \anno) {
    return (\anno.args[0].arg != "") ? \anno.args[0].arg : "default";
}

/*
 * @Name:   compile_verb_annotation_direction
 * @Desc:   Function that compiles the direction of a verb annotation
 * @Param:  \anno -> Annotation
 * @Ret:    String with the direction
 */
str compile_verb_annotation_direction(Annotation \anno) {
    return \anno.args[1].arg;
}

/*
 * @Name:   compile_verb_annotation_size
 * @Desc:   Function that compiles the size of a verb annotation
 * @Param:  \anno -> Annotation
 * @Ret:    Int with the size
 */
int compile_verb_annotation_size(Annotation \anno) {
    return toInt(\anno.args[2].arg);
}

/*
 * @Name:   compile_verb_annotation_dependencies
 * @Desc:   Function that compiles the dependencies of a verb annotation
 * @Param:  \anno -> Annotation
 * @Ret:    Tuple with dependencies
 */
tuple[tuple[str,str,str], tuple[str,str,str]] compile_verb_annotation_dependencies(Annotation \anno) {
    tuple[
        tuple[str name, str specification, str direction] prev, 
        tuple[str name, str specification, str direction] next
        ] dependencies = <<"","","">,<"","","">>;

    dependencies.prev = compile_verb_annotation_dependency(\anno.args[3].prev.verb_name, \anno.args[3].prev.args);
    dependencies.next = compile_verb_annotation_dependency(\anno.args[3].next.verb_name, \anno.args[3].next.args);

    return dependencies;
}


tuple[str,str,str] compile_verb_annotation_dependency(str name, list[str] args) {
    tuple[str name, str specification, str direction] dependency = <"","","">;
 
    if      (name == "none")  dependency = <name, "undefined", "undefined">;
    else if (size(args) == 0) dependency = <name, "_", "_">;          
    else if (size(args) == 1) dependency = <name, args[0], "_">;
    else if (size(args) == 2) dependency = <name, args[0], args[1]>;
    else                      exception_verb_annotation_dependency_invalid_args();

    return dependency;
}

/******************************************************************************/
// --- Public compile chunk annotation functions -------------------------------

/*
 * @Name:   compile_chunk_annotation
 * @Desc:   Function that compiles a chunk annotation
 * @Param:  \anno -> Annotation
 * @Ret:    ChunkAnnotation
 */
ChunkAnnotation compile_chunk_annotation(Annotation \anno) {
    ChunkAnnotation chunk_anno = chunk_annotation_empty();

    chunk_anno = chunk_annotation(
        \anno.name,
        \anno.args[0].arg
        );

    return chunk_anno;
}