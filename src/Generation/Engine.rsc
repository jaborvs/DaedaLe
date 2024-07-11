/*
 * @Module: Engine
 * @Desc:   Module that includes all the functionality to generate the desired 
 *          tutorial levels
 * @Auth:   Borja Velasco -> code, comments
 */
module Generation::Engine

/******************************************************************************/
// --- General modules imports -------------------------------------------------
import util::Eval;
import util::Math;
import util::Benchmark;
import List;
import IO;

/******************************************************************************/
// --- Own modules imports -----------------------------------------------------
import Generation::ADT::Command;
import Generation::ADT::Pattern;
import Generation::ADT::Rule;
import Generation::ADT::Module;
import Generation::ADT::Verb;
import Generation::ADT::Chunk;
import Generation::ADT::Level;
import Generation::Compiler;
import Generation::Concretizer;
import Generation::Translator;
import Generation::Match;
import Generation::Exception;

import Annotation::ADT::Verb;

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
void generate(GenerationEngine engine) {
    list[Level] levels_generated = [];
    real start_time = toReal(realTime());

    println("Generation started...");
    levels_generated = generate_levels(engine);
    println("Generation completed...\t\t\t(<(realTime()-start_time)/1000>s)");

    for (Level lvl <- levels_generated) level_print(lvl, |project://daedale/src/Interface/bin/levels.out|);
    return;
}

/******************************************************************************/
// --- Private Generation Functions --------------------------------------------

/*
 * @Name:   generate_levels
 * @Desc:   Function that generates all the specified levels
 * @Params: engine -> Generation engine
 * @Ret:    list of gnerated levels
 */
list[Level] generate_levels(GenerationEngine engine) {
    list[Level] levels_generated = [generate_level(engine, name, engine.levels_draft[name]) | str name <- engine.levels_draft.names];
    return levels_generated;
}

/*
 * @Name:   generate_level
 * @Desc:   Function that generates a single level from a given draft
 * @Params: engine -> Generation engine
 *          level  -> Generation level
 * @Ret:    list[list[str]] given that a level is a list[str] and we are
 *          returning all levels generated
 */
Level generate_level(GenerationEngine engine, str level_name, GenerationLevel level_abs) {
    Level level_generated = level_init(level_name, <engine.config["chunk_size"].width, engine.config["chunk_size"].height>);

    real start_time = toReal(realTime());

    Coords chunk_coords= <0,0>;
    Coords player_entry = <0, toInt(engine.config["chunk_size"].height/2)>;
    tuple[Chunk chunk_generated, Coords player_exit] res = <chunk_empty(), <-1,-1>>;
    for (GenerationChunk chunk_abs <- level_abs.chunks) {      
        res = generate_chunk(engine, chunk_coords, chunk_abs, player_entry);

        level_generated.chunks_generated[chunk_coords] = res.chunk_generated;

        player_entry = res.player_exit;
        if      (check_exited_right(engine, res.player_exit)) {          // We exit right
            player_entry.x = 0;
            chunk_coords.x += 1;
            if (chunk_coords.x > level_generated.abs_size.x_max) level_generated.abs_size.x_max += 1;
        }
        else if (check_exited_down(engine, res.player_exit)) {    // We exit down
            player_entry.y = 0;
            chunk_coords.y += 1;
            if (chunk_coords.y > level_generated.abs_size.y_max) level_generated.abs_size.y_max += 1;
        }
        else if (check_exited_up(res.player_exit)) {                       // We exit up
            player_entry.y = engine.config["chunk_size"].height-1 ;
            chunk_coords.y -= 1;
            if (chunk_coords.y < level_generated.abs_size.y_min)level_generated.abs_size.y_min -= 1;
        }
    }

    println("    <string_capitalize(level_name)> generated...\t\t\t(<(realTime()-start_time)/1000>s)");

    return level_generated;
}

/*
 * @Name:   generate_chunk
 * @Desc:   Function that generates a chunk from a given chunk data
 * @Params: engine        -> Generation engine
 *          chunk         -> Generation chunk
 *          player_entry  -> Entry coords to the chunk
 * @Ret:    Generated chunk object
 */
tuple[Chunk, Coords] generate_chunk(GenerationEngine engine, Coords chunk_coords, GenerationChunk chunk_abs, Coords player_entry) {
    Chunk win_chunk_generated = chunk_empty();
    Chunk challenge_chunk_generated = chunk_empty();
    Chunk chunk_generated = chunk_empty();   

    tuple[
        tuple[list[list[GenerationVerbConcretized]] verbs, Coords player_exit]     win,
        tuple[list[list[GenerationVerbConcretized]] verbs, Coords player_dead_end] \challenge
    ] verbs_concretized = concretize(engine.modules[chunk_abs.\module], chunk_abs, player_entry, <engine.config["pattern_max_size"].width, engine.config["pattern_max_size"].height>, <engine.config["chunk_size"].width, engine.config["chunk_size"].height>);

    tuple[
        list[VerbAnnotation] win,
        list[VerbAnnotation] \challenge
    ] verbs_translated = translate(engine.modules[chunk_abs.\module], verbs_concretized.win.verbs, verbs_concretized.\challenge.verbs);

    win_chunk_generated = generate_chunk_partial(engine, chunk_abs, player_entry, verbs_concretized.win.player_exit, verbs_translated.win, engine.config["chunk_size"].width, engine.config["chunk_size"].height);
    challenge_chunk_generated = generate_chunk_partial(engine, chunk_abs, player_entry, <-1,-1>, verbs_translated.\challenge, engine.config["chunk_size"].width, engine.config["chunk_size"].height);
    chunk_generated = apply_merge(chunk_abs.name, win_chunk_generated, challenge_chunk_generated);
    chunk_generated = apply_blanketize(engine, chunk_generated);

    if (chunk_coords == <0,0>) chunk_generated = apply_place_player(chunk_generated, player_entry);

    return <chunk_generated, verbs_concretized.win.player_exit>;
}

/*
 * @Name:   generate_chunk_partial
 * @Desc:   Function that generates a chunk. It is called partial cause the result
 *          will later be merged with another chunk.
 * @Params: engine           -> Generation engine
 *          chunk_abs        -> Generation chunk
 *          player_entry     -> Player entry coords to the chunk
 *          verbs_translated -> List of verbs to apply to generate the chunk
 *          width            -> Width of the chunk
 *          height           -> Height of the chunk
 * @Ret:    Chunk generated
 */
Chunk generate_chunk_partial(GenerationEngine engine, GenerationChunk chunk_abs, Coords player_entry, Coords player_exit, list[VerbAnnotation] verbs_translated, int width, int height) {
    Chunk chunk_generated = chunk_empty();

    if (verbs_translated == []) return chunk_generated;

    chunk_generated = chunk_init(chunk_abs.name, <width, height>);
    chunk_generated = apply_generation_rules(engine, engine.modules[chunk_abs.\module], chunk_generated, player_entry, player_exit, verbs_translated);
    
    return chunk_generated;
}

/******************************************************************************/
// --- Private Apply Functions -------------------------------------------------

/*
 * @Name:   apply_generation_rules
 * @Desc:   Function that applies the generation rules associated to each of the 
 *          verbs
 * @Params: engine  -> Generation engine
 *          \module -> Generation module
 *          verbs   -> List of verbs
 *          chunk   -> chunk to generate
 * @Ret:    Generated chunk object
 */
Chunk apply_generation_rules(GenerationEngine engine, GenerationModule \module, Chunk chunk, Coords player_entry, Coords player_exit, list[VerbAnnotation] verbs) {
    VerbAnnotation verb_enter = verb_annotation_empty();
    VerbAnnotation verb_exit  = verb_annotation_empty(); 

    if      (check_entered_above(player_entry))         verb_enter = Annotation::ADT::Verb::enter_down_verb;
    else if (check_entered_below(engine, player_entry)) verb_enter = Annotation::ADT::Verb::enter_up_verb;
    else if (check_entered_left(player_entry))          verb_enter = Annotation::ADT::Verb::enter_right_verb;
    verbs = insertAt(verbs, 0, verb_enter);

    if      (check_exited_up(player_exit))              verb_exit = Annotation::ADT::Verb::exit_up_verb;
    else if (check_exited_down(engine, player_exit))    verb_exit = Annotation::ADT::Verb::exit_down_verb;
    else if (check_exited_right(engine, player_exit))   verb_exit = Annotation::ADT::Verb::exit_right_verb;
    if (!verb_exit is verb_annotation_empty) verbs += [verb_exit];

    for (VerbAnnotation verb <- verbs[0..(size(verbs))]) {
        GenerationRule rule = \module.generation_rules[verb];
        GenerationPattern left = engine.patterns[rule.left];
        GenerationPattern right = engine.patterns[rule.right];
        chunk = apply_generation_rule(verb, left, right, chunk, player_entry);
    }

    return chunk;
}

/*
 * @Name:   generate_chunk
 * @Desc:   Function that applies the generation one rule
 * @Params: verb  -> Verb to apply
 *          left  -> LHS of the generation rule
 *          right -> RHS of the generation rule
 *          chunk -> Chunk to generate
 * @Ret:    Generated chunk object
 */
Chunk apply_generation_rule(VerbAnnotation verb, GenerationPattern left, GenerationPattern right, Chunk chunk, Coords player_entry) {
    str program = "";

    program = match_generate_program(chunk, player_entry, verb, left, right);
    if(result(Chunk chunk_rewritten) := eval(program)) {
        chunk = chunk_rewritten;
    }
    // println(verb_annotation_to_string(verb));
    // println(chunk_to_string(chunk));
    // println();

    return chunk;
}

Chunk apply_place_player(Chunk chunk, Coords player_entry) {
    chunk.objects[chunk.size.width * player_entry.y + player_entry.x] = "p";
    return chunk;
}

/*
 * @Name:   apply_blanketize
 * @Desc:   Function that eliminates those 
 * @Params: engine -> Generation engine
 *          chunk  -> Chunk to generate
 * @Ret:    Generated chunk object
 */
Chunk apply_blanketize(GenerationEngine engine, Chunk chunk) {
    for(int i <- [0..size(chunk.objects)]) {
        if (chunk.objects[i] notin engine.config["objects_permanent"].objects) chunk.objects[i] = ".";
    }

    return chunk;
}

/*
 * @Name:   apply_merge
 * @Desc:   Function that merges two chunks
 * @Params: name                 -> Name of the chunk
 *          win_chunk_generated  -> Chunk containing the win playtrace
 *          challenge_chunk_generated -> Chunk containing the challenge playtrace
 * @Ret:    Merged chunk object
 */
Chunk apply_merge(str name, Chunk win_chunk_generated, Chunk challenge_chunk_generated) {
    list[str] objects_merged = [];

    if (challenge_chunk_generated is chunk_empty) return win_chunk_generated;

    for (int i <- [0..size(win_chunk_generated.objects)]) {
        if      (win_chunk_generated.objects[i] != "." && challenge_chunk_generated.objects[i] == ".")     objects_merged += [win_chunk_generated.objects[i]];
        else if (win_chunk_generated.objects[i] == "." && challenge_chunk_generated.objects[i] != ".")     objects_merged += [challenge_chunk_generated.objects[i]];
        else if (win_chunk_generated.objects[i] != "." && challenge_chunk_generated.objects[i] != ".") {
            if      (win_chunk_generated.objects[i] != "#" && challenge_chunk_generated.objects[i] == "#") objects_merged += [win_chunk_generated.objects[i]];
            else if (win_chunk_generated.objects[i] == "#" && challenge_chunk_generated.objects[i] != "#") objects_merged += [challenge_chunk_generated.objects[i]];
            else                                                                                      objects_merged += [win_chunk_generated.objects[i]];
        }
        else                                                                                      objects_merged += [win_chunk_generated.objects[i]];
    }

    return chunk(name, win_chunk_generated.size, objects_merged);
}


/******************************************************************************/
// --- Calculate functions -----------------------------------------------------

/******************************************************************************/
// --- Check functions ---------------------------------------------------------

bool check_exited_vertical(GenerationEngine engine, Coords player_exit) {
    return check_exited_up(player_exit) || check_exited_down(engine, player_exit);
}

bool check_exited_horizontal(GenerationEngine engine, Coords player_exit) {
    return check_exited_right(engine, player_exit);
}

bool check_exited_up(Coords player_exit) {
    return player_exit.y == -1;
}

bool check_exited_right(GenerationEngine engine, Coords player_exit) {
    return player_exit.x == engine.config["chunk_size"].width;
}

bool check_exited_down(GenerationEngine engine, Coords player_exit) {
    return player_exit.y == engine.config["chunk_size"].height;
}

bool check_entered_vertical(GenerationEngine engine, Coords player_entry) {
    return check_entered_above(player_entry) || check_entered_below(engine, player_entry);
}

bool check_entered_horizontal(GenerationEngine engine, Coords player_entry) {
    return check_entered_left(player_entry);
}

bool check_entered_above(Coords player_entry) {
    return  player_entry.y == 0 && player_entry.x != 0;
}

bool check_entered_below(GenerationEngine engine, Coords player_entry) {
    return  player_entry.y == (engine.config["chunk_size"].height - 1) && player_entry.x != 0;
}

bool check_entered_left(Coords player_entry) {
    return player_entry.x == 0;
}