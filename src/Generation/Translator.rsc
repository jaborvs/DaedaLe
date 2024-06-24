/*
 * @Module: Translator
 * @Desc:   Module that contains all the functionality to translate verbs from
 *          abstract to specific
 * @Auth:   Borja Velasco -> code, comments
 */
module Generation::Translator

/******************************************************************************/
// --- General modules imports -------------------------------------------------

import List;

/******************************************************************************/
// --- Own modules imports -----------------------------------------------------
import Generation::ADT::Module;
import Generation::Exception;

import Annotation::ADT::Verb;

/******************************************************************************/
// --- Public translate functions ----------------------------------------------

/*
 * @Name:   translate
 * @Desc:   Function that translates a complete chunk. It translates each 
 *          subchunk individually keeping in mind which verbs the previous and 
 *          next subchunk use
 * @Param:  \module           -> Generation module of the chunk
 *          verbs_concretized -> List of verbs concretized
 * @Ret:    List of verbs translated
 */
list[VerbAnnotation] translate(GenerationModule \module, list[list[str]] verbs_concretized) {
    list[VerbAnnotation] verbs_translated = [];

    int subchunks_num = size(verbs_concretized);
    for (int i <- [0..subchunks_num]) {
        list[str] subchunk = verbs_concretized[i];
        if(subchunk == []) continue;

        tuple[list[VerbAnnotation] verbs_translated, int subchunk_size] res = <[],size(subchunk)>;

        tuple[str name, str specification] verb_prev = translate_get_verb_previous(verbs_translated);
        tuple[str name, str specification] verb_next = translate_get_verb_next(verbs_concretized, i);
        tuple[str name, str after_specification, str before_specification] verb_current = translate_get_verb_current(subchunk, verb_prev, verb_next);

        VerbAnnotation verb_after = generation_module_get_verb_after(\module, verb_current.name, verb_current.after_specification, verb_prev.name, verb_prev.specification);
        tuple[VerbAnnotation ind, VerbAnnotation seq] verb_mid = generation_module_get_verb_mid(\module, verb_current.name);
        VerbAnnotation verb_before = generation_module_get_verb_before(\module, verb_current.name, verb_current.before_specification, verb_next.name, verb_next.specification);
        bool verb_before_exists = !(verb_before is verb_annotation_empty);

        res = translate_single(res, verb_after);
        res = translate_loop(\module, res, verb_mid, verb_before_exists);
        res = translate_single(res, verb_before);

        verbs_translated += res.verbs_translated;
    }

    return verbs_translated;
}

/*
 * @Name:   translate_single
 * @Desc:   Function that translates a single verb. It is used for the after and 
 *          before verbs
 * @Param:  res     -> Tuple containing the translated verbs and the remaining 
 *                     subchunk size
 *          verb    -> VerbAnnotationto be translated
 * @Ret:
 */
tuple[list[VerbAnnotation],int] translate_single(tuple[list[VerbAnnotation] verbs_translated, int subchunk_size] res, VerbAnnotation verb) {
    if (verb is verb_annotation_empty) return res;

    res.verbs_translated += [verb];
    res.subchunk_size -= verb.size;
    return res;
}

/*
 * @Name:   translate_loop
 * @Desc:   Function to translate several verbs until we fill a subchunk. It is 
 *          used in the mid part of a subchunk
 * @Param:  \module -> Generation module for the subhcunk
 *          res     -> Tuple containing the translated verbs and the remaining 
 *                     subchunk size
 *          verb    -> Tuple containing the inductive and sequential verb
 *          verb_before_exists -> Boolean indicating there is a before verb to 
 *                                be applied after the mid verbs
 * @Ret:    Updated res
 */
tuple[list[VerbAnnotation],int] translate_loop(GenerationModule \module, tuple[list[VerbAnnotation] verbs_translated, int subchunk_size] res, tuple[VerbAnnotation ind, VerbAnnotation seq] verb, bool verb_before_exists) {
    if (verb.ind is verb_annotation_empty) res = translate_loop_seq(\module, res, verb.seq, verb_before_exists);
    else if (verb.seq is verb_annotation_empty) res = translate_loop_ind(res, verb.ind, verb_before_exists);
    else res = translate_loop_both(\module, res, verb, verb_before_exists);

    return res;
}

/*
 * @Name:   translate_loop_seq
 * @Desc:   Function to translate the mid part of a subchunk when we have only
 *          an sequential verb. The intuition is we apply each verb of the seq
 *          until we have filled the chunk
 * @Param:  res     -> Tuple containing the translated verbs and the remaining 
 *                     subchunk size
 *          verb    -> Sequential verb
 *          verb_before_exists -> Boolean indicating there is a before verb to 
 *                                be applied after the mid verbs
 * @Ret:    Updated res tuple
 */
tuple[list[VerbAnnotation],int] translate_loop_seq(GenerationModule \module, tuple[list[VerbAnnotation] verbs_translated, int subchunk_size] res, VerbAnnotation verb, bool verb_before_exists) {
    int subchunk_size_partial = (verb_before_exists) ? res.subchunk_size-1 : res.subchunk_size;

    if (generation_module_verb_sequence_size(\module, verb) < subchunk_size_partial) exception_verbs_translation_size_mismatch(verb, res.subchunk_size);

    VerbAnnotation current = verb;
    for (_ <- [0..subchunk_size_partial]) {
        res.verbs_translated += [current];
        res.subchunk_size -= current.size;
        subchunk_size_partial -= current.size;
        if (current.dependencies.next.name != "none") current = generation_module_verb_sequence_next(\module, current);
    }
    
    return res;
}

/*
 * @Name:   translate_loop_ind
 * @Desc:   Function to translate the mid part of a subchunk when we have only
 *          an inductive verb. The intuition is we apply the inductive verb 
 *          until we have filled the chunk
 * @Param:  res     -> Tuple containing the translated verbs and the remaining 
 *                     subchunk size
 *          verb    -> Inductive verb
 *          verb_before_exists -> Boolean indicating there is a before verb to 
 *                                be applied after the mid verbs
 * @Ret:    Updated res tuple
 */
tuple[list[VerbAnnotation],int] translate_loop_ind(tuple[list[VerbAnnotation] verbs_translated, int subchunk_size] res, VerbAnnotation verb, bool verb_before_exists) {
    int subchunk_size_partial = (verb_before_exists) ? res.subchunk_size-1 : res.subchunk_size;

    if (subchunk_size_partial % verb.size != 0) exception_verbs_translation_size_mismatch(verb, res.subchunk_size);

    while (subchunk_size_partial > 0) {
        res.verbs_translated += [verb];
        res.subchunk_size -= verb.size;
        subchunk_size_partial -= verb.size;
    }

    return res;
}

/*
 * @Name:   translate_loop_both
 * @Desc:   Function to translate the mid part of a subchunk when we have both 
 *          an inductive and a sequential verb. The intuition is we apply the 
 *          inductive verb until we can apply the sequential one to fill the 
 *          whole subchunk
 * @Param:  \module -> Generation module of the verbs
 *          res     -> Tuple containing the translated verbs and the remaining 
 *                     subchunk size
 *          verb    -> Tuple containing the inductive and sequential verb
 *          verb_before_exists -> Boolean indicating there is a before verb to 
 *                                be applied after the mid verbs
 * @Ret:    Updated res tuple
 */
tuple[list[VerbAnnotation],int] translate_loop_both(GenerationModule \module, tuple[list[VerbAnnotation] verbs_translated, int subchunk_size] res, tuple[VerbAnnotation ind, VerbAnnotation seq] verb, bool verb_before_exists) {
    int verb_seq_size = generation_module_verb_sequence_size(\module, verb.seq);
    int subchunk_size_partial = (verb_before_exists) ? res.subchunk_size-1 : res.subchunk_size;

    while (subchunk_size_partial > 0) {
        if (verb_seq_size >= subchunk_size_partial) {
            VerbAnnotation current = verb.seq;
            for (_ <- [0..subchunk_size_partial]) {
                res.verbs_translated += [current];
                res.subchunk_size -= current.size;
                subchunk_size_partial -= current.size;
                if (current.dependencies.next.name != "none") current = generation_module_verb_sequence_next(\module, current);
            }
        }
        else {
            res.verbs_translated += [verb.ind];
            res.subchunk_size -= verb.ind.size;
            subchunk_size_partial -= verb.ind.size;
        }

        if (subchunk_size_partial < 0) exception_verbs_translation_size_mismatch(verb.ind, res.subchunk_size);
    }

    return res;
}

/*
 * @Name:   translate_get_verb_previous
 * @Desc:   Function to get the last verb applied on the previous subchunk
 * @Param:  verbs_translated -> List of verbs translated
 * @Ret:    Name and specification of the last translated verb
 */
tuple[str,str] translate_get_verb_previous(list[VerbAnnotation] verbs_translated) {
    str name = (verbs_translated != []) ? verbs_translated[-1].name : "";
    str specification = (verbs_translated != []) ? verbs_translated[-1].specification : "";
    return <name, specification>;
}

/*
 * @Name:   translate_get_verb_next
 * @Desc:   Function to get the first verb to be used in the following subchunk
 * @Param:  verbs_concretized -> List of verbs concretized
 *          index             -> Current index of the subhcunk to be translated
 * @Ret:    Tuple with name and specification of the next verb
 */
tuple[str,str] translate_get_verb_next(list[list[str]] verbs_concretized, int index) {
    str name = (index+1 < size(verbs_concretized)) ? verbs_concretized[index+1][0] : "";
    str specification = (index+1 < size(verbs_concretized)) ? "_" : "";
    return <name, specification>;
}

/*
 * @Name:   translate_get_verb_current
 * @Desc:   Function to get the current verb to be translated
 * @Param:  subchunk  -> Current subchunk we are translating
 *          verb_prev -> Last verb applied on the previous subchunk
 *          verb_next -> First verb to be applied on the next subchunk
 * @Ret:    Tuple containing the name, the after specification and the 
 *          before specification
 */
tuple[str,str,str] translate_get_verb_current(list[str] subchunk, tuple[str name, str specification] verb_prev, tuple[str name, str specification] verb_next) {
    str name = subchunk[0];

    str after_specification = "_";
    if (verb_prev.name != "" 
        && verb_prev.specification != "") after_specification = "after_<verb_prev.name>_<verb_prev.specification>";

    str before_specification = "_";
    if (verb_next.name != "" 
            && verb_next.specification != "") before_specification = "before_<verb_next.name>";

    return <name, after_specification, before_specification>;
}
 