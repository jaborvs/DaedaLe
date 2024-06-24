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
import List;
import IO;

/******************************************************************************/
// --- Own modules imports -----------------------------------------------------
import Generation::ADT::Command;
import Generation::ADT::Pattern;
import Generation::ADT::Rule;
import Generation::ADT::Module;
import Generation::ADT::Chunk;
import Generation::ADT::Level;
import Generation::Compiler;
import Generation::Concretizer;
import Generation::Translator;
import Generation::Match;

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
    levels_generated = generate_levels(engine);

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
Level generate_level(GenerationEngine engine, str level_name, GenerationLevel gen_level) {
    Level level_generated = level_init(level_name, <engine.config["chunk_size"].width, engine.config["chunk_size"].height>);

    Coords chunk_level_coords= <0,0>;
    Coords chunk_entry = <0, toInt(engine.config["chunk_size"].height/2)-1>;
    tuple[Chunk chunk_generated, Coords chunk_exit] res = <chunk_empty(), <-1,-1>>;
    for (GenerationChunk chunk <- gen_level.chunks) {      
        res = generate_chunk(engine, chunk, chunk_entry);

        // if (chunk_level_coords in chunks_generated.coords) exception_wip
        level_generated.chunks_generated[chunk_level_coords] = res.chunk_generated;

        chunk_entry = res.chunk_exit;
        if (res.chunk_exit.x == engine.config["chunk_size"].width) {          // We exit right
            chunk_entry.x = 0;
            chunk_level_coords.x += 1;
            level_generated.abs_size.x_max += 1;
        }
        else if (res.chunk_exit.y == engine.config["chunk_size"].height) {    // We exit down
            chunk_entry.y = 0;
            chunk_level_coords.y += 1;
            level_generated.abs_size.y_max += 1;
        }
        else if (res.chunk_exit.y == 0) {                       // We exit up
            chunk_entry.y = engine.config["chunk_size"].height-1 ;
            chunk_level_coords.y -= 1;
            level_generated.abs_size.y_min -= 1;
        }
    }

    return level_generated;
}

/*
 * @Name:   generate_chunk
 * @Desc:   Function that generates a chunk from a given chunk data
 * @Params: engine -> Generation engine
 *          chunk  -> Generation chunk
 *          entry  -> Entry coords to the chunk
 * @Ret:    Generated chunk object
 */
tuple[Chunk, Coords] generate_chunk(GenerationEngine engine, GenerationChunk chunk, Coords entry) {
    tuple[list[list[str]] verbs, Coords exit] chunk_concretized = concretize(engine.modules[chunk.\module], chunk.verbs, entry, engine.config["chunk_size"].width, engine.config["chunk_size"].height);
    println(chunk_concretized);
    list[VerbAnnotation] verbs_translated = translate(engine.modules[chunk.\module], chunk_concretized.verbs);

    Chunk chunk_generated = chunk_init(chunk.name, <engine.config["chunk_size"].width, engine.config["chunk_size"].height>);
    chunk_generated.objects[engine.config["chunk_size"].width * entry.y + entry.x]     = "ph1";
    chunk_generated.objects[engine.config["chunk_size"].width * (entry.y+1) + entry.x] = "#";
    chunk_generated = apply_generation_rules(engine, engine.modules[chunk.\module], verbs_translated, chunk_generated);
    chunk_generated = apply_blanketize(engine, chunk_generated);

    return <chunk_generated, chunk_concretized.exit>;
}

/******************************************************************************/
// --- Private Apply Functions -------------------------------------------------

/*
 * @Name:   generate_chunk
 * @Desc:   Function that applies the generation rules associated to each of the 
 *          verbs
 * @Params: engine  -> Generation engine
 *          \module -> Generation module
 *          verbs   -> List of verbs
 *          chunk   -> chunk to generate
 * @Ret:    Generated chunk object
 */
Chunk apply_generation_rules(GenerationEngine engine, GenerationModule \module, list[VerbAnnotation] verbs, Chunk chunk) {
    println();
    println();
    println();
    println();
    println();
    println();
    println();
    println();
    println();
    println();
    println();

    for (VerbAnnotation verb <- verbs[0..(size(verbs)-1)]) {
        GenerationRule rule = \module.generation_rules[verb];
        GenerationPattern left = engine.patterns[rule.left];
        GenerationPattern right = engine.patterns[rule.right];
        chunk = apply_generation_rule(verb, left, right, chunk);
        
    }

    println(chunk_to_string(chunk));
    println();

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
Chunk apply_generation_rule(VerbAnnotation verb, GenerationPattern left, GenerationPattern right, Chunk chunk) {
    str program = "";

    program = match_generate_program(chunk, verb, left, right);
    if(result(Chunk chunk_rewritten) := eval(program)) {
        chunk = chunk_rewritten;
    }

    println("Verb <verb.name>(<verb.specification>)");
    println(chunk_to_string(chunk));
    println();

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