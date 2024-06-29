/*
 * @Module: Module
 * @Desc:   Module that contains the functionality for the generation module
 * @Auth:   Borja Velasco -> code, comments
 */
module Generation::ADT::Module

/******************************************************************************/
// --- Genearal modules imports ------------------------------------------------
import List;
import String;

/******************************************************************************/
// --- Own modules imports -----------------------------------------------------
import Generation::ADT::Rule;
import Generation::ADT::Verb;
import Annotation::ADT::Verb;

/******************************************************************************/
// --- Data structure defines --------------------------------------------------

/*
 * @Name:   GenerationModule
 * @Desc:   Data structure that models a generation module
 */
data GenerationModule
    = generation_module(map[VerbAnnotation verbs, GenerationRule generation_rule] generation_rules)
    | generation_module_empty()
    ;

/******************************************************************************/
// --- Public functions --------------------------------------------------------

/*
 * @Name:   generation_module_verb_depends
 * @Desc:   Function that checks if one verb depends of another
 * @Param:  \module -> Module of the verb
 *          verb1   -> Verb to check the dependency
 *          verb2   -> Verb to check if the verb1 depends on
 * @Ret:    Boolean
 */
bool generation_module_verb_depends(GenerationModule \module, VerbAnnotation verb1, VerbAnnotation verb2) {
    VerbAnnotation current = verb1;

    while (current.dependencies.next.name != "none") {
        if (current.dependencies.next.name == verb2.name
            && current.dependencies.next.specification == verb2.specification
            && current.dependencies.next.direction == verb2.direction) return true;

        current = generation_module_verb_sequence_next(\module, current);
    }

    return false;
}

/*
 * @Name:   generation_module_verb_sequence_next
 * @Desc:   Function that gets the next verb of a verb that is part of a sequence
 * @Param:  \module -> Module of the verb
 *          current -> Current verb to get the next from
 * @Ret:    Next verb
 */
VerbAnnotation generation_module_verb_sequence_next(GenerationModule \module, VerbAnnotation  current) {
    return generation_module_get_verb(\module, current.dependencies.next.name, current.dependencies.next.specification, current.dependencies.next.direction);
}

/*
 * @Name:   generation_module_verb_sequence_size
 * @Desc:   Function that calculates the size of a sequence of verbs
 * @Param:  \module -> Module of the verb
 *          verb    -> Start of the sequence
 * @Ret:    Size of the sequence or -1 if the verb is inductive
 */
int generation_module_verb_sequence_size(GenerationModule \module, VerbAnnotation verb) {
    int size = 0;

    if (verb_annotation_is_inductive(verb)) return -1;

    VerbAnnotation current = verb;
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
VerbAnnotation generation_module_get_verb(GenerationModule \module, str verb_name, str verb_specification, str verb_direction) {
    for (VerbAnnotation v <- \module.generation_rules.verbs) {
        if (v.name == verb_name 
            && (v.specification == verb_specification || verb_specification == "_")
            && (v.direction == verb_direction || verb_direction == "_")) return v;
    }

    return verb_annotation_empty();
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
VerbAnnotation generation_module_get_verb_after(GenerationModule \module, GenerationVerbConcretized verb_current, GenerationVerbConcretized verb_prev, bool chunk_end) {
    for (VerbAnnotation v <- \module.generation_rules.verbs) {
        if (v.name == verb_current.name 
            && v.direction == verb_current.direction
            && (v.direction != "end" || chunk_end)
            && v.dependencies.prev.name == verb_prev.name
            && (v.dependencies.prev.specification == verb_prev.specification || v.dependencies.prev.specification == "_")
            && (v.dependencies.prev.direction == verb_prev.direction         || v.dependencies.prev.direction == "_")) return v;
    }

    return verb_annotation_empty();
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
VerbAnnotation generation_module_get_verb_before(GenerationModule \module, GenerationVerbConcretized verb_current, GenerationVerbConcretized verb_next) {
    for (VerbAnnotation v <- \module.generation_rules.verbs) {
        if (v.name == verb_current.name 
            && (v.direction == verb_current.direction)
            && v.dependencies.next.name == verb_next.name
            && (v.dependencies.next.specification == verb_next.specification || v.dependencies.next.specification == "_")
            && (v.dependencies.next.direction == verb_next.direction || v.dependencies.next.direction == "_")) return v;
    }

    return verb_annotation_empty();
}

/*
 * @Name:   generation_module_get_verb_before
 * @Desc:   Function that gets a verb to be applied in the middle part of a subchunk
 * @Param:  \module                    -> Module of the verb
 *          verb_current_name          -> Name of the verb to be found
 * @Ret:    Tuple with an inductive and sequential verb
 */
tuple[VerbAnnotation,VerbAnnotation] generation_module_get_verb_mid(GenerationModule \module, GenerationVerbConcretized verb_current) {
    tuple[VerbAnnotation ind, VerbAnnotation seq] verb = <verb_annotation_empty(), verb_annotation_empty()>;
    list[VerbAnnotation] verbs_ind = [];
    list[VerbAnnotation] verbs_seq = [];

    for (VerbAnnotation v <- \module.generation_rules.verbs) {
        bool tmp1 = v.name == verb_current.name;
        bool tmp2 = (v.specification == verb_current.specification || verb_current.specification == "_");
        bool tmp3 = (v.direction == verb_current.direction || verb_current.direction == "_");
        bool tmp4 = !verb_annotation_is_after(v);
        bool tmp5 = !verb_annotation_is_before(v);

        if (v.name == verb_current.name 
            && (v.specification == verb_current.specification || verb_current.specification == "_")
            && (v.direction == verb_current.direction || verb_current.direction == "_")
            && !verb_annotation_is_after(v)
            && !verb_annotation_is_before(v)) {

            if (verb_annotation_is_sequence_start(v)) verbs_seq += [v];
            else if (verb_annotation_is_inductive(v)) verbs_ind += [v];
        }
    }

    if      (verbs_ind == [] && verbs_seq != []) verb.seq = getOneFrom(verbs_seq);
    else if (verbs_ind != [] && verbs_seq == []) verb.ind = getOneFrom(verbs_ind);
    else if (verbs_ind != [] && verbs_seq != []) verb = <getOneFrom(verbs_ind),getOneFrom(verbs_seq)>;

    return verb;
}