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

/******************************************************************************/
// --- Data structure defines --------------------------------------------------

/*
 * @Name:   GenerationEngine
 * @Desc:   Data structure that models the generation engine
 */
data GenerationEngine 
    = generation_engine(
        GenerationConfig config,
        map[str name, GenerationPattern generation_pattern] patterns,
        map[str name, GenerationModule generation_module] modules,
        map[str name, GenerationLevel generation_level] generated_levels
    );

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
    = generation_pattern(int tmp)
    | generation_pattern_empty()
    ;

/*
 * @Name:   GenerationModule
 * @Desc:   Data structure that models a generation module
 */
data GenerationModule
    = generation_module(map[str verb, GenerationRule generation_rule] generation_rules)
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
    = generation_level(
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
    // engine.levels = _papyrus_compile_levels(pprs.level_drafts);

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
    return ();
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
        else  modules_compiled[m_c] = m_c.\module;
    }

    return modules_compiled;
}

/*
 * @Name:   _papyrus_compile_module
 * @Desc:   Function that compiles a module of a PapyrusData object
 * @Param:  \module -> ModuleData object from the ast
 * @Ret:    GenerationModule object
 */
GenerationModule _papyrus_compile_module(ModuleData \module) {
    GenerationModule compiled_module = generation_module_empty();

    map[str verbs, GenerationRule generation_rules] compiled_rules = ();
    for (RuleData r <- \module.rule_dts) {
        tuple[str verb, GenerationRule rule] c_r = _papyrus_compile_rule(r);
        if (c_r.verb in compiled_rules.verbs) exception_modules_duplicated_verb(c_r.verb);
        else compiled_rules[c_r.verb] = c_r.rule;
    }

    return compiled_module;
}

tuple[str,GenerationRule] _papyrus_compile_rule(RuleData rule) {
    tuple[str verb, GenerationRule rule] rule_compiled = <"", generation_rule_empty()>;

    map[int key, list[str] content] comments = rule.comments;
    if (comments == ()) exception_rules_no_verb();
    str comments_processed = comments[toList(comments.key)[0]][0];

    return rule_compiled;
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