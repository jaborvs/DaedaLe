/*
 * @Module: Match
 * @Desc:   Module that contains the functionality to generate a program that 
 *          enables us to use GenerationPatterns through Rascal's list pattern
 *          matching 
 * @Auth:   Borja Velasco -> code
 */
module Generation::Match

/******************************************************************************/
// --- General modules imports -------------------------------------------------
import IO;
import String;
import List;
import util::Eval;

/******************************************************************************/
// --- Own modules imports -----------------------------------------------------
import Generation::Compiler;
import Extension::Verb;
import Utils;

void main() {
    Verb v = verb(
        "crawl",
        "",
        "up",
        1,
        <<"start","">,<"end","">>
        );

    GenerationPattern left = generation_pattern([
        generation_row(["P","."]),
        generation_row(["#","."])
        ]);
    GenerationPattern right = generation_pattern([
        generation_row(["H","P"]),
        generation_row(["#","#"])
        ]);

    int width = 5;
    int height = 5;
    GenerationChunk chunk = generation_chunk(
        "Module1",
        [],
        [
            ".",".",".",".",".",
            ".","P",".",".",".",
            ".","#",".",".",".",
            ".",".",".",".",".",
            ".",".",".",".","."
        ]
        );

    str program = match_generate_program(chunk, width, v, left, right);
    println(program);
    if(result(GenerationChunk chunk_rewritten) := eval(program)) {
        chunk = chunk_rewritten;
        println(chunk.objects);
    }
}

/******************************************************************************/
// --- Public functions --------------------------------------------------------

/*
 * @Name:   match_generate_program
 * @Desc:   Function that generates the matching program for a given
 *          GenerationRule to rewrite a GenerationChunk
 * @Params: chunk -> GenerationChunk to be rewritten
 *          left  -> Left pattern of the GenerationRule
 *          right -> Right pattern of the GenerationRule
 * @Ret:    str with the complete programm
 */
str match_generate_program(GenerationChunk chunk, int chunk_width, Verb verb, GenerationPattern left, GenerationPattern right) {
    str program = "";

    program += _match_generate_module_section(verb);
    program += _match_generate_imports_section();
    program += _match_generate_data_structures_section();
    program += _match_generate_functions_section(chunk_width, verb, left, right);
    program += _match_generate_calls_section(chunk, verb);

    return program;
}

/******************************************************************************/
// --- Private module section functions ----------------------------------------

str _match_generate_module_section(Verb verb) 
    = "//module Generation::<string_capitalize(verb.name)><string_capitalize(verb.specification)>"
    + _match_generate_line_break(2)
    ;

/******************************************************************************/
// --- Private imports section functions ---------------------------------------

str _match_generate_imports_section() 
    = _match_generate_separator()
    + _match_generate_title("General modules imports")
    + "import List;"
    + _match_generate_line_break(2)
    ;

/******************************************************************************/
// --- Private data structures section functions -------------------------------

str _match_generate_data_structures_section() 
    = _match_generate_separator()
    + _match_generate_title("Data structure defines")
    + "data GenerationVerbExpression
      '    = generation_verb_expression(str verb, str modifier)
      '    | generation_verb_expression_empty()
      '    ;
      '
      'data GenerationChunk
      '    = generation_chunk(str \\module, list[GenerationVerbExpression] verbs, list[str] objects)
      '    ;
      '
      'data GenerationRow
      '    = generation_row(list[str] objects)
      '    ;
      '
      'data GenerationPattern
      '    = generation_pattern(list[GenerationRow] rows)
      '    | generation_pattern_empty()
      '    ;
      '
      'data Verb 
      '    = verb(
      '        str name, 
      '        str specification, 
      '        str direction, 
      '        int size, 
      '        tuple[tuple[str name, str specification] prev, tuple[str name, str specification] next] dependencies
      '        )
      '    | verb_empty()
      '    ;"
    ;

/******************************************************************************/
// --- Private functions section functions -------------------------------------

str _match_generate_functions_section(int chunk_width, Verb verb, GenerationPattern left, GenerationPattern right) 
    = _match_generate_separator()
    + _match_generate_title("Public functions")
    + _match_generate_function(chunk_width, verb, left, right)
    ;

str _match_generate_function(int chunk_width, Verb verb, GenerationPattern left, GenerationPattern right)
    = _match_generate_function_documentation(verb)
    + _match_generate_function_definition(chunk_width, verb, left, right)
    ;

str _match_generate_function_name(Verb verb)
    = (verb.specification == "") ? "<verb.name>" : "<verb.name>_<verb.specification>"
    ;

str _match_generate_function_documentation(Verb verb)
    = "/*
      ' * @Name:   <_match_generate_function_name(verb)>
      ' * @Desc:   Function to apply the Generation rule associated to the given verb
      ' * @Param:  chunk -\> GenerationChunk to be rewriten
      ' * @Ret:    Rewritten GenerationChunk
      ' */"
    + _match_generate_line_break(1)
    ;

str _match_generate_function_definition(int chunk_width, Verb verb, GenerationPattern left, GenerationPattern right) 
    = "public GenerationChunk (GenerationChunk chunk) <_match_generate_function_name(verb)> = 
      'GenerationChunk (GenerationChunk chunk) 
      '{
      '    for(list[str] pattern: <_match_generate_pattern_left(left)> := chunk.objects) {
      '        if (<_match_generate_mid_condition(chunk_width, left)>) {
      '            chunk.objects = visit(chunk.objects) {
      '                case list[str] p:pattern =\> <_match_generate_pattern_right(right)>
      '            };
      '        }
      '    }
      '    return chunk;
      '};"
    + _match_generate_line_break(2)
    ;

str _match_generate_mid_condition(int chunk_width, GenerationPattern pattern) 
    = "<for(int i <- [0..size(pattern.rows)-1]){>size(mid_<i+1>) == <chunk_width - size(pattern.rows[0].objects)><if(i != size(pattern.rows)-2){> && <}><}>"
    ;

str _match_generate_pattern(GenerationPattern pattern, str side)
    = "[*<if(side == "left"){>str <}>top, <for(int i <- [0..size(pattern.rows)]){><for(str object <- pattern.rows[i].objects){>\"<object>\", <}><if(i != size(pattern.rows)-1){>*<if(side == "left"){>str <}>mid_<i+1>, <}><}> *<if(side == "left"){>str <}>bottom]"
    ; 

str _match_generate_pattern_left(GenerationPattern pattern) 
    = _match_generate_pattern(pattern, "left")
    ;

str _match_generate_pattern_right(GenerationPattern pattern) 
    = _match_generate_pattern(pattern, "right")
    ;

/******************************************************************************/
// --- Private call section functions ------------------------------------------

str _match_generate_calls_section(GenerationChunk chunk, Verb verb)
    = _match_generate_separator()
    + _match_generate_title("Calls")
    + _match_generate_call(chunk, verb)
    ;

str _match_generate_call(GenerationChunk chunk, Verb verb)
    = "<_match_generate_function_name(verb)>(<chunk>);";

/******************************************************************************/
// --- Other private functions -------------------------------------------------

str _match_generate_line_break(int i) 
    = "<for(_ <- [0..i]){>\n<}>";

str _match_generate_separator()
    = "/******************************************************************************/"
    + _match_generate_line_break(1)
    ;

str _match_generate_title(str title)
    = "// --- <title> <for(_ <- [0..(80 - size("// --- <title> "))]){>-<}>"
    + _match_generate_line_break(2)
    ;