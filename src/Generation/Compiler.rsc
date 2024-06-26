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
import Generation::AST;
import Generation::ADT::Command;
import Generation::ADT::Pattern;
import Generation::ADT::Rule;
import Generation::ADT::Module;
import Generation::ADT::VerbExpression;
import Generation::ADT::Chunk;
import Generation::ADT::Level;
import Generation::Exception;

import Annotation::ADT::Verb;
import Annotation::ADT::Chunk;
import Annotation::Load;

/******************************************************************************/
// --- Data structure defines --------------------------------------------------

/*
 * @Name:   GenerationEngine
 * @Desc:   Data structure that models the generation engine
 */
data GenerationEngine 
    = generation_engine(
        map[str names, GenerationCommand generation_commands] config,
        map[str names, GenerationPattern generation_patterns] patterns,
        map[str names, GenerationModule generation_modules] modules,
        map[str names, GenerationLevel generation_levels] levels_draft,
        map[str names, Level levels] levels_generated
        )
    | generation_engine_empty()
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

    engine.config = papyrus_compile_config(pprs.commands);
    engine.patterns = papyrus_compile_patterns(pprs.patterns);
    engine.modules = papyrus_compile_modules(pprs.modules);
    engine.levels_draft = papyrus_compile_levels(pprs.level_drafts);

    return engine;
}

/******************************************************************************/
// --- Private compile config functions ----------------------------------------

/*
 * @Name:   papyrus_compile_config
 * @Desc:   Function to compile the generation configuration commands. For now,
 *          the only allowed command is 'chunk_size', but it is somewhat ready 
 *          to add more commands in the future if needed
 * @Params: command_datas -> Raw commands data form the ast 
 * @Ret:    GenerationConfig object for the command
 */
map[str,GenerationCommand] papyrus_compile_config(list[CommandData] commands_datas) {
    map[str names, GenerationCommand generation_commmands] config = ();

    for (CommandData cmd <- commands_datas) {
        if (cmd.name in config.names) exception_config_duplicated_cmd(cmd.name);
        else                          config[cmd.name] = papyrus_compile_command(cmd);
    } 

    return config;
}

/*
 * @Name:   papyrus_compile_command
 * @Desc:   Function to compile configuration commands
 * @Param:  command_data -> Unprocessed command
 * @Ret:    GenerationCommand object
 */
GenerationCommand papyrus_compile_command(CommandData command_data) {
    GenerationCommand command = generation_command_empty();

    switch(command_data.name) {
        case /chunk_size/: command = papyrus_compile_chunk_size(command_data);
        case /objects_permanent/: command = papyrus_compile_objects_permanent(command_data);
    }

    return command;
}

/*
 * @Name:   papyrus_compile_config_chunk_size
 * @Desc:   Function to compile chunk size
 * @Param:  command -> Unprocessed command
 * @Ret:    GenerationCommand object
 */
GenerationCommand papyrus_compile_chunk_size(CommandData command) {
    list[str] params = split("x", command.params);
    int width = 0;
    int height = 0;

    try {
        width = toInt(params[0]);
        height = toInt(params[1]);
    } 
    catch IllegalArgument(value v, _): exception_config_chunk_size_illegal_arg(v);

    return generation_command_chunk_size(width, height);
}

/*
 * @Name:   papyrus_compile_config_chunk_size
 * @Desc:   Function to compile permanent objects
 * @Param:  command -> Unprocessed command
 * @Ret:    GenerationCommand object
 */
GenerationCommand papyrus_compile_objects_permanent(CommandData command) {
    list[str] params = split(" and ", command.params);
    return generation_command_objects_permanent(params);
}

/******************************************************************************/
// --- Private compile pattern functions ---------------------------------------

/*
 * @Name:   papyrus_compile_patterns
 * @Desc:   Function that compiles all the patterns of a PapyrusData object. It
 *          converts them into a rascal pattern to be used by 'visit'
 * @Param:  patterns -> List of PatternData from the ast
 * @Ret:    Map of pattern name and generation pattern object
 */
map[str, GenerationPattern] papyrus_compile_patterns(list[PatternData] patterns) {
    map[str names, GenerationPattern pattern] patterns_compiled = ();

    for (PatternData p <- patterns) {
        tuple[str name, GenerationPattern pattern] p_c = papyrus_compile_pattern(p);
        if (p_c.name in patterns_compiled.names) exception_patterns_duplicated_pattern(p_c.name);
        else patterns_compiled[p_c.name] = p_c.pattern;
    }
    
    return patterns_compiled;
}

/*
 * @Name:   papyrus_compile_pattern
 * @Desc:   Function to compile a pattern 
 * @Param:  pattern -> PatternData object fromm the ast
 * @Ret:    Tuple with name and generation pattern object
 */
tuple[str, GenerationPattern] papyrus_compile_pattern(PatternData pattern) {
    tuple[str, GenerationPattern] pattern_compiled = <"", generation_pattern_empty()>;

    list[list[str]] objects_compiled = [];
    for (TilemapRowData r <- pattern.tilemap.row_dts) {
        objects_compiled += [r.objects];
    }

    pattern_compiled = <
        pattern.name,
        generation_pattern(objects_compiled)
        >;

    return pattern_compiled;
}

/******************************************************************************/
// --- Private compile module functions ----------------------------------------

/*
 * @Name:   papyrus_compile_modules
 * @Desc:   Function that compiles all modules of a PapyrusData object
 * @Param:  modules -> List of ModuleData objects form the ast
 * @Ret:    Map of module name and generation module object
 */
map[str, GenerationModule] papyrus_compile_modules(list[ModuleData] modules) {
    map[str names, GenerationModule modules] modules_compiled = ();

    for(ModuleData m <- modules) {
        tuple[str name, GenerationModule \module] m_c = papyrus_compile_module(m);
        
        m_c.\module.generation_rules[Annotation::ADT::Verb::enter_verb] = Generation::ADT::Rule::enter_generation_rule;
        m_c.\module.generation_rules[Annotation::ADT::Verb::exit_verb]  = Generation::ADT::Rule::exit_generation_rule;

        if (m_c.name in modules_compiled.names) exception_modules_duplicated_module(m_c.name);
        else  modules_compiled[m_c.name] = m_c.\module;
    }

    return modules_compiled;
}

/*
 * @Name:   papyrus_compile_module
 * @Desc:   Function that compiles a module of a PapyrusData object
 * @Param:  \module -> ModuleData object from the ast
 * @Ret:    GenerationModule object
 */
tuple[str, GenerationModule] papyrus_compile_module(ModuleData \module) {
    tuple[str, GenerationModule] module_compiled = <"", generation_module_empty()>;

    map[VerbAnnotation verbs, GenerationRule generation_rules] compiled_rules = ();
    for (RuleData r <- \module.rule_dts) {
        tuple[VerbAnnotation verb, GenerationRule rule] c_r = papyrus_compile_rule(r);
        if (c_r.verb in compiled_rules.verbs) exception_modules_duplicated_verb(c_r.verb);
        else compiled_rules[c_r.verb] = c_r.rule;
    }

    module_compiled = <
        \module.name,
        generation_module(compiled_rules)
    >;

    return module_compiled;
}

tuple[VerbAnnotation, GenerationRule] papyrus_compile_rule(RuleData rule) {
    tuple[VerbAnnotation verb, GenerationRule rule] rule_compiled = <verb_annotation_empty(), generation_rule_empty()>;

    map[int key, list[str] content] comments = rule.comments;
    if (comments == ()) exception_rules_no_verb();
    VerbAnnotation verb = annotation_load_verb_annotation(comments);

    rule_compiled = <
        verb,
        generation_rule(rule.left, rule.right)
    >;

    return rule_compiled;
}

/******************************************************************************/
// --- Private compile levels functions ----------------------------------------

/*
 * @Name:   papyrus_compile_levels
 * @Desc:   Function that compiles all levels of a PapyrusData object
 * @Param:  levels -> List of LevelDraftData objects form the ast
 *          width  -> Chunk width
 *          height -> Chunk height
 * @Ret:    Map of level name and generation level object
 */
map[str, GenerationLevel] papyrus_compile_levels(list[LevelDraftData] levels) {
    map[str names, GenerationLevel levels] levels_compiled = ();

    for (LevelDraftData ld <- levels) {
        tuple[str name, GenerationLevel level] ld_c = papyrus_compile_level(ld);
        if (ld_c.name in levels_compiled.names) exception_levels_duplicated_level(ld_c.name);
        else levels_compiled[ld_c.name] = ld_c.level;
    }

    return levels_compiled;
}

/*
 * @Name:   papyrus_compile_level
 * @Desc:   Function that compiles a level of a PapyrusData object
 * @Param:  level -> LevelDraftData object from the ast
 *          width  -> Chunk width
 *          height -> Chunk height
 * @Ret:    Level name and GenerationLevel object
 */
tuple[str, GenerationLevel] papyrus_compile_level(LevelDraftData level) {
    tuple[str, GenerationLevel] level_compiled = <"", generation_level_empty()>;

    list[GenerationChunk] chunks_compiled = [papyrus_compile_chunk(c) | ChunkData c <- level.chunk_dts];

    level_compiled = <
        level.name,
        generation_level(chunks_compiled)
        >;
    return level_compiled;
}

/*
 * @Name:   papyrus_compile_chunk
 * @Desc:   Function that compiles a chunk
 * @Params: chunk  -> Chunk object from the ast
 *          width  -> Chunk width
 *          height -> Chunk height
 * @Ret:    GenerationChunk object
 */
GenerationChunk papyrus_compile_chunk(ChunkData chunk) {
    GenerationChunk chunk_compiled = generation_chunk_empty();

    map[int key, list[str] content] comments = chunk.comments;
    if (comments == ()) exception_chunk_no_module();
    ChunkAnnotation chunk_anno = annotation_load_chunk_annotation(comments);

    list[GenerationVerbExpression] win_verbs = [generation_verb_expression(v.name, v.modifier) | VerbExpressionData v <- chunk.win_pt.verb_dts];
    list[GenerationVerbExpression] fail_verbs = (chunk.fail_pt != []) ? [generation_verb_expression(v.name, v.modifier) | VerbExpressionData v <- chunk.fail_pt[0].verb_dts] : [];

    chunk_compiled = generation_chunk(
        chunk_anno.name,
        chunk_anno.\module,
        win_verbs,
        fail_verbs
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
        (),
        (),
        (),
        (),
        ()
    );

    return engine;
}