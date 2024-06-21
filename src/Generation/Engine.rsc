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
import Generation::ADT::Config;
import Generation::ADT::Pattern;
import Generation::ADT::Rule;
import Generation::ADT::Module;
import Generation::ADT::Chunk;
import Generation::ADT::LevelDraft;
import Generation::Compiler;
import Generation::Concretizer;
import Generation::Translator;
import Generation::Match;

import Extension::ADT::Verb;

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
    levels_generated = generate_levels(engine);

    return levels_generated;
}

/******************************************************************************/
// --- Private Generation Functions --------------------------------------------

/*
 * @Name:   generate_levels
 * @Desc:   Function that generates all the specified levels
 * @Params: 
 * @Ret:    list[list[str]] given that a level is a list[str] and we are
 *          returning all levels generated
 */
list[list[str]] generate_levels(GenerationEngine engine) {
    list[list[str]] levels_generated = [generate_level(engine, engine.generated_levels[name]) | str name <- engine.generated_levels.names];
    return levels_generated;
}

/*
 * @Name:   generate_level
 * @Desc:   Function that generates a single level from a given draft
 * @Params: 
 * @Ret:    list[list[str]] given that a level is a list[str] and we are
 *          returning all levels generated
 */
list[str] generate_level(GenerationEngine engine, GenerationLevel level) {
    // list[GenerationChunk] chunks_generated =  [generate_chunk(engine, chunk) | GenerationChunk chunk <- level.chunks];
    list[GenerationChunk] chunks_generated = [];

    Coords entry = <0, toInt(engine.config.height/2)-1>;
    tuple[GenerationChunk generated_chunk, Coords exit] res = <generation_chunk_empty(), <-1,-1>>;
    for (GenerationChunk chunk <- level.chunks) {      
        res = generate_chunk(engine, chunk, entry);
        entry = res.exit;
        chunks_generated += [res.generated_chunk];
    }

    return [];
}

/*
 * @Name:   generate_chunk
 * @Desc:   Function that generates a chunk from a given chunk data
 * @Params:
 * @Ret:    Generated chunk object
 */
tuple[GenerationChunk, Coords] generate_chunk(GenerationEngine engine, GenerationChunk chunk, Coords entry) {
    tuple[list[list[str]] verbs, Coords exit] chunk_concretized = concretize(engine.modules[chunk.\module], chunk.verbs, entry, engine.config.width, engine.config.height);
    list[Verb] verbs_translated = translate(engine.modules[chunk.\module], chunk_concretized.verbs);

    chunk.objects[engine.config.width * entry.y + entry.x]     = "ph1";
    chunk.objects[engine.config.width * (entry.y+1) + entry.x] = "#";
    chunk = apply_generation_rules(engine, chunk, verbs_translated);
    
    return <chunk, chunk_concretized.exit>;
}

/******************************************************************************/
// --- Private Apply Functions -------------------------------------------------

GenerationChunk apply_generation_rules(GenerationEngine engine, GenerationChunk chunk, list[Verb] verbs) {
    writeFile(|project://daedale/src/Interface/bin/chunk.out|, "");
    chunk_print(chunk, engine.config.width);

    for (Verb verb <- slice(verbs, 0, size(verbs)-1)) {
        chunk = apply_generation_rule(engine, chunk, verb);
        chunk_print_verb(chunk, engine.config.width, verb);
    }

    return chunk;
}

GenerationChunk apply_generation_rule(GenerationEngine engine, GenerationChunk chunk, Verb verb) {
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