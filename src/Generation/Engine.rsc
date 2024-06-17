/*
 * @Module: Engine
 * @Desc:   Module that includes all the functionality to generate the desired 
 *          tutorial levels
 * @Auth:   Borja Velasco -> code, comments
 */
module Generation::Engine

/******************************************************************************/
// --- General modules imports -------------------------------------------------
import util::Math;
import List;
import Set;
import IO;

/******************************************************************************/
// --- Own modules imports -----------------------------------------------------
import Generation::Compiler;
import Extension::AST;
import Utils;

/******************************************************************************/
// --- Public Generation Functions ---------------------------------------------

/*
 * @Name:   generate
 * @Desc:   Function that generates all the specified levels
 * @Params: engine -> Generation engine
 * @Ret:    list[list[str]] given that a level is a list[str] and we are
 *          returning all levels generated
 */
list[list[str]] generate(GenerationEngine engine) {
    list[list[str]] levels_generated = [];
    levels_generated = _generate_levels(engine);

    return levels_generated;
}

/******************************************************************************/
// --- Private Generation Functions --------------------------------------------

/*
 * @Name:   _generate_levels
 * @Desc:   Function that generates all the specified levels
 * @Params: 
 * @Ret:    list[list[str]] given that a level is a list[str] and we are
 *          returning all levels generated
 */
list[list[str]] _generate_levels(GenerationEngine engine) {
    list[list[str]] levels_generated = [_generate_level(engine, engine.generated_levels[name]) | str name <- engine.generated_levels.names];
    return levels_generated;
}

/*
 * @Name:   _generate_level
 * @Desc:   Function that generates a single level from a given draft
 * @Params: 
 * @Ret:    list[list[str]] given that a level is a list[str] and we are
 *          returning all levels generated
 */
list[str] _generate_level(GenerationEngine engine, GenerationLevel level) {
    // list[GenerationChunk] chunks_generated =  [_generate_chunk(engine, chunk) | GenerationChunk chunk <- level.chunks];
    // return chunks_generated;
    list[list[str]] chunks_generated =  [_generate_chunk(engine, chunk) | GenerationChunk chunk <- level.chunks];
    return [];
}

/*
 * @Name:   _generate_chunk
 * @Desc:   Function that generates a chunk from a given chunk data
 * @Params:
 * @Ret:    Generated chunk object
 */
list[str] _generate_chunk(GenerationEngine engine, GenerationChunk chunk) {
    list[list[str]] verbs_concretized = _verbs_concretize(chunk.verbs, engine.config.width, engine.config.height);
    list[Verb] verbs_translated       = _verbs_translate(engine.modules[chunk.\module], verbs_concretized);

    chunk = _apply_generation_rules(engine, chunk, verbs_concretized);

    return verbs_concretized;
}

/******************************************************************************/
// --- Private Apply Functions -------------------------------------------------

// GenerationChunk _apply_generation_rules(GenerationEngine engine, GenerationChunk chunk, list[str] verbs_concretized) {

// }

/******************************************************************************/
// --- Private Verbs Functions -------------------------------------------------

list[Verb] _verbs_translate(GenerationModule \module, list[list[str]] verbs_concretized) {
    return [];
}

/*
 * @Name:   _verbs_concretize
 * @Desc:   Function that concretizes the verbs to be applied in a chunk. It 
 *          transforms a regular-like expresion such as [crawl+, climb+] to an
 *          specific sequence of verbs
 * @Param:  chunk  -> GenertionChunk to be concretized
 *          width  -> Chunk width
 *          height -> Chunk height
 * @Ret:    List of concretized verbs
 */
list[list[str]] _verbs_concretize(GenerationVerbExpression verbs, int width, int height) {
    list[list[str]] verbs_concretized = [];
    
    Coords position_init = <0, toInt(height/2)>;
    map[int, Coords] position_current = ();
    for (int i <- [0..size(verbs)]) position_current[i] = position_init;
    
    tuple[list[list[str]] verbs_concretized, map[int, Coords] position_current] res = <[], ()>;
    res = _verbs_concretize_init(verbs, position_current);
    res = _verbs_concretize_extend(verbs, res.verbs_concretized, res.position_current, width, height);

    return res.verbs_concretized;
}

/*
 * @Name:   _verbs_concretize_init
 * @Desc:   Function that concretizes the mandatory verbs to be applied in a 
 *          chunk
 * @Param:  verbs  -> GenerationVerbExpressions to be concretized
 *          position_current -> Dictionary with the current positions
 * @Ret:    List of concretized verbs and updated position_current
 */
tuple[list[list[str]], map[int,Coords]] _verbs_concretize_init(list[GenerationVerbExpression] verbs, map[int, Coords] position_current) {
    list[list[str]] verbs_concretized = [];

    int subchunk_num = size(verbs);

    for (int i <- [0..subchunk_num]) {
        str verb = verbs[i].verb;
        str modifier = verbs[i].modifier;

        list[str] basket = [];
        if (modifier == "+") basket += [verb];

        if      (verb == "climb") position_current = _verbs_concretize_update_position_current_up(position_current, i);
        else if (verb == "crawl") position_current = _verbs_concretize_update_position_current_right(position_current, i);
        else if (verb == "fall" ) position_current = _verbs_concretize_update_position_current_down(position_current, i);

        verbs_concretized += [basket];
    }

    return <verbs_concretized, position_current>;
}

/*
 * @Name:   _verbs_concretize_extend
 * @Desc:   Function that concretizes all the verbs to be applied in a chunk
 *          (mandatory and non-mandatory)
 * @Param:  verbs             -> GenerationVerbExpressions to be concretized
 *          verbs_concretized -> List of concretized verbs
 *          position_current  -> Dictionary with the current positions
 *          width             -> Chunk width
 *          height            -> Chunk height
 * @Ret:    List of concretized verbs and updated position_current
 */
tuple[list[list[str]], map[int,Coords]] _verbs_concretize_extend(list[GenerationVerbExpression] verbs, list[list[str]] verbs_concretized, map[int,Coords] position_current, int width, int height) {
    int subchunk_num = size(verbs);
    int subchunk_last_compulsory = max([i | int i <- [0..subchunk_num], verbs[i].modifier == "+"]);

    bool exited = false;
    while (!exited) {
        int i = arbInt(subchunk_num);
        str verb = verbs[i].verb;

        if      (i < subchunk_last_compulsory
                && verb == "climb" 
                && _verbs_concretize_check_future_position_exited_up(position_current, i, width, height))    continue;
        else if (i < subchunk_last_compulsory 
                && verb == "crawl" 
                && _verbs_concretize_check_future_position_exited_right(position_current, i, width, height)) continue;
        else if (i < subchunk_last_compulsory 
                && verb == "fall"  
                && _verbs_concretize_check_future_position_exited_down(position_current, i, width, height))  continue;
                
        verbs_concretized[i] += [verb];

        if (verb == "climb") position_current = _verbs_concretize_update_position_current_up(position_current, i);
        else if (verb == "crawl") position_current = _verbs_concretize_update_position_current_right(position_current, i);
        else if (verb == "fall" ) position_current = _verbs_concretize_update_position_current_down(position_current, i);

        exited = _verbs_concretize_check_position_current_exited(position_current, i, width, height);
    }

    return <verbs_concretized, position_current>;
}

/*
 * @Name:   _verbs_concretize_check_future_position_exited
 * @Desc:   Function that checks if the future position to add will make us 
 *          exit from the chunk
 * @Param:  position_current  -> Dictionary with the current positions
 *          index             -> Index of the verb's subchunk to include
 *          direction         -> Direction of the verb
 *          width             -> Chunk width
 *          height            -> Chunk height
 * @Ret:    Boolean indicating if we exit or not
 */
bool _verbs_concretize_check_future_position_exited(map[int keys, Coords coords] position_current, int index, str direction, int width, int height) {
    for(int i <- [index..size(position_current.keys)]) {
        if (direction == "up"    && position_current[i].y+1 == height) return true;
        if (direction == "right" && position_current[i].x+1 == width ) return true;
        if (direction == "down"  && position_current[i].y-1 == 0     ) return true;
    }
    return false;
}

/*
 * @Name:   _verbs_concretize_check_future_position_exited_up
 * @Desc:   Function that checks if the future position to add (up) will make us 
 *          exit from the chunk. It calls _verbs_concretize_check_future_position_exited
 * @Param:  position_current  -> Dictionary with the current positions
 *          index             -> Index of the verb's subchunk to include
 *          width             -> Chunk width
 *          height            -> Chunk height
 * @Ret:    Boolean indicating if we exit or not
 */
bool _verbs_concretize_check_future_position_exited_up(map[int keys, Coords coords] position_current, int index, int width, int height) {
    return _verbs_concretize_check_future_position_exited(position_current, index, "up", width, height);
}

/*
 * @Name:   _verbs_concretize_check_future_position_exited_up
 * @Desc:   Function that checks if the future position to add (right) will make us 
 *          exit from the chunk. It calls _verbs_concretize_check_future_position_exited
 * @Param:  position_current  -> Dictionary with the current positions
 *          index             -> Index of the verb's subchunk to include
 *          width             -> Chunk width
 *          height            -> Chunk height
 * @Ret:    Boolean indicating if we exit or not
 */
bool _verbs_concretize_check_future_position_exited_right(map[int keys, Coords coords] position_current, int index, int width, int height) {
    return _verbs_concretize_check_future_position_exited(position_current, index, "right", width, height);
}

/*
 * @Name:   _verbs_concretize_check_future_position_exited_up
 * @Desc:   Function that checks if the future position to add (down) will make us 
 *          exit from the chunk. It calls _verbs_concretize_check_future_position_exited
 * @Param:  position_current  -> Dictionary with the current positions
 *          index             -> Index of the verb's subchunk to include
 *          width             -> Chunk width
 *          height            -> Chunk height
 * @Ret:    Boolean indicating if we exit or not
 */
bool _verbs_concretize_check_future_position_exited_down(map[int keys, Coords coords] position_current, int index, int width, int height) {
    return _verbs_concretize_check_future_position_exited(position_current, index, "down", width, height);
}

/*
 * @Name:   _verbs_concretize_update_position_current
 * @Desc:   Function that updates the position current after adding one more 
 *          concrete verb
 * @Param:  position_current  -> Dictionary with the current positions
 *          index             -> Index of the verb's subchunk to include
 *          direction         -> Direction of the verb
 * @Ret:    Updated position current
 */
map[int, Coords] _verbs_concretize_update_position_current(map[int keys, Coords coords] position_current, int index, str direction) {
    for(int i <- [index..size(position_current.keys)]) {
        if      (direction == "up")    position_current[i].y += 1;
        else if (direction == "right") position_current[i].x += 1;
        else if (direction == "down")  position_current[i].y -= 1;
    }

    return position_current;
}

/*
 * @Name:   _verbs_concretize_update_position_current
 * @Desc:   Function that updates the position current after adding one more 
 *          concrete verb (up). It calls _verbs_concretize_update_position_current
 * @Param:  position_current  -> Dictionary with the current positions
 *          index             -> Index of the verb's subchunk to include
 * @Ret:    Updated position current
 */
map[int, Coords] _verbs_concretize_update_position_current_up(map[int keys, Coords coords] position_current, int index) {
    return _verbs_concretize_update_position_current(position_current, index, "up");
}

/*
 * @Name:   _verbs_concretize_update_position_current
 * @Desc:   Function that updates the position current after adding one more 
 *          concrete verb (right). It calls _verbs_concretize_update_position_current
 * @Param:  position_current  -> Dictionary with the current positions
 *          index             -> Index of the verb's subchunk to include
 * @Ret:    Updated position current
 */
map[int, Coords] _verbs_concretize_update_position_current_right(map[int keys, Coords coords] position_current, int index) {
    return _verbs_concretize_update_position_current(position_current, index, "right");
}

/*
 * @Name:   _verbs_concretize_update_position_current
 * @Desc:   Function that updates the position current after adding one more 
 *          concrete verb (down). It calls _verbs_concretize_update_position_current
 * @Param:  position_current  -> Dictionary with the current positions
 *          index             -> Index of the verb's subchunk to include
 * @Ret:    Updated position current
 */
map[int, Coords] _verbs_concretize_update_position_current_down(map[int keys, Coords coords] position_current, int index) {
    return _verbs_concretize_update_position_current(position_current, index, "down");
}

/*
 * @Name:   _verbs_concretize_check_position_current_exited
 * @Desc:   Function that checks if the last verb included made us exit from 
 *          the chunk
 * @Param:  position_current  -> Dictionary with the current positions
 *          index             -> Index of the verb's subchunk to include
 *          width             -> Chunk width
 *          height            -> Chunk height
 * @Ret:    Updated position current
 */
bool _verbs_concretize_check_position_current_exited(map[int keys, Coords coords] position_current, int index, int width, int height) {
    for(int i <- [index..size(position_current.keys)]) {
        if (position_current[i].x == width 
            || position_current[i].y == height 
            || position_current[i].y == -1) return true;
    }
    return false;
}

