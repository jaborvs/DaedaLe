/*
 * @Module: Verb
 * @Desc:   Module that contains all the verb functionality
 * @Auth:   Borja Velasco -> code, comments
 */
module Extension::Verb

/******************************************************************************/
// --- Data structure defines --------------------------------------------------

/*
 * @Name:   Verb
 * @Desc:   Structure to model an verb
 */
data Verb 
    = verb(
        str name, 
        str specification, 
        str direction, 
        int size, 
        tuple[tuple[str name, str specification] prev, tuple[str name, str specification] next] dependencies
        )
    | verb_empty()
    ;

/******************************************************************************/
// --- Public function defines -------------------------------------------------

/*
 * @Name:   verb_is_before
 * @Desc:   Function that checks if a verb is an after verb. We consider a verb a 
 *          after verb if it has to be applied after the last verb of the 
 *          previous subchunk. This means its prev value is set to a verb of a different
 *          name
 * @Param:  verb -> Verb to be checked
 * @Ret:    Boolean
 */
bool verb_is_after(Verb verb) {
    return verb.dependencies.prev.name != "none" 
           && verb.dependencies.prev.name != verb.name
           && verb.dependencies.next.name == "none";
}

/*
 * @Name:   verb_is_before
 * @Desc:   Function that checks if a verb is a before verb. We consider a verb a 
 *          before verb if it has to be applied before the first verb of the 
 *          next subchunk. This means its next value is set to a verb of a different
 *          name
 * @Param:  verb -> Verb to be checked
 * @Ret:    Boolean
 */
bool verb_is_before(Verb verb) {
    return verb.dependencies.prev.name == "none"
           && verb.dependencies.next.name != "none" 
           && verb.dependencies.next.name != verb.name;
}

/*
 * @Name:   verb_is_sequence
 * @Desc:   Function that checks if a verb is a sequence. We consider a verb a 
 *          sequence verb if it has a dependency set
 * @Param:  verb -> Verb to be checked
 * @Ret:    Boolean
 */
bool verb_is_sequence(Verb verb) {
    return verb.dependencies.prev.name != "none" 
           || verb.dependencies.next.name != "none";
}

/*
 * @Name:   verb_to_string
 * @Desc:   Function that converts a verb to a string
 * @Param:  verb -> Verb to be converted
 * @Ret:    Stringified verb
 */
str verb_to_string(Verb verb)
    = verb_to_string(verb.name, verb.specification);

/*
 * @Name:   verb_to_string
 * @Desc:   Function that converts a verb to a string
 * @Param:  name          -> Name of the verb
 *          specification -> Specification of the verb
 * @Ret:    Stringified verb
 */
str verb_to_string(str name, str specification = "_")
    = "<name>(<specification>)";