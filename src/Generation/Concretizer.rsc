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
import Map;

/******************************************************************************/
// --- Own modules imports -----------------------------------------------------
import Generation::ADT::Module;
import Generation::ADT::Verb;
import Generation::ADT::Chunk;
import Generation::Exception;

import Annotation::ADT::Verb;

import Utils;


/******************************************************************************/
// --- Public concretize functions ---------------------------------------------

/*
 * @Name:   concretize
 * @Desc:   Function that concretizes the verbs to use in a chunk
 * @Params: \module -> Module of the chunk
 *          chunk   -> Generation chunk
 *          entry   -> Entry coords to the chunk
 *          width   -> Width of the chunk
 *          height  -> Height of the chunk
 * @Ret:    Tuple with the winning and challengeing playtraces
 */
tuple[tuple[list[list[GenerationVerbConcretized]], Coords], tuple[list[list[GenerationVerbConcretized]], Coords]] concretize(GenerationModule \module, GenerationChunk chunk, Coords entry, tuple[int,int] pattern_max_size, tuple[int,int] chunk_size) {
    tuple[list[list[GenerationVerbConcretized]] verbs, map[int,Coords] position_current] win_concretized = <[], ()>;
    tuple[list[list[GenerationVerbConcretized]] verbs, map[int,Coords] position_current] challenge_concretized = <[], ()>;

    win_concretized = concretize_win(
        \module, 
        chunk.win_verbs, 
        entry, 
        pattern_max_size,
        chunk_size
        );
    Coords exit = win_concretized.position_current[size(win_concretized.verbs)-1];

    challenge_concretized = concretize_challenge(
        \module, 
        chunk.challenge_verbs, 
        entry, 
        chunk.win_verbs, 
        win_concretized.verbs, 
        win_concretized.position_current
        );
    Coords dead_end = (size(challenge_concretized.verbs)-1 in challenge_concretized.position_current) ? challenge_concretized.position_current[size(challenge_concretized.verbs)-1] : <-1,-1>;

    return <
        <win_concretized.verbs, exit>,
        <challenge_concretized.verbs, dead_end>
    >;
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
bool concretize_check_future_position_exited(map[int keys, Coords coords] position_current, int index, str direction, tuple[int width, int height] chunk_size) {
    for(int i <- [index..size(position_current.keys)]) {
        if      (direction == "up"    && position_current[i].y-1 == -1)                  return true;
        else if (direction == "right" && position_current[i].x+1 == chunk_size.width)    return true;
        else if (direction == "down"  && position_current[i].y+1 == chunk_size.height-1) return true;
    }

    return false;
}

/*
 * @Name:   concretize_check_future_pattern_fit
 * @Desc:   Function that checks if the pattern that will be applied fits
 * @Param:  position_current  -> Dictionary with the current positions
 *          index             -> Index of the verb's subchunk to include
 *          direction         -> Direction of the verb
 *          width             -> Chunk width
 *          height            -> Chunk height
 * @Ret:    Boolean indicating if it fits
 */
bool concretize_check_future_pattern_fit(map[int keys, Coords coords] position_current, int index, tuple[int width, int height] pattern_size, str direction, tuple[int width, int height] chunk_size) {
    if      (direction == "up"    && position_current[index].y > pattern_size.height)                           return true;
    else if (direction == "right" && (chunk_size.width - position_current[index].x - 1) > pattern_size.width)   return true;
    else if (direction == "down"  && (chunk_size.height - position_current[index].y - 1) > pattern_size.height) return true;
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
bool concretize_check_position_current_exited(map[int keys, Coords coords] position_current, int index, tuple[int width, int height] chunk_size) {
    for(int i <- [index..size(position_current.keys)]) {
        if (position_current[i].y == -1
            || position_current[i].x == chunk_size.width 
            || position_current[i].y == chunk_size.height) return true;
    }
    return false;
}

/*
 * @Name:   concretize_delete_unused
 * @Desc:   Function that deletes those verbs that are after the chunk exit
 * @Param:  verbs_concretized -> List of concretized verbs
 *          position_current  -> Dictionary with the current positions
 *          width             -> Chunk width
 *          height            -> Chunk height
 * @Ret:    List of concretized verbs and updated position_current
 */
tuple[list[list[GenerationVerbConcretized]], map[int,Coords]] concretize_delete_unused(list[list[GenerationVerbConcretized]] verbs_concretized, map[int keys, Coords coords] position_current, tuple[int width, int height] chunk_size) {
    int exit_num = min(
        [i | int i <- [0..size(position_current.keys)], 
             position_current[i].y == -1 
             || position_current[i].x == chunk_size.width 
             || position_current[i].y == chunk_size.height
        ]
        );

    for (int i <- [(exit_num+1)..size(position_current.keys)]) {
        verbs_concretized = remove(verbs_concretized, i);
        position_current = delete(position_current, i);
    }

    return <verbs_concretized, position_current>;
}

/*
 * @Name:   concretize_concat
 * @Desc:   Function that concats adjacent subchunks that use the same verbs
 * @Params: concretized_verbs -> List of concretized verbs
 *          position_current  -> Map with the positions after each subchunk
 * @Ret:    Tuple with the list of concated concretized verbs and their 
 *          corresponding positions
 */
tuple[list[list[GenerationVerbConcretized]], map[int,Coords]] concretize_concat(list[list[GenerationVerbConcretized]] concretized_verbs, map[int, Coords] position_current) {
    list[list[GenerationVerbConcretized]] concretized_verbs_concated = [];
    map[int, Coords] position_current_concated = ();

    int i = 0;
    int subchunk_num = 0;
    while(i < size(concretized_verbs)) {
        list[GenerationVerbConcretized] subchunk = concretized_verbs[i];
        Coords position_current_coords = position_current[i];
        list[int] neighbors_eq = concretize_get_neighbors_equivalent(concretized_verbs, i);

        i += 1;

        for(int n <- neighbors_eq) {
            subchunk += concretized_verbs[n];
            position_current_coords = position_current[i];
            i += 1;
        }

        concretized_verbs_concated += [subchunk];
        position_current_concated[subchunk_num] = position_current_coords;
        subchunk_num += 1;
    }

    return <concretized_verbs_concated, position_current_concated>;
}

/*
 * @Name:   concretize_get_neighbors_equivalent
 * @Desc:   Function that gets the index of those neighbor subchunks that use 
 *          the same verb of the given one. By neighbor we refer to those chunks
 *          that are next (towards the right of the list) and that are adjacent
 * @Params: concretized_verbs -> List of concretized verbs
 *          index             -> Index of the current subchunk
 * @Ret:    List with the indexes of the next neighbors that use the same index
 */
list[int] concretize_get_neighbors_equivalent(list[list[GenerationVerbConcretized]] concretized_verbs, int index) {
    list[int] neighbors_eq = [];
    list[GenerationVerbConcretized] subchunk_current = [];
    list[GenerationVerbConcretized] subchunk_next = [];
    GenerationVerbConcretized verb_current = generation_verb_concretized_empty();
    GenerationVerbConcretized verb_next = generation_verb_concretized_empty();
    int i = -1;

    subchunk_current = concretized_verbs[index];
    if (subchunk_current == []) return neighbors_eq;

    i = index+1;
    if (i >= size(concretized_verbs)) return neighbors_eq;

    subchunk_next = concretized_verbs[i];
    verb_current = subchunk_current[0];
    verb_next = (subchunk_next != []) ? subchunk_next[0] : generation_verb_concretized_empty();
    while(i < size(concretized_verbs) && (verb_next == verb_current || verb_next is generation_verb_concretized_empty)) {
        neighbors_eq += [i];
        i += 1;

        subchunk_next = concretized_verbs[i];
        verb_next = (subchunk_next != []) ? subchunk_next[0] : generation_verb_concretized_empty();;
    }

    return neighbors_eq;
}

/******************************************************************************/
// --- Public concretize win functions -----------------------------------------

/*
 * @Name:   concretize_win
 * @Desc:   Function that concretizes the verbs to be applied in a chunk. It 
 *          transforms a regular-like expresion such as [crawl+, climb+] to an
 *          specific sequence of verbs
 * @Param:  chunk  -> GenertionChunk to be concretized
 *          width  -> Chunk width
 *          height -> Chunk height
 * @Ret:    List of concretized verbs
 */
tuple[list[list[GenerationVerbConcretized]], map[int,Coords]] concretize_win(GenerationModule \module, list[GenerationVerbExpression] verbs_abs, Coords entry, tuple[int,int] pattern_max_size, tuple[int,int] chunk_size) {
    map[int, Coords] position_current = ();
    for (int i <- [0..size(verbs_abs)]) position_current[i] = entry;
    
    tuple[list[list[GenerationVerbConcretized]] verbs_concretized, map[int, Coords] position_current] res = <[], position_current>;
    res = concretize_win_init(\module, verbs_abs, res.verbs_concretized, res.position_current);
    res = concretize_win_extend(\module, verbs_abs, res.verbs_concretized, res.position_current, pattern_max_size, chunk_size);
    res = concretize_concat(res.verbs_concretized, res.position_current);

    return <res.verbs_concretized, res.position_current>;
}

/*
 * @Name:   concretize_win_init
 * @Desc:   Function that concretizes the mandatory verbs to be applied in a 
 *          chunk
 * @Param:  verbs_abs        -> GenerationVerbExpressions to be concretized
 *          position_current -> Dictionary with the current positions
 * @Ret:    List of concretized verbs and updated position_current
 */
tuple[list[list[GenerationVerbConcretized]], map[int,Coords]] concretize_win_init(GenerationModule \module, list[GenerationVerbExpression] verbs_abs, list[list[GenerationVerbConcretized]] verbs_concretized, map[int, Coords] position_current) {
    for (int i <- [0..size(verbs_abs)]) {
        str verb_name = verbs_abs[i].verb;
        str verb_specification = verbs_abs[i].specification;
        str verb_modifier = verbs_abs[i].modifier;
        str verb_direction = (verbs_abs[i].direction != "_") ? verbs_abs[i].direction : generation_module_get_verb(\module, verb_name, verb_specification, "_").direction;

        list[GenerationVerbConcretized] basket = [];
        if (verb_modifier == "+" || verb_modifier == "") {
            GenerationVerbConcretized verb_concretized = generation_verb_concretized(verb_name, verb_specification, verb_direction);
            basket += [verb_concretized];
            position_current = concretize_update_position_current(position_current, i, verb_direction);
        }

        verbs_concretized += [basket];
    }

    return <verbs_concretized, position_current>;
}

/*
 * @Name:   concretize_win_extend
 * @Desc:   Function that concretizes all the verbs to be applied in a chunk
 *          (mandatory and non-mandatory)
 * @Param:  verbs_abs         -> GenerationVerbExpressions to be concretized
 *          verbs_concretized -> List of concretized verbs
 *          position_current  -> Dictionary with the current positions
 *          width             -> Chunk width
 *          height            -> Chunk height
 * @Ret:    List of concretized verbs and updated position_current
 */
tuple[list[list[GenerationVerbConcretized]], map[int,Coords]] concretize_win_extend(GenerationModule \module, list[GenerationVerbExpression] verbs_abs, list[list[GenerationVerbConcretized]] verbs_concretized, map[int,Coords] position_current, tuple[int,int] pattern_max_size, tuple[int,int] chunk_size) {
    int subchunk_num = size(verbs_abs);
    int subchunk_last_compulsory = max([i | int i <- [0..subchunk_num], verbs_abs[i].modifier == "+" || verbs_abs[i].modifier == ""] + [0]);

    bool subchunk_contains_end = concretize_contains_end(\module, verbs_abs);
    bool exited = false;
    while (!exited) {
        int i = arbInt(subchunk_num);

        str verb_name = verbs_abs[i].verb;
        str verb_specification = verbs_abs[i].specification;
        str verb_modifier = verbs_abs[i].modifier;
        VerbAnnotation verb = generation_module_get_verb(\module, verb_name, verb_specification, "_");
        str verb_direction = (verbs_abs[i].direction != "_") ? verbs_abs[i].direction : verb.direction;

        if(verb_modifier == "" 
           || (verb_modifier == "?" && size(verbs_concretized[i])== 1)) continue; 

        if (i < subchunk_last_compulsory
            && (concretize_check_future_position_exited(position_current, i, verb_direction, chunk_size)
                || !concretize_check_future_pattern_fit(position_current, i, pattern_max_size, verb_direction, chunk_size))) continue;
                
        position_current = concretize_update_position_current(position_current, i, verb_direction);
        exited = concretize_check_position_current_exited(position_current, i, chunk_size);
        if (!exited) {
            GenerationVerbConcretized verb_concretized = generation_verb_concretized(verb_name, verb_specification, verb_direction);
            verbs_concretized[i] += [verb_concretized];
        }

        if (subchunk_contains_end) exited = (arbInt(2) == 1);
    }

    tuple[list[list[GenerationVerbConcretized]], map[int,Coords]] res = <verbs_concretized, position_current>;
    if (!subchunk_contains_end) res = concretize_delete_unused(verbs_concretized, position_current, chunk_size);

    return res;
}

bool concretize_contains_end(GenerationModule \module, list[GenerationVerbExpression] verbs_abs) {
    for (GenerationVerbExpression v <- verbs_abs) {
        VerbAnnotation verb = generation_module_get_verb(\module, v.verb, v.specification, v.direction);
        if (verb_is_end(verb)) return true;
    }

    return false;
}

/******************************************************************************/
// --- Public concretize challenge functions ----------------------------------------

/*
 * @Name:   concretize_challenge
 * @Desc:   Function that concretized the challenge playtrace of a chunk. Intuitively
 *          it copies a part of the winning playtrace and extends another part 
 *          that is new
 * @Params: \module -> Module of the chunk
 *          challenge_verbs_abs -> Abstract list of challengeing verbs
 *          entry -> Entry coords to the chunk
 *          win_verbs_abs -> Abstract list of winning verbs
 *          win_verbs_concretized -> List of winning verbs concretized
 *          win_position_current -> Map with partial positions
 * @Ret:    Tuple with the list of concretized verbs and the map of partial 
 *          current positions
 */
tuple[list[list[GenerationVerbConcretized]], map[int,Coords]] concretize_challenge(GenerationModule \module, list[GenerationVerbExpression] challenge_verbs_abs,  Coords entry, list[GenerationVerbExpression] win_verbs_abs, list[list[GenerationVerbConcretized]] win_verbs_concretized, map[int, Coords] win_position_current) {
    tuple[list[list[GenerationVerbConcretized]] verbs_concretized, map[int, Coords] position_current] res = <[],()>;
    list[GenerationVerbExpression] challenge_verbs_abs_subpt = [];
    list[GenerationVerbExpression] challenge_verbs_abs_newpt = [];
    int newpt_index = -1;

    if (challenge_verbs_abs == []) return res;

    newpt_index = concretize_challenge_get_subplaytrace_index(challenge_verbs_abs, win_verbs_abs);
    if (newpt_index == -1) exception_playtraces_challenge_not_subplaytrace();

    list[list[GenerationVerbConcretized]] verbs_concretized = [[] | _ <- [0..(size(challenge_verbs_abs))]];
    map[int, Coords] position_current = ();
    for (int i <- [0..(size(challenge_verbs_abs))]) position_current[i] = entry;
    res = <verbs_concretized, position_current>;

    challenge_verbs_abs_subpt = challenge_verbs_abs[0..newpt_index];
    challenge_verbs_abs_newpt = challenge_verbs_abs[newpt_index..size(challenge_verbs_abs)];
    res = concretize_challenge_subplaytrace(challenge_verbs_abs_subpt, res.verbs_concretized, res.position_current, win_verbs_concretized, win_position_current);
    res = concretize_challenge_newplaytrace(\module, challenge_verbs_abs_newpt, res.verbs_concretized, res.position_current, newpt_index);
    res = concretize_concat(res.verbs_concretized, res.position_current);

    return <res.verbs_concretized, res.position_current>;
}   

/*
 * @Name:   concretize_challenge_subplaytrace
 * @Desc:   Function that concretizes the subplaytrace of the challengeing playtrace
 *          that is also part of the winning playtrace
 * @Params: challenge_verbs_abs         -> challengeing verbs part of the subplaytrace
 *          challenge_verbs_concretized -> Current list of challengeing verbs concretized
 *          challenge_position_current  -> Current map of partial current positions
 *          win_verbs_concretized  -> List of winning verbs concretized
 *          win_position_current   -> Map of win partial current positions
 * @Ret:    Tuple with list of challenge verbs concretized and position current updated
 */
tuple[list[list[GenerationVerbConcretized]], map[int, Coords]] concretize_challenge_subplaytrace(list[GenerationVerbExpression] challenge_verbs_abs, list[list[GenerationVerbConcretized]] challenge_verbs_concretized, map[int, Coords] challenge_position_current, list[list[GenerationVerbConcretized]] win_verbs_concretized, map[int, Coords] win_position_current) {
    int challenge_subchunk_subpt_num = size(challenge_verbs_abs);
    for (int i <- [0..challenge_subchunk_subpt_num]) {
        challenge_verbs_concretized[i] += win_verbs_concretized[i];
        challenge_position_current[i]  = win_position_current[i];
    }

    return <challenge_verbs_concretized, challenge_position_current>;
}

/*
 * @Name:   concretize_challenge_subplaytrace
 * @Desc:   Function that concretizes the subplaytrace of the challengeing playtrace
 *          that is also part of the winning playtrace. It first sets the initial
 *          position current of each of the corresponding subchunks to the value
 *          of the last position current of the subplaytrace and then includes
 *          the needed verbs
 * @Params: challenge_verbs_abs         -> challengeing verbs part of the subplaytrace
 *          challenge_verbs_concretized -> Current list of challengeing verbs concretized
 *          challenge_position_current  -> Current map of partial current positions
 *          win_verbs_concretized  -> List of winning verbs concretized
 *          win_position_current   -> Map of win partial current positions
 * @Ret:    Tuple with list of challenge verbs concretized and position current updated
 */
tuple[list[list[GenerationVerbConcretized]], map[int, Coords]] concretize_challenge_newplaytrace(GenerationModule \module, list[GenerationVerbExpression] challenge_verbs_abs, list[list[GenerationVerbConcretized]] challenge_verbs_concretized, map[int, Coords] challenge_position_current, int newpt_index) {
    for (int i <- [newpt_index..(size(challenge_verbs_abs)+newpt_index)]) {
        challenge_position_current[i] = challenge_position_current[newpt_index-1];
    }

    for (int i <- [0..size(challenge_verbs_abs)]) {
        str verb_name = challenge_verbs_abs[i].verb;
        str verb_specification = challenge_verbs_abs[i].specification;
        str verb_direction = (challenge_verbs_abs[i].direction != "_") ? challenge_verbs_abs[i].direction : generation_module_get_verb(\module, verb_name, verb_specification, "_").direction;
        str verb_modifier = challenge_verbs_abs[i].modifier;

        if (verb_modifier != "") exception_playtraces_challenge_non_specific_verb(verb_name, verb_modifier);

        GenerationVerbConcretized verb_concretized = generation_verb_concretized(verb_name, verb_specification, verb_direction);
        challenge_verbs_concretized[i + newpt_index] += [verb_concretized];
        challenge_position_current = concretize_update_position_current(challenge_position_current, i + newpt_index, verb_direction);
    }

    return <challenge_verbs_concretized, challenge_position_current>;
}

/*
 * @Name:   concretize_challenge_get_subplaytrace_index
 * @Desc:   Function that gets the index of when the subplaytrace of challengeing
 *          abstract verbs ends with respect to the winning abstract verbs
 * @Params: challenge_verbs_abs -> challengeing verbs abstract
 *          win_verbs_abs  -> Winning verbs abstract 
 */
int concretize_challenge_get_subplaytrace_index(list[GenerationVerbExpression] challenge_verbs_abs, list[GenerationVerbExpression] win_verbs_abs) {
    for (int i <- [0..size(win_verbs_abs)]) {
        if(win_verbs_abs[i].verb != challenge_verbs_abs[i].verb
           || (win_verbs_abs[i].verb == challenge_verbs_abs[i].verb 
               && win_verbs_abs[i].specification != challenge_verbs_abs[i].specification)
           || (win_verbs_abs[i].verb == challenge_verbs_abs[i].verb 
               && win_verbs_abs[i].specification == challenge_verbs_abs[i].specification
               && win_verbs_abs[i].direction != challenge_verbs_abs[i].direction)) return i;
    }
    return -1;
}