/*
 * @Module: Module
 * @Desc:   Module that contains the functionality for the generation module
 * @Auth:   Borja Velasco -> code, comments
 */
module Generation::ADT::Module

/******************************************************************************/
// --- Genearal modules imports ------------------------------------------------
import List;

/******************************************************************************/
// --- Own modules imports -----------------------------------------------------
import Generation::ADT::Rule;
import Annotation::ADT::Verb;

/******************************************************************************/
// --- Data structure defines --------------------------------------------------

/*
 * @Name:   GenerationModule
 * @Desc:   Data structure that models a generation module
 */
data GenerationModule
    = generation_module(map[Verb verbs, GenerationRule generation_rule] generation_rules)
    | generation_module_empty()
    ;

/******************************************************************************/
// --- Public functions --------------------------------------------------------

/*
 * @Name:   generation_module_verb_sequence_next
 * @Desc:   Function that gets the next verb of a verb that is part of a sequence
 * @Param:  \module -> Module of the verb
 *          current -> Current verb to get the next from
 * @Ret:    Next verb
 */
Verb generation_module_verb_sequence_next(GenerationModule \module, Verb current) {
    return generation_module_get_verb(\module, current.dependencies.next.name, current.dependencies.next.specification);
}

/*
 * @Name:   generation_module_verb_sequence_size
 * @Desc:   Function that calculates the size of a sequence of verbs
 * @Param:  \module -> Module of the verb
 *          verb    -> Start of the sequence
 * @Ret:    Size of the sequence or -1 if the verb is inductive
 */
int generation_module_verb_sequence_size(GenerationModule \module, Verb verb) {
    int size = 0;

    if (verb_is_inductive(verb)) return -1;

    Verb current = verb;
    while (current.dependencies.next.name != "none") {
        size += current.size;
        current = generation_module_verb_sequence_next(\module, current);
    }
    size += current.size;

    return size;
}

/*
 * @Name:   generation_module_get_verb
 * @Desc:   Function that gets a verb given its name and speciication. If the 
 *          specification is "_" it just returns the first match
 * @Param:  \module            -> Module of the verb
 *          verb_name          -> Name of the verb
 *          verb_specification -> Specification of the verb 
 * @Ret:    Verb
 */
Verb generation_module_get_verb(GenerationModule \module, str verb_name, str verb_specification) {
    for (Verb v <- \module.generation_rules.verbs) {
        if (v.name == verb_name 
            && (v.specification == verb_specification
                || verb_specification == "_")) return v;
    }

    return verb_empty();
}

/*
 * @Name:   generation_module_get_verb_after
 * @Desc:   Function that gets a verb to be applied after another verb
 * @Param:  \module                    -> Module of the verb
 *          verb_current_name          -> Name of the verb to be found
 *          verb_current_specification -> Specification of the verb to be found
 *          verb_prev_name             -> Name of the previous verb
 *          verb_prev_specification    -> Specification of the previous verb
 * @Ret:    Verb
 */
Verb generation_module_get_verb_after(GenerationModule \module, str verb_current_name, str verb_current_specification, str verb_prev_name, str verb_prev_specification) {
    for (Verb v <- \module.generation_rules.verbs) {
        if (v.name == verb_current_name 
            && v.specification == verb_current_specification
            && verb_is_after(v)
            && v.dependencies.prev.name == verb_prev_name
            && v.dependencies.prev.specification == verb_prev_specification) return v;
    }

    return verb_empty();
}

/*
 * @Name:   generation_module_get_verb_before
 * @Desc:   Function that gets a verb to be applied before another verb
 * @Param:  \module                    -> Module of the verb
 *          verb_current_name          -> Name of the verb to be found
 *          verb_current_specification -> Specification of the verb to be found
 *          verb_next_name             -> Name of the next verb
 *          verb_next_specification    -> Specification of the next verb
 * @Ret:    Verb
 */
Verb generation_module_get_verb_before(GenerationModule \module, str verb_current_name, str verb_current_specification, str verb_next_name, str verb_next_specification) {
    for (Verb v <- \module.generation_rules.verbs) {
        if (v.name == verb_current_name 
            && v.specification == verb_current_specification
            && verb_is_before(v)
            && v.dependencies.next.name == verb_next_name
            && v.dependencies.next.specification == verb_next_specification) return v;
    }

    return verb_empty();
}

/*
 * @Name:   generation_module_get_verb_before
 * @Desc:   Function that gets a verb to be applied in the middle part of a subchunk
 * @Param:  \module                    -> Module of the verb
 *          verb_current_name          -> Name of the verb to be found
 * @Ret:    Tuple with an inductive and sequential verb
 */
tuple[Verb,Verb] generation_module_get_verb_mid(GenerationModule \module, str verb_current_name) {
    tuple[Verb ind, Verb seq] verb = <verb_empty(), verb_empty()>;
    list[Verb] verbs_ind = [];
    list[Verb] verbs_seq = [];

    for (Verb v <- \module.generation_rules.verbs) {
        if (v.name == verb_current_name 
            && !verb_is_after(v)
            && !verb_is_before(v)) {

            if (verb_is_sequence_start(v)) verbs_seq += [v];
            else if (verb_is_inductive(v)) verbs_ind += [v];
        }
    }

    if      (verbs_ind == []) verb.seq = getOneFrom(verbs_seq);
    else if (verbs_seq == []) verb.ind = getOneFrom(verbs_ind);
    else                      verb = <getOneFrom(verbs_ind),getOneFrom(verbs_seq)>;

    return verb;
}