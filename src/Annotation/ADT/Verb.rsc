/*
 * @Module: Verb
 * @Desc:   Module that contains all the verb functionality
 * @Auth:   Borja Velasco -> code, comments
 */
module Annotation::ADT::Verb

/******************************************************************************/
// --- Own modules imports -----------------------------------------------------
import Utils;

/******************************************************************************/
// --- Data structure defines --------------------------------------------------

/*
 * @Name:   Verb
 * @Desc:   Structure to model an verb
 */
data VerbAnnotation
    = verb_annotation(
        str name, 
        str specification, 
        str direction, 
        int size, 
        tuple[
            tuple[str name, str specification, str direction] prev, 
            tuple[str name, str specification, str direction] next
            ] dependencies
        )
    | verb_annotation_empty()
    ;

/******************************************************************************/
// --- Global implicit verb defines --------------------------------------------

VerbAnnotation enter_verb = verb_annotation("enter", "default", "none", 0, <<"none", "", "">,<"none", "", "">>);
VerbAnnotation exit_verb  = verb_annotation("exit",  "default", "none", 0, <<"none", "", "">,<"none", "", "">>);

/******************************************************************************/
// --- Public function defines -------------------------------------------------

/*
 * @Name:   verb_is_end
 * @Desc:   Function that checks if a verb is an end verb 
 * @Param:  verb -> VerbAnnotationto be checked
 * @Ret:    Boolean
 */
bool verb_is_end(VerbAnnotation verb) {
    return (verb.direction == "end");
}


/*
 * @Name:   verb_annotation_is_before
 * @Desc:   Function that checks if a verb is an after verb. We consider a verb a 
 *          after verb if it has to be applied after the last verb of the 
 *          previous subchunk. This means its prev value is set to a verb of a different
 *          name
 * @Param:  verb -> VerbAnnotationto be checked
 * @Ret:    Boolean
 */
bool verb_annotation_is_after(VerbAnnotation verb) {
    return verb.dependencies.prev.name != "none" 
           && verb.dependencies.prev.name != verb.name;
}

/*
 * @Name:   verb_annotation_is_before
 * @Desc:   Function that checks if a verb is a before verb. We consider a verb a 
 *          before verb if it has to be applied before the first verb of the 
 *          next subchunk. This means its next value is set to a verb of a different
 *          name
 * @Param:  verb -> VerbAnnotationto be checked
 * @Ret:    Boolean
 */
bool verb_annotation_is_before(VerbAnnotation verb) {
    return verb.dependencies.next.name != "none" 
           && verb.dependencies.next.name != verb.name;
}

/*
 * @Name:   verb_annotation_is_sequence_start
 * @Desc:   Function that checks if a verb is a sequence start. We consider a verb a 
 *          sequence verb start if it has a non set prev and a set prev 
 * @Param:  verb -> VerbAnnotationto be checked
 * @Ret:    Boolean
 */
bool verb_annotation_is_sequence_start(VerbAnnotation verb) {
    return verb.dependencies.prev.name == "none" 
           && verb.dependencies.next.name != "none";
}

/*
 * @Name:   verb_annotation_is_sequence_start
 * @Desc:   Function that checks if a verb is a sequence start. We consider a verb a 
 *          sequence verb start if it has a non set prev and next
 * @Param:  verb -> VerbAnnotationto be checked
 * @Ret:    Boolean
 */
bool verb_annotation_is_inductive(VerbAnnotation verb) {
    return verb.dependencies.prev.name == "none" 
           && verb.dependencies.next.name == "none";
}

/*
 * @Name:   verb_annotation_to_string
 * @Desc:   Function that converts a verb to a string
 * @Param:  verb -> VerbAnnotationto be converted
 * @Ret:    Stringified verb
 */
str verb_annotation_to_string(VerbAnnotation verb)
    = "<string_capitalize(verb.name)>(<verb.specification>, <verb.direction>)";