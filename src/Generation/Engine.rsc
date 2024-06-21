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
import List;
import String;
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
    list[list[str]] verbs_concretized = concretize(chunk.verbs, engine.config.width, engine.config.height);
    list[Verb] verbs_translated       = translate(engine.modules[chunk.\module], verbs_concretized);

    Coords player_coords = <0,engine.config.height/2-1>;
    chunk.objects[engine.config.width * player_coords.y + player_coords.x]     = "ph1";
    chunk.objects[engine.config.width * (player_coords.y+1) + player_coords.x] = "#";
    chunk = _apply_generation_rules(engine, chunk, verbs_translated);

    return chunk;
}

/******************************************************************************/
// --- Private Apply Functions -------------------------------------------------

GenerationChunk _apply_generation_rules(GenerationEngine engine, GenerationChunk chunk, list[Verb] verbs) {
    writeFile(|project://daedale/src/Interface/bin/chunk.out|, "");
    chunk_print(chunk, engine.config.width, "Initial state", "");

    for (Verb verb <- verbs) {
        chunk = _apply_generation_rule(engine, chunk, verb);
        chunk_print(chunk, engine.config.width, verb.name, verb.specification);
    }

    return chunk;
}

void chunk_print(GenerationChunk chunk, int width, str name, str specification) {
    file_loc = |project://daedale/src/Interface/bin/chunk.out|;
    str chunk_printed = readFile(file_loc);

    if (toLowerCase(name) == "initial state") chunk_printed += "\>\>\> <name>:\n\n";
    else                                      chunk_printed += "\>\>\> Verb <name>(<specification>)\n\n";

    int i = 0;
    for (str object <- chunk.objects) {
        chunk_printed += object;
        chunk_printed += "\t";
        i += 1;

        if (i % width == 0) chunk_printed += "\n";
    }

    chunk_printed += "\n<for(_ <- [0..(width-1)*4]){>-<}>\n";
    
    writeFile(file_loc, chunk_printed);
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