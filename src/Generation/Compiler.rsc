/*
 * @Module: Compiler
 * @Desc:   Module that compiles all the information from a Papyrus file
 * @Auth:   Borja Velasco -> code, comments
 */
module Generation::Compiler

/******************************************************************************/
// --- General modules imports -------------------------------------------------
import String;
import List;
import Set;
import IO;

/******************************************************************************/
// --- Own modules imports -----------------------------------------------------
import Generation::Exception;
import Generation::AST;
import Extension::Load;
import Extension::AST;

/******************************************************************************/
// --- Data structure defines --------------------------------------------------

/*
 * @Name:   GenerationEngine
 * @Desc:   Data structure that models the generation engine
 */
data GenerationEngine 
    = generation_engine(
        GenerationConfig config,
        map[str names, GenerationPattern generation_patterns] patterns,
        map[str names, GenerationModule generation_modules] modules,
        map[str names, GenerationLevel generation_levels] generated_levels
        )
    ;

/*
 * @Name:   GenerationConfig
 * @Desc:   Data structure that models the configuration for generation
 */
data GenerationConfig 
    = generation_config(int width, int height)
    | generation_config_empty()
    ;

/*
 * @Name:   GenerationPattern
 * @Desc:   Data structure that models a generation pattern
 */
data GenerationPattern
    = generation_pattern(list[GenerationRow] rows)
    | generation_pattern_empty()
    ;

/*
 * @Name:   GenerationModule
 * @Desc:   Data structure that models a generation module
 */
data GenerationModule
    = generation_module(map[Verb verbs, GenerationRule generation_rule] generation_rules)
    | generation_module_empty()
    ;

/*
 * @Name:   GenerationRule
 * @Desc:   Data structure that models a generation rule
 */
data GenerationRule
    = generation_rule(str left, str right)
    | generation_rule_empty()
    ;

/*
 * @Name:   GenerationLevel
 * @Desc:   Data structure that models a generation level draft
 */
data GenerationLevel
    = generation_level(list[GenerationChunk] chunks)
    | generation_level_empty()
    ;

/*
 * @Name:   GenerationChunk
 * @Desc:   Data structure that models a generation chunk
 */
data GenerationChunk
    = generation_chunk(str \module, list[GenerationVerbExpression] verbs, list[GenerationRow] rows)
    | generation_chunk_empty()
    ;

/*
 * @Name:   GenerationVerbExpression
 * @Desc:   Data structure that models a generation verb expression
 */
data GenerationVerbExpression
    = generation_verb_expression(str verb, str modifier)
    | generation_verb_expression_empty()
    ;

/*
 * @Name:   GenerationRow
 * @Desc:   Data structure that models a generation row
 */
data GenerationRow
    = generation_row(list[GenerationCell] cells)
    ;

/*
 * @Name:   GenerationCell
 * @Desc:   Data structure that models a generation cell
 */
data GenerationCell
    = generation_cell(str object)
    ;


/******************************************************************************/
// --- Public compile functions ------------------------------------------------

/*
 * @Name:   papyrus_compile
 * @Desc:   Function that compiles a PapyrusData object
 * @Params: pprs -> PapyrusData object to be compiled
 * @Ret:    GenerationEngine 
 */
GenerationEngine papyrus_compile(PapyrusData pprs) {
    GenerationEngine engine = generation_engine_init();

    engine.config = _papyrus_compile_config(pprs.configs);
    engine.patterns = _papyrus_compile_patterns(pprs.patterns);
    engine.modules = _papyrus_compile_modules(pprs.modules);
    engine.generated_levels = _papyrus_compile_levels(pprs.level_drafts, engine.config.width, engine.config.height);

    return engine;
}

/******************************************************************************/
// --- Private compile config functions ----------------------------------------

/*
 * @Name:   _papyrus_compile_config
 * @Desc:   Function to compile the generation configuration commands. For now,
 *          the only allowed command is 'chunk_size', but it is somewhat ready 
 *          to add more commands in the future if needed
 * @Params: configs -> Raw configuration data form the ast 
 * @Ret:    GenerationConfig object for the command
 */
GenerationConfig _papyrus_compile_config(list[ConfigurationData] configs) {
    GenerationConfig config_compiled = generation_config_empty();

    if (size(configs) > 1) exception_config_args_len();
    if (configs == []) return generation_config(15,15);

    str command = toLowerCase(configs[0].command);
    str params = configs[0].params;
    if (command != "chunk_size") exception_config_unknown_cmd(command);
    
    switch(command) {
        case "chunk_size": config_compiled = _papyrus_compile_config_chunk_size(params);
    }

    return config_compiled;
}

/*
 * @Name:   _papyrus_compile_config_chunk_size
 * @Desc:   Function to compile chunk size
 * @Param:  params -> Unprocessed params
 * @Ret:    GenerationConfig object
 */
GenerationConfig _papyrus_compile_config_chunk_size(str params) {
    list[str] params_splitted = split("x", params);
    int width = 0;
    int height = 0;

    try {
        width = toInt(params_splitted[0]);
        height = toInt(params_splitted[1]);
    } 
    catch IllegalArgument(value v, _): exception_config_chunk_size_illegal_arg(v);

    return generation_config(width, height);
}

/******************************************************************************/
// --- Private compile pattern functions ---------------------------------------

/*
 * @Name:   _papyrus_compile_patterns
 * @Desc:   Function that compiles all the patterns of a PapyrusData object. It
 *          converts them into a rascal pattern to be used by 'visit'
 * @Param:  patterns -> List of PatternData from the ast
 * @Ret:    Map of pattern name and generation pattern object
 */
map[str, GenerationPattern] _papyrus_compile_patterns(list[PatternData] patterns) {
    map[str names, GenerationPattern pattern] patterns_compiled = ();

    for (PatternData p <- patterns) {
        tuple[str name, GenerationPattern pattern] p_c = _papyrus_compile_pattern(p);
        if (p_c in patterns_compiled.names) exception_patterns_duplicated_pattern(p_c.name);
        else patterns_compiled[p_c.name] = p_c.pattern;
    }
    
    return patterns_compiled;
}

/*
 * @Name:   _papyrus_compile_pattern
 * @Desc:   Function to compile a pattern 
 * @Param:  pattern -> PatternData object fromm the ast
 * @Ret:    Tuple with name and generation pattern object
 */
tuple[str, GenerationPattern] _papyrus_compile_pattern(PatternData pattern) {
    tuple[str, GenerationPattern] pattern_compiled = <"", generation_pattern_empty()>;

    list[GenerationRow] rows_compiled = [];
    for (TilemapRowData r <- pattern.tilemap.row_dts) {
        list[GenerationCell] cells_compiled = [];
        for (str c <- r.objects) {
            cells_compiled += [generation_cell(c)];
        }
        rows_compiled += [generation_row(cells_compiled)];
    }

    pattern_compiled = <
        pattern.name,
        generation_pattern(rows_compiled)
        >;

    return pattern_compiled;
}

/******************************************************************************/
// --- Private compile module functions ----------------------------------------

/*
 * @Name:   _papyrus_compile_modules
 * @Desc:   Function that compiles all modules of a PapyrusData object
 * @Param:  modules -> List of ModuleData objects form the ast
 * @Ret:    Map of module name and generation module object
 */
map[str, GenerationModule] _papyrus_compile_modules(list[ModuleData] modules) {
    map[str names, GenerationModule modules] modules_compiled = ();

    for(ModuleData m <- modules) {
        tuple[str name, GenerationModule \module] m_c = _papyrus_compile_module(m);
        if (m_c.name in modules_compiled.names) exception_modules_duplicated_module(m_c.name);
        else  modules_compiled[m_c.name] = m_c.\module;
    }

    return modules_compiled;
}

/*
 * @Name:   _papyrus_compile_module
 * @Desc:   Function that compiles a module of a PapyrusData object
 * @Param:  \module -> ModuleData object from the ast
 * @Ret:    GenerationModule object
 */
tuple[str, GenerationModule] _papyrus_compile_module(ModuleData \module) {
    tuple[str, GenerationModule] module_compiled = <"", generation_module_empty()>;

    map[Verb verbs, GenerationRule generation_rules] compiled_rules = ();
    for (RuleData r <- \module.rule_dts) {
        tuple[Verb verb, GenerationRule rule] c_r = _papyrus_compile_rule(r);
        if (c_r.verb in compiled_rules.verbs) exception_modules_duplicated_verb(c_r.verb);
        else compiled_rules[c_r.verb] = c_r.rule;
    }

    module_compiled = <
        \module.name,
        generation_module(compiled_rules)
    >;

    return module_compiled;
}

tuple[Verb, GenerationRule] _papyrus_compile_rule(RuleData rule) {
    tuple[Verb verb, GenerationRule rule] rule_compiled = <verb_empty(), generation_rule_empty()>;

    map[int key, list[str] content] comments = rule.comments;
    if (comments == ()) exception_rules_no_verb();
    Verb verb = extension_load_verb(comments);

    rule_compiled = <
        verb,
        generation_rule(rule.left, rule.right)
    >;

    return rule_compiled;
}

/******************************************************************************/
// --- Private compile levels functions ----------------------------------------

/*
 * @Name:   _papyrus_compile_levels
 * @Desc:   Function that compiles all levels of a PapyrusData object
 * @Param:  levels -> List of LevelDraftData objects form the ast
 *          width  -> Chunk width
 *          height -> Chunk height
 * @Ret:    Map of level name and generation level object
 */
map[str, GenerationLevel] _papyrus_compile_levels(list[LevelDraftData] levels, int width, int height) {
    map[str names, GenerationLevel levels] levels_compiled = ();

    for (LevelDraftData ld <- levels) {
        tuple[str name, GenerationLevel level] ld_c = _papyrus_compile_level(ld, width, height);
        if (ld_c.name in levels_compiled.names) exception_levels_duplicated_level(ld_c);
        else levels_compiled[ld_c.name] = ld_c.level;
    }

    return levels_compiled;
}

/*
 * @Name:   _papyrus_compile_level
 * @Desc:   Function that compiles a level of a PapyrusData object
 * @Param:  level -> LevelDraftData object from the ast
 *          width  -> Chunk width
 *          height -> Chunk height
 * @Ret:    Level name and GenerationLevel object
 */
tuple[str, GenerationLevel] _papyrus_compile_level(LevelDraftData level, int width, int height) {
    tuple[str, GenerationLevel] level_compiled = <"", generation_level_empty()>;

    list[GenerationChunk] chunks_compiled = [_papyrus_compile_chunk(c, width, height) | ChunkData c <- level.chunk_dts];

    level_compiled = <
        level.name,
        generation_level(chunks_compiled)
        >;
    return level_compiled;
}

/*
 * @Name:   _papyrus_compile_chunk
 * @Desc:   Function that compiles a chunk
 * @Params: chunk  -> Chunk object from the ast
 *          width  -> Chunk width
 *          height -> Chunk height
 * @Ret:    GenerationChunk object
 */
GenerationChunk _papyrus_compile_chunk(ChunkData chunk, int width, int height) {
    GenerationChunk chunk_compiled = generation_chunk_empty();

    map[int key, list[str] content] comments = chunk.comments;
    if (comments == ()) exception_chunk_no_module();
    Module \module = extension_load_module(comments);

    chunk_compiled = generation_chunk(
        \module.name,
        [generation_verb_expression(v.name, v.modifier) | VerbExpressionData v <- chunk.verb_dts],
        [generation_row_init(width) | _ <- [0..height]]
    );
    
    return chunk_compiled;
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

/******************************************************************************/
// --- Level functions ---------------------------------------------------------

/*
 * @Name:   generation_row_init
 * @Desc:   Function to create a blank row filled only with background objects
 * @Params:
 * @Ret:    A blank row
 */
GenerationRow generation_row_init(int length) {
    return generation_row([generation_cell_init() | _ <- [0..length]]);
}

/*
 * @Name:   generation_cell_init
 * @Desc:   Function to create a blan cell filled with a background object
 * @Params:
 * @Ret:    A blank cell
 */
GenerationCell generation_cell_init() {
    return generation_cell(".");
}