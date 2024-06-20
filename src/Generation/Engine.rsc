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
import util::Eval;
import List;
import Set;
import IO;

/******************************************************************************/
// --- Own modules imports -----------------------------------------------------
import Generation::Compiler;
import Generation::Match;
import Extension::Verb;
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
    list[GenerationChunk] chunks_generated =  [_generate_chunk(engine, chunk) | GenerationChunk chunk <- level.chunks];
    return [];
}

/*
 * @Name:   _generate_chunk
 * @Desc:   Function that generates a chunk from a given chunk data
 * @Params:
 * @Ret:    Generated chunk object
 */
GenerationChunk _generate_chunk(GenerationEngine engine, GenerationChunk chunk) {
    list[list[str]] verbs_concretized = _verbs_concretize(chunk.verbs, engine.config.width, engine.config.height);
    list[Verb] verbs_translated       = _verbs_translate(engine.modules[chunk.\module], verbs_concretized);

    Coords player_coords = <0,4>;
    chunk.objects[engine.config.width * player_coords.y + player_coords.x]     = "ph1";
    chunk.objects[engine.config.width * (player_coords.y+1) + player_coords.x] = "#";
    chunk = _apply_generation_rules(engine, chunk, verbs_translated);

    return chunk;
}

/******************************************************************************/
// --- Private Apply Functions -------------------------------------------------

GenerationChunk _apply_generation_rules(GenerationEngine engine, GenerationChunk chunk, list[Verb] verbs) {
    println("\>\>\> Chunk inicial:");
    chunk_print(chunk, engine.config.width);

    for (Verb verb <- verbs) {
        chunk = _apply_generation_rule(engine, chunk, verb);
        println("\>\>\> Aplicamos <verb.name>_<verb.specification>:");
        chunk_print(chunk, engine.config.width);
    }

    return chunk;
}

void chunk_print(GenerationChunk chunk, int width) {
    str chunk_printed = "";

    int i = 0;
    for (str object <- chunk.objects) {
        chunk_printed += object;
        chunk_printed += "\t";
        i += 1;

        if (i % width == 0) chunk_printed += "\n";
    }
    
    print(chunk_printed);
    return;
}

GenerationChunk _apply_generation_rule(GenerationEngine engine, GenerationChunk chunk, Verb verb) {
    str program = "";

    GenerationRule rule = engine.modules[chunk.\module].generation_rules[verb];
    GenerationPattern left = engine.patterns[rule.left];
    GenerationPattern right = engine.patterns[rule.right];

    program = match_generate_program(chunk, engine.config.width, verb, left, right);
    if(result(GenerationChunk chunk_rewritten) := eval(program)) {
        chunk = chunk_rewritten;
    }

    return chunk;
}

/******************************************************************************/
// --- Private Verbs Functions -------------------------------------------------


list[Verb] _verbs_translate(GenerationModule \module, list[list[str]] verbs_concretized) {
    list[Verb] verbs_translated = [];

    int subchunks_num = size(verbs_concretized);
    for (int i <- [0..subchunks_num]) {
        list[str] subchunk = verbs_concretized[i];
        tuple[list[Verb] verbs_translated, int subchunk_size] res = <[],size(subchunk)>;

        str verb_prev_name = (verbs_translated != []) ? verbs_translated[-1].name : "";
        str verb_prev_specification = (verbs_translated != []) ? verbs_translated[-1].specification : "";

        str verb_next_name = (i+1 < subchunks_num) ? verbs_concretized[i+1][0] : "";
        str verb_next_specification = (i+1 < subchunks_num) ? "_" : "";

        str verb_current_name = subchunk[0];
        str verb_current_after_specification = "_";
        if (verb_prev_name != "" 
            && verb_prev_specification != "") verb_current_after_specification = "after_<verb_prev_name>_<verb_prev_specification>";
        str verb_current_before_specification = "_";
        if (verb_next_name != "" 
             && verb_next_specification != "") verb_current_before_specification = "before_<verb_next_name>";

        Verb verb_after = _module_get_verb_after(\module, verb_current_name, verb_current_after_specification, verb_prev_name, verb_prev_specification);
        tuple[Verb ind, Verb seq] verb_mid = _module_get_verb_mid(\module, verb_current_name);
        Verb verb_before = _module_get_verb_before(\module, verb_current_name, verb_current_before_specification, verb_next_name, verb_next_specification);
        bool verb_before_exists = !(verb_before is verb_empty);

        res = _verbs_translate_single(res, verb_after);
        res = _verbs_translate_multi(\module, res, verb_mid, verb_before_exists);
        res = _verbs_translate_single(res, verb_before);

        verbs_translated += res.verbs_translated;
    }

    return verbs_translated;
}

tuple[list[Verb],int] _verbs_translate_single(tuple[list[Verb] verbs_translated, int subchunk_size] res, Verb verb) {
    if (verb is verb_empty) return res;

    res.verbs_translated += [verb];
    res.subchunk_size -= verb.size;
    return res;
}


tuple[list[Verb],int] _verbs_translate_multi(GenerationModule \module, tuple[list[Verb] verbs_translated, int subchunk_size] res, tuple[Verb ind, Verb seq] verb, bool verb_before_exists) {
    if (verb.ind is verb_empty) res = _verbs_translate_multi_seq(\module, res, verb.seq, verb_before_exists);
    else if (verb.seq is verb_empty) res = _verbs_translate_multi_ind(res, verb.ind, verb_before_exists);
    else res = _verbs_translate_multi_both(\module, res, verb, verb_before_exists);

    return res;
}

tuple[list[Verb],int] _verbs_translate_multi_seq(tuple[list[Verb] verbs_translated, int subchunk_size] res, Verb verb, bool verb_before_exists) {
    int subchunk_size_partial = (verb_before_exists) ? res.subchunk_size-1 : res.subchunk_size;

    if (verb_seq_size(verb) < subchunk_size_partial) exception_verbs_translation_size_mismatch(verb, res.subchunk_size);

    for (_ <- [0..subchunk_size_partial]) {
        res.verbs_translated += [current];
        res.subchunk_size -= current.size;
        subchunk_size_partial -= current.size;
        if (current.dependencies.next.name != "none") current = _verb_sequence_next(\module, current);
    }
    
    return res;
}

tuple[list[Verb],int] _verbs_translate_multi_ind(tuple[list[Verb] verbs_translated, int subchunk_size] res, Verb verb, bool verb_before_exists) {
    int subchunk_size_partial = (verb_before_exists) ? res.subchunk_size-1 : res.subchunk_size;

    if (subchunk_size_partial % verb.size != 0) exception_verbs_translation_size_mismatch(verb, res.subchunk_size);

    while (subchunk_size_partial > 0) {
        res.verbs_translated += [verb];
        res.subchunk_size -= verb.size;
        subchunk_size_partial -= verb.size;
    }

    return res;
}

tuple[list[Verb],int] _verbs_translate_multi_both(GenerationModule \module, tuple[list[Verb] verbs_translated, int subchunk_size] res, tuple[Verb ind, Verb seq] verb, bool verb_before_exists) {
    int verb_seq_size = _verb_sequence_size(\module, verb.seq);
    int subchunk_size_partial = (verb_before_exists) ? res.subchunk_size-1 : res.subchunk_size;

    while (subchunk_size_partial > 0) {
        if (verb_seq_size >= subchunk_size_partial) {
            Verb current = verb.seq;
            for (_ <- [0..subchunk_size_partial]) {
                res.verbs_translated += [current];
                res.subchunk_size -= current.size;
                subchunk_size_partial -= current.size;
                if (current.dependencies.next.name != "none") current = _verb_sequence_next(\module, current);
            }
        }
        else {
            res.verbs_translated += [verb.ind];
            res.subchunk_size -= verb.ind.size;
            subchunk_size_partial -= verb.ind.size;
        }

        if (subchunk_size_partial < 0) exception_verbs_translation_size_mismatch(verb, res.subchunk_size);
    }

    return res;
}

int _verb_sequence_size(GenerationModule \module, Verb verb) {
    int size = 0;

    if (verb.dependencies.prev.name == "none"
        && verb.dependencies.next.name == "none") return -1;
    if (verb.dependencies.prev.name == "none"
        || verb.dependencies.next.name == "none") return 1;

    Verb current = verb;
    while (current.dependencies.next.name != "none") {
        size += current.size;
        current = _verb_sequence_next(\module, current);
    }
    size += current.size;

    return size;
}

Verb _verb_sequence_next(GenerationModule \module, Verb current) {
    return _module_get_verb(\module, current.dependencies.next.name, current.dependencies.next.specification);
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
list[list[str]] _verbs_concretize(list[GenerationVerbExpression] verbs, int width, int height) {
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

/******************************************************************************/
// --- Private Module Functions ------------------------------------------------

Verb _module_get_verb(GenerationModule \module, str verb_name, str verb_specification) {
    for (Verb v <- \module.generation_rules.verbs) {
        if (v.name == verb_name 
            && v.specification == verb_specification) return v;
    }

    exception_modules_not_found_verb(\module.name, verb_name, verb_specification);
    return verb_empty();
}

Verb _module_get_verb_after(GenerationModule \module, str verb_current_name, str verb_current_specification, str verb_prev_name, str verb_prev_specification) {
    for (Verb v <- \module.generation_rules.verbs) {
        if (v.name == verb_current_name 
            && v.specification == verb_current_specification
            && verb_is_after(v)
            && v.dependencies.prev.name == verb_prev_name
            && v.dependencies.prev.specification == verb_prev_specification) return v;
    }

    return verb_empty();
}

Verb _module_get_verb_before(GenerationModule \module, str verb_current_name, str verb_current_specification, str verb_next_name, str verb_next_specification) {
    for (Verb v <- \module.generation_rules.verbs) {
        if (v.name == verb_current_name 
            && v.specification == verb_current_specification
            && verb_is_before(v)
            && v.dependencies.next.name == verb_next_name
            && v.dependencies.next.specification == verb_next_specification) return v;
    }

    return verb_empty();
}

tuple[Verb,Verb] _module_get_verb_mid(GenerationModule \module, str verb_current_name) {
    tuple[Verb ind, Verb seq] verb = <verb_empty(), verb_empty()>;
    list[Verb] verbs_ind = [];
    list[Verb] verbs_seq = [];

    for (Verb v <- \module.generation_rules.verbs) {
        if (v.name == verb_current_name 
            && !verb_is_after(v)
            && !verb_is_before(v)) {

            if (verb_is_sequence(v)) verbs_seq += [v];
            else                     verbs_ind += [v];
        }
    }

    if      (verbs_ind == []) verb.seq = getOneFrom(verbs_seq);
    else if (verbs_seq == []) verb.ind = getOneFrom(verbs_ind);
    else                      verb = <getOneFrom(verbs_ind),getOneFrom(verbs_seq)>;

    return verb;
}