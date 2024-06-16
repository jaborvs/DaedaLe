/*
 * @Module: Compiler
 * @Desc:   Module that compiles all the information from a Papyrus file
 * @Auth:   Borja Velasco -> code, comments
 */
module Generation::Compiler

/******************************************************************************/
// --- Data structure defines --------------------------------------------------

/*
 * @Name:   GenerationEngine
 * @Desc:   Data structure that models the generation engine
 */
data GenerationEngine 
    = generation_engine(
        GenerationConfig config,
        map[str, GenerationPattern] patterns,
        map[str, GenerationModule] modules,
        map[str, GeneratedLevel] generated_levels
    );

/*
 * @Name:   GenerationConfig
 * @Desc:   Data structure that models the configuration for generation
 */
data GenerationConfig 
    = generation_config(tuple[int width, int height] chunk_size)
    | generation_config_empty()
    ;

/*
 * @Name:   GenerationPattern
 * @Desc:   Data structure that models a generation pattern
 */
data GenerationPattern
    = generation_pattern(
        int tmp
    )
    ;

/*
 * @Name:   GenerationModule
 * @Desc:   Data structure that models a generation module
 */
data GenerationModule
    = generation_module(
        map[str verb, GenerationRule generation_rule] generation_rules
    );

/*
 * @Name:   GenerationRule
 * @Desc:   Data structure that models a generation rule
 */
data GenerationRule
    = generation_rule(
        str verb,
        str left,
        str right
    );

/*
 * @Name:   GenerationLevel
 * @Desc:   Data structure that models a generation level draft
 */
data GenerationLevel
    = generation_level(
        str name,
        list[GenerationChunk] chunks
    );

/*
 * @Name:   GenerationChunk
 * @Desc:   Data structure that models a generation chunk
 */
data GenerationChunk
    = generation_chunk(
        str \module,
        list[GenerationRow] rows
    );

/*
 * @Name:   GenerationRow
 * @Desc:   Data structure that models a generation row
 */
data GenerationRow
    = generation_row(
        list[GenerationCell] cells
    );

/*
 * @Name:   GenerationCell
 * @Desc:   Data structure that models a generation cell
 */
data GenerationCell
    = generation_cell(
        str object
    );


/******************************************************************************/
// --- Public compile functions ------------------------------------------------

GenerationEngine compile(PapyrusData pprs) {
    GenerationEngine engine = generation_engine_init();

    engine.config = compile_config(pprs.config);
    engine.patterns = compile_patterns(pprs.patterns);
    engine.modules = compile_modules(pprs.modules);
    engine.levels = compile_levels(pprs.levels);

    return engine;
}

/******************************************************************************/
// --- Engine functions --------------------------------------------------------

/*
 * @Name:   generation_engine_init
 * @Desc:   Function that starts an blank generation engine
 * @Param:  Empty
 * @Ret:    Blank generation engine
 */
GenerationEngine generation_engine_init() {
    GenerationEngine engine = generation_engine(
        generation_config_empty(),
        (),
        (),
        ()
    );

    return engine;
}