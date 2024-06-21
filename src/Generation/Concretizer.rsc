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
import Generation::ADT::VerbExpression;
import Generation::ADT::Chunk;


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
list[list[str]] concretize(list[GenerationVerbExpression] verbs, int width, int height) {
    list[list[str]] verbs_concretized = [];
    
    Coords position_init = <0, toInt(height/2)>;
    map[int, Coords] position_current = ();
    for (int i <- [0..size(verbs)]) position_current[i] = position_init;
    
    tuple[list[list[str]] verbs_concretized, map[int, Coords] position_current] res = <[], ()>;
    res = concretize_init(verbs, position_current);
    res = concretize_extend(verbs, res.verbs_concretized, res.position_current, width, height);

    return res.verbs_concretized;
}

/*
 * @Name:   concretize_init
 * @Desc:   Function that concretizes the mandatory verbs to be applied in a 
 *          chunk
 * @Param:  verbs  -> GenerationVerbExpressions to be concretized
 *          position_current -> Dictionary with the current positions
 * @Ret:    List of concretized verbs and updated position_current
 */
tuple[list[list[str]], map[int,Coords]] concretize_init(list[GenerationVerbExpression] verbs, map[int, Coords] position_current) {
    list[list[str]] verbs_concretized = [];

    int subchunk_num = size(verbs);

    for (int i <- [0..subchunk_num]) {
        str verb = verbs[i].verb;
        str modifier = verbs[i].modifier;

        list[str] basket = [];
        if (modifier == "+") basket += [verb];

        if      (verb == "climb") position_current = concretize_update_position_current_up(position_current, i);
        else if (verb == "crawl") position_current = concretize_update_position_current_right(position_current, i);
        else if (verb == "fall" ) position_current = concretize_update_position_current_down(position_current, i);

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
tuple[list[list[str]], map[int,Coords]] concretize_extend(list[GenerationVerbExpression] verbs, list[list[str]] verbs_concretized, map[int,Coords] position_current, int width, int height) {
    int subchunk_num = size(verbs);
    int subchunk_last_compulsory = max([i | int i <- [0..subchunk_num], verbs[i].modifier == "+"]);

    bool exited = false;
    while (!exited) {
        int i = arbInt(subchunk_num);
        str verb = verbs[i].verb;

        if      (i < subchunk_last_compulsory
                && verb == "climb" 
                && concretize_check_future_position_exited_up(position_current, i, width, height))    continue;
        else if (i < subchunk_last_compulsory 
                && verb == "crawl" 
                && concretize_check_future_position_exited_right(position_current, i, width, height)) continue;
        else if (i < subchunk_last_compulsory 
                && verb == "fall"  
                && concretize_check_future_position_exited_down(position_current, i, width, height))  continue;
                
        verbs_concretized[i] += [verb];

        if (verb == "climb") position_current = concretize_update_position_current_up(position_current, i);
        else if (verb == "crawl") position_current = concretize_update_position_current_right(position_current, i);
        else if (verb == "fall" ) position_current = concretize_update_position_current_down(position_current, i);

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
        if (direction == "up"    && position_current[i].y+1 == height) return true;
        if (direction == "right" && position_current[i].x+1 == width ) return true;
        if (direction == "down"  && position_current[i].y-1 == 0     ) return true;
    }
    return false;
}

/*
 * @Name:   concretize_check_future_position_exited_up
 * @Desc:   Function that checks if the future position to add (up) will make us 
 *          exit from the chunk. It calls concretize_check_future_position_exited
 * @Param:  position_current  -> Dictionary with the current positions
 *          index             -> Index of the verb's subchunk to include
 *          width             -> Chunk width
 *          height            -> Chunk height
 * @Ret:    Boolean indicating if we exit or not
 */
bool concretize_check_future_position_exited_up(map[int keys, Coords coords] position_current, int index, int width, int height) {
    return concretize_check_future_position_exited(position_current, index, "up", width, height);
}

/*
 * @Name:   concretize_check_future_position_exited_up
 * @Desc:   Function that checks if the future position to add (right) will make us 
 *          exit from the chunk. It calls concretize_check_future_position_exited
 * @Param:  position_current  -> Dictionary with the current positions
 *          index             -> Index of the verb's subchunk to include
 *          width             -> Chunk width
 *          height            -> Chunk height
 * @Ret:    Boolean indicating if we exit or not
 */
bool concretize_check_future_position_exited_right(map[int keys, Coords coords] position_current, int index, int width, int height) {
    return concretize_check_future_position_exited(position_current, index, "right", width, height);
}

/*
 * @Name:   concretize_check_future_position_exited_up
 * @Desc:   Function that checks if the future position to add (down) will make us 
 *          exit from the chunk. It calls concretize_check_future_position_exited
 * @Param:  position_current  -> Dictionary with the current positions
 *          index             -> Index of the verb's subchunk to include
 *          width             -> Chunk width
 *          height            -> Chunk height
 * @Ret:    Boolean indicating if we exit or not
 */
bool concretize_check_future_position_exited_down(map[int keys, Coords coords] position_current, int index, int width, int height) {
    return concretize_check_future_position_exited(position_current, index, "down", width, height);
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
        if      (direction == "up")    position_current[i].y += 1;
        else if (direction == "right") position_current[i].x += 1;
        else if (direction == "down")  position_current[i].y -= 1;
    }

    return position_current;
}

/*
 * @Name:   concretize_update_position_current
 * @Desc:   Function that updates the position current after adding one more 
 *          concrete verb (up). It calls concretize_update_position_current
 * @Param:  position_current  -> Dictionary with the current positions
 *          index             -> Index of the verb's subchunk to include
 * @Ret:    Updated position current
 */
map[int, Coords] concretize_update_position_current_up(map[int keys, Coords coords] position_current, int index) {
    return concretize_update_position_current(position_current, index, "up");
}

/*
 * @Name:   concretize_update_position_current
 * @Desc:   Function that updates the position current after adding one more 
 *          concrete verb (right). It calls concretize_update_position_current
 * @Param:  position_current  -> Dictionary with the current positions
 *          index             -> Index of the verb's subchunk to include
 * @Ret:    Updated position current
 */
map[int, Coords] concretize_update_position_current_right(map[int keys, Coords coords] position_current, int index) {
    return concretize_update_position_current(position_current, index, "right");
}

/*
 * @Name:   concretize_update_position_current
 * @Desc:   Function that updates the position current after adding one more 
 *          concrete verb (down). It calls concretize_update_position_current
 * @Param:  position_current  -> Dictionary with the current positions
 *          index             -> Index of the verb's subchunk to include
 * @Ret:    Updated position current
 */
map[int, Coords] concretize_update_position_current_down(map[int keys, Coords coords] position_current, int index) {
    return concretize_update_position_current(position_current, index, "down");
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
        if (position_current[i].x == width 
            || position_current[i].y == height 
            || position_current[i].y == -1) return true;
    }
    return false;
}