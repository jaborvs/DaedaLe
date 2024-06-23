/*
 * @Module: Verb
 * @Desc:   Module that contains all the verb functionality
 * @Auth:   Borja Velasco -> code, comments
 */
module Annotation::ADT::Verb

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
        tuple[tuple[str name, str specification] prev, tuple[str name, str specification] next] dependencies
        )
    | verb_annotation_empty()
    ;

/******************************************************************************/
// --- Public function defines -------------------------------------------------

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
        //    && verb.dependencies.next.name == "none";
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
    return  verb.dependencies.next.name != "none" 
           && verb.dependencies.next.name != verb.name;
        //    verb.dependencies.prev.name == "none"
        //    &&
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
    = verb_annotation_to_string(verb.name, verb.specification);

/*
 * @Name:   verb_annotation_to_string
 * @Desc:   Function that converts a verb to a string
 * @Param:  name          -> Name of the verb
 *          specification -> Specification of the verb
 * @Ret:    Stringified verb
 */
str verb_annotation_to_string(str name, str specification)
    = "<name>(<specification>)";