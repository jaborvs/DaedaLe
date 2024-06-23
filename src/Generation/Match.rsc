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
import Generation::ADT::Pattern;
import Generation::ADT::Chunk;
import Annotation::ADT::Verb;
import Utils;

void main() {
    VerbAnnotation v = verb_annotation(
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
    Chunk c = chunk(
        "Test",
        <5,5>,
        [
            ".",".",".",".",".",
            ".","P",".",".",".",
            ".","#",".",".",".",
            ".",".",".",".",".",
            ".",".",".",".","."
        ]
        );

    str program = match_generate_program(c, v, left, right);
    println(program);
    if(result(Chunk c_r) := eval(program)) {
        c = c_r;
        println(c.objects);
    }
}

/******************************************************************************/
// --- Public functions --------------------------------------------------------

/*
 * @Name:   match_generate_program
 * @Desc:   Function that generates the matching program for a given
 *          GenerationRule to rewrite a GenerationChunk
 * @Params: chunk -> Chunk to be rewritten
 *          left  -> Left pattern of the GenerationRule
 *          right -> Right pattern of the GenerationRule
 * @Ret:    str with the complete programm
 */
str match_generate_program(Chunk chunk, VerbAnnotation verb, GenerationPattern left, GenerationPattern right) {
    str program = "";

    program += _match_generate_module_section(verb);
    program += _match_generate_imports_section();
    program += _match_generate_data_structures_section();
    program += _match_generate_functions_section(chunk.size.width, verb, left, right);
    program += _match_generate_calls_section(chunk, verb);

    return program;
}

/******************************************************************************/
// --- Private module section functions ----------------------------------------

str _match_generate_module_section(VerbAnnotation verb) 
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
    + "data Chunk
      '    = chunk(str name, tuple[int width, int height] size, list[str] objects)
      '    | chunk_empty()
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
      'data VerbAnnotation
      '    = verb(
      '        str name, 
      '        str specification, 
      '        str direction, 
      '        int size, 
      '        tuple[tuple[str name, str specification] prev, tuple[str name, str specification] next] dependencies
      '        )
      '    | verb_annotation_empty()
      '    ;"
    ;

/******************************************************************************/
// --- Private functions section functions -------------------------------------

str _match_generate_functions_section(int chunk_width, VerbAnnotation verb, GenerationPattern left, GenerationPattern right) 
    = _match_generate_separator()
    + _match_generate_title("Public functions")
    + _match_generate_function(chunk_width, verb, left, right)
    ;

str _match_generate_function(int chunk_width, VerbAnnotation verb, GenerationPattern left, GenerationPattern right)
    = _match_generate_function_documentation(verb)
    + _match_generate_function_definition(chunk_width, verb, left, right)
    ;

str _match_generate_function_name(VerbAnnotation verb)
    = (verb.specification == "") ? "<verb.name>" : "<verb.name>_<verb.specification>"
    ;

str _match_generate_function_documentation(VerbAnnotation verb)
    = "/*
      ' * @Name:   <_match_generate_function_name(verb)>
      ' * @Desc:   Function to apply the Generation rule associated to the given verb
      ' * @Param:  c -\> Chunk to be rewriten
      ' * @Ret:    Rewritten Chunk
      ' */"
    + _match_generate_line_break(1)
    ;

str _match_generate_function_definition(int chunk_width, VerbAnnotation verb, GenerationPattern left, GenerationPattern right) 
    = "public Chunk (Chunk c) <_match_generate_function_name(verb)> = 
      'Chunk (Chunk c) 
      '{
      '    for(list[str] pattern: <_match_generate_pattern_left(left)> := c.objects) {
      '        if (<_match_generate_mid_condition(chunk_width, left)>) {
      '            c.objects = visit(c.objects) {
      '                case list[str] p:pattern =\> <_match_generate_pattern_right(right)>
      '            };
      '        }
      '    }
      '    return c;
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

str _match_generate_calls_section(Chunk chunk, VerbAnnotation verb)
    = _match_generate_separator()
    + _match_generate_title("Calls")
    + _match_generate_call(chunk, verb)
    ;

str _match_generate_call(Chunk chunk, VerbAnnotation verb)
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