/*
 * @Module: Concretizer
 * @Desc:   Module that contains all the functionality to concretize verbs
 * @Auth:   Borja Velasco -> code, comments
 */
module Generation::Concretizer

/******************************************************************************/
// --- General modules imports -------------------------------------------------
import util::Math;
import List;
import Set;

/******************************************************************************/
// --- Own modules imports -----------------------------------------------------
import Generation::ADT::Module;
import Generation::ADT::VerbExpression;
import Generation::ADT::Chunk;

import Annotation::ADT::Verb;

import Utils;

/******************************************************************************/
// --- Public translate functions ----------------------------------------------

/*
 * @Name:   concretize
 * @Desc:   Function that concretizes the verbs to be applied in a chunk. It 
 *          transforms a regular-like expresion such as [crawl+, climb+] to an
 *          specific sequence of verbs
 * @Param:  chunk  -> GenertionChunk to be concretized
 *          width  -> Chunk width
 *          height -> Chunk height
 * @Ret:    List of concretized verbs
 */
tuple[list[list[str]], Coords] concretize(GenerationModule \module, list[GenerationVerbExpression] verbs, Coords entry, int width, int height) {
    list[list[str]] verbs_concretized = [];
    
    map[int, Coords] position_current = ();
    for (int i <- [0..size(verbs)]) position_current[i] = entry;
    
    tuple[list[list[str]] verbs_concretized, map[int, Coords] position_current] res = <[], ()>;
    res = concretize_init(\module, verbs, position_current);
    res = concretize_extend(\module, verbs, res.verbs_concretized, res.position_current, width, height);

    return <res.verbs_concretized, res.position_current[size(verbs)-1]>;
}

/*
 * @Name:   concretize_init
 * @Desc:   Function that concretizes the mandatory verbs to be applied in a 
 *          chunk
 * @Param:  verbs  -> GenerationVerbExpressions to be concretized
 *          position_current -> Dictionary with the current positions
 * @Ret:    List of concretized verbs and updated position_current
 */
tuple[list[list[str]], map[int,Coords]] concretize_init(GenerationModule \module, list[GenerationVerbExpression] verbs, map[int, Coords] position_current) {
    list[list[str]] verbs_concretized = [];

    int subchunk_num = size(verbs);

    for (int i <- [0..subchunk_num]) {
        str verb_name = verbs[i].verb;
        str verb_modifier = verbs[i].modifier;
        VerbAnnotation verb = generation_module_get_verb(\module, verb_name, "_");

        list[str] basket = [];
        if (verb_modifier == "+") basket += [verb_name];

        position_current = concretize_update_position_current(position_current, i, verb.direction);

        verbs_concretized += [basket];
    }

    return <verbs_concretized, position_current>;
}

/*
 * @Name:   concretize_extend
 * @Desc:   Function that concretizes all the verbs to be applied in a chunk
 *          (mandatory and non-mandatory)
 * @Param:  verbs             -> GenerationVerbExpressions to be concretized
 *          verbs_concretized -> List of concretized verbs
 *          position_current  -> Dictionary with the current positions
 *          width             -> Chunk width
 *          height            -> Chunk height
 * @Ret:    List of concretized verbs and updated position_current
 */
tuple[list[list[str]], map[int,Coords]] concretize_extend(GenerationModule \module, list[GenerationVerbExpression] verbs, list[list[str]] verbs_concretized, map[int,Coords] position_current, int width, int height) {
    int subchunk_num = size(verbs);
    int subchunk_last_compulsory = max([i | int i <- [0..subchunk_num], verbs[i].modifier == "+"]);

    bool exited = false;
    while (!exited) {
        int i = arbInt(subchunk_num);
        str verb_name = verbs[i].verb;
        VerbAnnotation verb = generation_module_get_verb(\module, verb_name, "_");

        if      (i < subchunk_last_compulsory
                && concretize_check_future_position_exited(position_current, i, verb.direction, width, height))    continue;
                
        verbs_concretized[i] += [verb_name];
        position_current = concretize_update_position_current(position_current, i, verb.direction);
        exited = concretize_check_position_current_exited(position_current, i, width, height);
    }

    return <verbs_concretized, position_current>;
}

/*
 * @Name:   concretize_check_future_position_exited
 * @Desc:   Function that checks if the future position to add will make us 
 *          exit from the chunk
 * @Param:  position_current  -> Dictionary with the current positions
 *          index             -> Index of the verb's subchunk to include
 *          direction         -> Direction of the verb
 *          width             -> Chunk width
 *          height            -> Chunk height
 * @Ret:    Boolean indicating if we exit or not
 */
bool concretize_check_future_position_exited(map[int keys, Coords coords] position_current, int index, str direction, int width, int height) {
    for(int i <- [index..size(position_current.keys)]) {
        if (direction == "up"    && position_current[i].y-1 == -1    ) return true;
        if (direction == "right" && position_current[i].x+1 == width ) return true;
        if (direction == "down"  && position_current[i].y+1 == height-1) return true;
    }
    return false;
}

/*
 * @Name:   concretize_update_position_current
 * @Desc:   Function that updates the position current after adding one more 
 *          concrete verb
 * @Param:  position_current  -> Dictionary with the current positions
 *          index             -> Index of the verb's subchunk to include
 *          direction         -> Direction of the verb
 * @Ret:    Updated position current
 */
map[int, Coords] concretize_update_position_current(map[int keys, Coords coords] position_current, int index, str direction) {
    for(int i <- [index..size(position_current.keys)]) {
        if      (direction == "up")    position_current[i].y -= 1;
        else if (direction == "right") position_current[i].x += 1;
        else if (direction == "down")  position_current[i].y += 1;
    }

    return position_current;
}

/*
 * @Name:   concretize_check_position_current_exited
 * @Desc:   Function that checks if the last verb included made us exit from 
 *          the chunk
 * @Param:  position_current  -> Dictionary with the current positions
 *          index             -> Index of the verb's subchunk to include
 *          width             -> Chunk width
 *          height            -> Chunk height
 * @Ret:    Updated position current
 */
bool concretize_check_position_current_exited(map[int keys, Coords coords] position_current, int index, int width, int height) {
    for(int i <- [index..size(position_current.keys)]) {
        if (position_current[i].y == -1
            || position_current[i].x == width 
            || position_current[i].y == height) return true;
    }
    return false;
}