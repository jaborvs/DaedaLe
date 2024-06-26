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
import Generation::ADT::VerbExpression;
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
 * @Ret:    Tuple with the winning and failing playtraces
 */
tuple[tuple[list[list[str]], Coords], tuple[list[list[str]], Coords]] concretize(GenerationModule \module, GenerationChunk chunk, Coords entry, int width, int height) {
    tuple[list[list[str]] verbs, map[int,Coords] position_current] win_concretized = <[], ()>;
    tuple[list[list[str]] verbs, map[int,Coords] position_current] fail_concretized = <[], ()>;

    win_concretized = concretize_win(
        \module, 
        chunk.win_verbs, 
        entry, 
        width, 
        height
        );
    Coords exit = win_concretized.position_current[size(win_concretized.verbs)-1];

    fail_concretized = concretize_fail(
        \module, 
        chunk.fail_verbs, 
        entry, 
        chunk.win_verbs, 
        win_concretized.verbs, 
        win_concretized.position_current
        );
    Coords dead_end = (size(fail_concretized.verbs)-1 in fail_concretized.position_current) ? fail_concretized.position_current[size(fail_concretized.verbs)-1] : <-1,-1>;

    return <
        <win_concretized.verbs, exit>,
        <fail_concretized.verbs, dead_end>
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

/*
 * @Name:   concretize_delete_unused
 * @Desc:   Function that deletes those verbs that are after the chunk exit
 * @Param:  verbs_concretized -> List of concretized verbs
 *          position_current  -> Dictionary with the current positions
 *          width             -> Chunk width
 *          height            -> Chunk height
 * @Ret:    List of concretized verbs and updated position_current
 */
tuple[list[list[str]], map[int,Coords]] concretize_delete_unused(list[list[str]] verbs_concretized, map[int keys, Coords coords] position_current, int width, int height) {
    int exit_num = min(
        [i | int i <- [0..size(position_current.keys)], 
             position_current[i].y == -1 
             || position_current[i].x == width 
             || position_current[i].y == height
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
tuple[list[list[str]], map[int,Coords]] concretize_concat(list[list[str]] concretized_verbs, map[int, Coords] position_current) {
    list[list[str]] concretized_verbs_concated = [];
    map[int, Coords] position_current_concated = ();

    int i = 0;
    int subchunk_num = 0;
    while(i < size(concretized_verbs)) {
        list[str] subchunk = concretized_verbs[i];
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
list[int] concretize_get_neighbors_equivalent(list[list[str]] concretized_verbs, int index) {
    list[int] neighbors_eq = [];
    list[str] subchunk_current = [];
    list[str] subchunk_next = [];
    str verb_current = "";
    str verb_next = "";
    int i = -1;

    subchunk_current = concretized_verbs[index];
    if (subchunk_current == []) return neighbors_eq;

    i = index+1;
    if (i >= size(concretized_verbs)) return neighbors_eq;

    subchunk_next = concretized_verbs[i];
    verb_current = subchunk_current[0];
    verb_next = (subchunk_next != []) ? subchunk_next[0] : "";
    while(i < size(concretized_verbs) && (verb_next == verb_current || verb_next == "")) {
        neighbors_eq += [i];
        i += 1;

        subchunk_next = concretized_verbs[i];
        verb_next = (subchunk_next != []) ? subchunk_next[0] : "";
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
tuple[list[list[str]], map[int,Coords]] concretize_win(GenerationModule \module, list[GenerationVerbExpression] verbs, Coords entry, int width, int height) {
    map[int, Coords] position_current = ();
    for (int i <- [0..size(verbs)]) position_current[i] = entry;
    
    tuple[list[list[str]] verbs_concretized, map[int, Coords] position_current] res = <[], position_current>;
    res = concretize_win_init(\module, verbs, res.position_current);
    res = concretize_win_extend(\module, verbs, res.verbs_concretized, res.position_current, width, height);
    res = concretize_concat(res.verbs_concretized, res.position_current);

    return <res.verbs_concretized, res.position_current>;
}

/*
 * @Name:   concretize_win_init
 * @Desc:   Function that concretizes the mandatory verbs to be applied in a 
 *          chunk
 * @Param:  verbs  -> GenerationVerbExpressions to be concretized
 *          position_current -> Dictionary with the current positions
 * @Ret:    List of concretized verbs and updated position_current
 */
tuple[list[list[str]], map[int,Coords]] concretize_win_init(GenerationModule \module, list[GenerationVerbExpression] verbs, map[int, Coords] position_current) {
    list[list[str]] verbs_concretized = [];

    int subchunk_num = size(verbs);

    for (int i <- [0..subchunk_num]) {
        str verb_name = verbs[i].verb;
        str verb_modifier = verbs[i].modifier;
        VerbAnnotation verb = generation_module_get_verb(\module, verb_name, "_");

        list[str] basket = [];
        if (verb_modifier == "+" || verb_modifier == "") {
            basket += [verb_name];
            position_current = concretize_update_position_current(position_current, i, verb.direction);
        }

        verbs_concretized += [basket];
    }

    return <verbs_concretized, position_current>;
}

/*
 * @Name:   concretize_win_extend
 * @Desc:   Function that concretizes all the verbs to be applied in a chunk
 *          (mandatory and non-mandatory)
 * @Param:  verbs             -> GenerationVerbExpressions to be concretized
 *          verbs_concretized -> List of concretized verbs
 *          position_current  -> Dictionary with the current positions
 *          width             -> Chunk width
 *          height            -> Chunk height
 * @Ret:    List of concretized verbs and updated position_current
 */
tuple[list[list[str]], map[int,Coords]] concretize_win_extend(GenerationModule \module, list[GenerationVerbExpression] verbs, list[list[str]] verbs_concretized, map[int,Coords] position_current, int width, int height) {
    int subchunk_num = size(verbs);
    int subchunk_last_compulsory = max([i | int i <- [0..subchunk_num], verbs[i].modifier == "+" || verbs[i].modifier == ""] + [0]);

    bool exited = false;
    while (!exited) {
        int i = arbInt(subchunk_num);
        str verb_name = verbs[i].verb;

        if(verbs[i].modifier == "" 
           || (verbs[i].modifier == "?" && size(verbs_concretized[i])== 1)) continue; 

        VerbAnnotation verb = generation_module_get_verb(\module, verb_name, "_");

        if (i < subchunk_last_compulsory
            && concretize_check_future_position_exited(position_current, i, verb.direction, width, height)) continue;
                
        verbs_concretized[i] += [verb_name];
        position_current = concretize_update_position_current(position_current, i, verb.direction);
        exited = concretize_check_position_current_exited(position_current, i, width, height);
    }

    return concretize_delete_unused(verbs_concretized, position_current, width, height);
}

/******************************************************************************/
// --- Public concretize fail functions ----------------------------------------

/*
 * @Name:   concretize_fail
 * @Desc:   Function that concretized the fail playtrace of a chunk. Intuitively
 *          it copies a part of the winning playtrace and extends another part 
 *          that is new
 * @Params: \module -> Module of the chunk
 *          fail_verbs_abs -> Abstract list of failing verbs
 *          entry -> Entry coords to the chunk
 *          win_verbs_abs -> Abstract list of winning verbs
 *          win_verbs_concretized -> List of winning verbs concretized
 *          win_position_current -> Map with partial positions
 * @Ret:    Tuple with the list of concretized verbs and the map of partial 
 *          current positions
 */
tuple[list[list[str]], map[int,Coords]] concretize_fail(GenerationModule \module, list[GenerationVerbExpression] fail_verbs_abs,  Coords entry, list[GenerationVerbExpression] win_verbs_abs, list[list[str]] win_verbs_concretized, map[int, Coords] win_position_current) {
    tuple[list[list[str]] verbs_concretized, map[int, Coords] position_current] res = <[],()>;
    list[GenerationVerbExpression] fail_verbs_abs_subpt = [];
    list[GenerationVerbExpression] fail_verbs_abs_newpt = [];
    int newpt_index = -1;

    if (fail_verbs_abs == []) return res;

    newpt_index = concretize_fail_get_subplaytrace_index(fail_verbs_abs, win_verbs_abs);
    if (newpt_index == -1) exception_playtraces_fail_not_subplaytrace();

    list[list[str]] verbs_concretized = [[] | _ <- [0..(size(fail_verbs_abs))]];
    map[int, Coords] position_current = ();
    for (int i <- [0..(size(fail_verbs_abs))]) position_current[i] = entry;
    res = <verbs_concretized, position_current>;

    fail_verbs_abs_subpt = fail_verbs_abs[0..newpt_index];
    fail_verbs_abs_newpt = fail_verbs_abs[newpt_index..size(fail_verbs_abs)];
    res = concretize_fail_subplaytrace(fail_verbs_abs_subpt, res.verbs_concretized, res.position_current, win_verbs_concretized, win_position_current);
    res = concretize_fail_newplaytrace(\module, fail_verbs_abs_newpt, res.verbs_concretized, res.position_current, newpt_index);
    res = concretize_concat(res.verbs_concretized, res.position_current);

    return <res.verbs_concretized, res.position_current>;
}   

/*
 * @Name:   concretize_fail_subplaytrace
 * @Desc:   Function that concretizes the subplaytrace of the failing playtrace
 *          that is also part of the winning playtrace
 * @Params: fail_verbs_abs         -> Failing verbs part of the subplaytrace
 *          fail_verbs_concretized -> Current list of failing verbs concretized
 *          fail_position_current  -> Current map of partial current positions
 *          win_verbs_concretized  -> List of winning verbs concretized
 *          win_position_current   -> Map of win partial current positions
 * @Ret:    Tuple with list of fail verbs concretized and position current updated
 */
tuple[list[list[str]], map[int, Coords]] concretize_fail_subplaytrace(list[GenerationVerbExpression] fail_verbs_abs, list[list[str]] fail_verbs_concretized, map[int, Coords] fail_position_current, list[list[str]] win_verbs_concretized, map[int, Coords] win_position_current) {
    int fail_subchunk_subpt_num = size(fail_verbs_abs);
    for (int i <- [0..fail_subchunk_subpt_num]) {
        fail_verbs_concretized[i] += win_verbs_concretized[i];
        fail_position_current[i]  = win_position_current[i];
    }

    return <fail_verbs_concretized, fail_position_current>;
}

/*
 * @Name:   concretize_fail_subplaytrace
 * @Desc:   Function that concretizes the subplaytrace of the failing playtrace
 *          that is also part of the winning playtrace. It first sets the initial
 *          position current of each of the corresponding subchunks to the value
 *          of the last position current of the subplaytrace and then includes
 *          the needed verbs
 * @Params: fail_verbs_abs         -> Failing verbs part of the subplaytrace
 *          fail_verbs_concretized -> Current list of failing verbs concretized
 *          fail_position_current  -> Current map of partial current positions
 *          win_verbs_concretized  -> List of winning verbs concretized
 *          win_position_current   -> Map of win partial current positions
 * @Ret:    Tuple with list of fail verbs concretized and position current updated
 */
tuple[list[list[str]], map[int, Coords]] concretize_fail_newplaytrace(GenerationModule \module, list[GenerationVerbExpression] fail_verbs_abs, list[list[str]] fail_verbs_concretized, map[int, Coords] fail_position_current, int newpt_index) {
    for (int i <- [newpt_index..(size(fail_verbs_abs)+newpt_index)]) {
        fail_position_current[i] = fail_position_current[newpt_index-1];
    }

    for (int i <- [0..size(fail_verbs_abs)]) {
        str verb_name = fail_verbs_abs[i].verb;
        str verb_modifier = fail_verbs_abs[i].modifier;

        if (verb_modifier != "") exception_playtraces_fail_non_specific_verb(verb_name, verb_modifier);

        VerbAnnotation verb = generation_module_get_verb(\module, verb_name, "_");

        fail_verbs_concretized[i + newpt_index] += [verb_name];
        fail_position_current = concretize_update_position_current(fail_position_current, i + newpt_index, verb.direction);
    }

    return <fail_verbs_concretized, fail_position_current>;
}

/*
 * @Name:   concretize_fail_get_subplaytrace_index
 * @Desc:   Function that gets the index of when the subplaytrace of failing
 *          abstract verbs ends with respect to the winning abstract verbs
 * @Params: fail_verbs_abs -> Failing verbs abstract
 *          win_verbs_abs  -> Winning verbs abstract 
 */
int concretize_fail_get_subplaytrace_index(list[GenerationVerbExpression] fail_verbs_abs, list[GenerationVerbExpression] win_verbs_abs) {
    for (int i <- [0..size(win_verbs_abs)]) {
        if(win_verbs_abs[i].verb != fail_verbs_abs[i].verb) return i;
    }
    return -1;
}