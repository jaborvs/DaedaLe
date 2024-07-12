/*
 * @Module: Match
 * @Desc:   Module that contains the functionality to generate a program that 
 *          enables us to use GenerationPatterns through Rascal's list pattern
 *          matching. 
 *          NOTE: The function to generate the body could be further fragmented,
 *                but for now that is future work
 * @Auth:   Borja Velasco -> code
 */
module Generation::Match

/******************************************************************************/
// --- General modules imports -------------------------------------------------
import IO;
import String;
import List;
import util::Eval;
import util::Math;

/******************************************************************************/
// --- Own modules imports -----------------------------------------------------
import Generation::ADT::Pattern;
import Generation::ADT::Chunk;
import Annotation::ADT::Verb;
import Utils;

void main() {
    VerbAnnotation v = verb_annotation(
        "enasdfasdfter",
        "default",
        "none",
        0,
        <<"none","undefined","undefined">,<"none","undefined","undefined">>
        );

    GenerationPattern left = generation_pattern([
        ["."]
        ]);
    GenerationPattern right = generation_pattern([
        ["#"]
        ]);

    int width = 5;
    int height = 5;
    Chunk c = chunk(
        "Test",
        <5,5>,
        [
            ".",".",".",".",".",
            ".",".",".",".",".",
            ".",".",".",".",".",
            ".",".",".",".",".",
            ".",".",".",".","."
        ]
        );

    str program = match_generate_program(c, <0,2>, v, left, right);
    println(program);
    if(result(Chunk c_r) := eval(program)) {
        c = c_r;
        println(chunk_to_string(c));
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
str match_generate_program(Chunk chunk, Coords player_entry, VerbAnnotation verb, GenerationPattern left, GenerationPattern right) {
    str program = "";
    Coords pattern_entry = <-1,-1>;
    Coords pattern_player = <-1,-1>;

    pattern_entry   = player_entry;
    pattern_entry.x = player_entry.x - generation_pattern_get_player_coords(right).x;
    pattern_entry.y = player_entry.y - generation_pattern_get_player_coords(right).y;

    program += _match_generate_module_section(verb);
    program += _match_generate_imports_section();
    program += _match_generate_data_structures_section();
    program += _match_generate_functions_section(chunk.size, pattern_entry, verb, left, right);
    program += _match_generate_calls_section(chunk, verb);

    return program;
}

/******************************************************************************/
// --- Private module section functions ----------------------------------------

str _match_generate_module_section(VerbAnnotation verb) 
    = "//module Generation::<string_capitalize(verb.name)><string_capitalize(verb.specification)><string_capitalize(verb.direction)>"
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
      'data GenerationPattern
      '    = generation_pattern(list[list[str]] objects)
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
      '    ;
      '\n"
    ;

/******************************************************************************/
// --- Private functions section functions -------------------------------------

str _match_generate_functions_section(tuple[int,int] chunk_size, Coords pattern_entry, VerbAnnotation verb, GenerationPattern left, GenerationPattern right) 
    = _match_generate_separator()
    + _match_generate_title("Public functions")
    + _match_generate_function(chunk_size, pattern_entry, verb, left, right)
    ;

str _match_generate_function(tuple[int,int] chunk_size, Coords pattern_entry, VerbAnnotation verb, GenerationPattern left, GenerationPattern right)
    = _match_generate_function_documentation(verb)
    + _match_generate_function_definition(chunk_size, pattern_entry, verb, left, right)
    ;

str _match_generate_function_name(VerbAnnotation verb)
    = (verb.specification == "") ? "<verb.name>_<verb.direction>" : "<verb.name>_<verb.specification>_<verb.direction>"
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

str _match_generate_function_definition_old(tuple[int,int] chunk_size, Coords entry, VerbAnnotation verb, GenerationPattern left, GenerationPattern right) 
    = "public Chunk (Chunk c) <_match_generate_function_name(verb)> = 
      'Chunk (Chunk c) 
      '{
      '    for(list[str] pattern: <_match_generate_pattern_left(left)> := c.objects) {
      '        if (<_match_generate_mid_condition(chunk_size, entry, verb, left)>) {
      '            c.objects = visit(c.objects) {
      '                case list[str] p:pattern =\> <_match_generate_pattern_right(right)>
      '            };
      '        }
      '    }
      '    return c;
      '};"
    + _match_generate_line_break(2)
    ;

str _match_generate_mid_condition(tuple[int width, int height] chunk_size, Coords entry, VerbAnnotation verb, GenerationPattern pattern) 
    = "<if(verb.name == "enter"){>size(top) == <(chunk_size.width * entry.y + entry.x)> && <}><for(int i <- [0..size(pattern.objects)-1]){>size(mid_<i+1>) == <chunk_size.width - size(pattern.objects[0])><if(i != size(pattern.objects)-2){> && <}><}>"
    ;

str _match_generate_function_definition(tuple[int,int] chunk_size, Coords pattern_entry, VerbAnnotation verb, GenerationPattern left, GenerationPattern right) 
    = _match_generate_function_header(verb)
    + _match_generate_curly_bracket_open(0)
    + _match_generate_function_body(chunk_size, pattern_entry, verb, left, right, 1)
    + _match_generate_function_return(1)
    + _match_generate_curly_bracket_semicolon_close(0)
    + _match_generate_line_break(2)
    ;

str _match_generate_function_header(VerbAnnotation verb)
    = "public Chunk (Chunk c) <_match_generate_function_name(verb)> = 
      'Chunk (Chunk c)"
    ;

str _match_generate_function_body(tuple[int,int] chunk_size, Coords pattern_entry, VerbAnnotation verb, GenerationPattern left, GenerationPattern right, int tabs) 
    = _match_generate_for(chunk_size, pattern_entry, verb, left, right, tabs)
    ;

str _match_generate_function_return(int tabs)
    = _match_generate_tabbed("return c;", tabs)
    ;

str _match_generate_for(tuple[int,int] chunk_size, Coords pattern_entry, VerbAnnotation verb, GenerationPattern left, GenerationPattern right, int tabs)
    = _match_generate_for_header(left, tabs)
    + _match_generate_curly_bracket_open(tabs) 
    + _match_generate_for_body(chunk_size, pattern_entry, verb, left, right, tabs)
    + _match_generate_curly_bracket_close(tabs)
    ;

str _match_generate_for_header(GenerationPattern left, int tabs)
    = _match_generate_tabbed("for(list[str] pattern: <_match_generate_pattern_left(left)> := c.objects)", tabs) 
    ;

str _match_generate_for_body(tuple[int,int] chunk_size, Coords pattern_entry, VerbAnnotation verb, GenerationPattern left, GenerationPattern right, int tabs) 
    = ((verb_is_enter(verb) || size(left.objects) > 1) ? _match_generate_if_header(chunk_size, pattern_entry, verb, left, tabs+1) + _match_generate_curly_bracket_open(tabs+1) : "")
    + ((verb_is_enter(verb) || size(left.objects) > 1) ? _match_generate_if_body(right, tabs+1) : _match_generate_visit(right, tabs+1))
    + ((verb_is_enter(verb) || size(left.objects) > 1) ? _match_generate_curly_bracket_close(tabs+1) : "")
    ;

str _match_generate_if_header(tuple[int,int] chunk_size, Coords pattern_entry, VerbAnnotation verb, GenerationPattern left, int tabs)
    = _match_generate_tabbed("if (<_match_generate_condition(chunk_size, pattern_entry, verb, left)>)", tabs)
    ;

str _match_generate_if_body(GenerationPattern right, int tabs)
    = _match_generate_visit(right, tabs+1)
    ;

str _match_generate_visit(GenerationPattern right, int tabs)
    = _match_generate_tabbed("c.objects = visit(c.objects)", tabs)
    + _match_generate_curly_bracket_open(tabs)
    + _match_generate_tabbed("case list[str] p:pattern =\> <_match_generate_pattern_right(right)>", tabs+1)
    + _match_generate_curly_bracket_semicolon_close(tabs)
    ;

str _match_generate_condition(tuple[int width, int height] chunk_size, Coords pattern_entry, VerbAnnotation verb, GenerationPattern left)
    = (verb_is_enter(verb) ? _match_generate_condition_top(chunk_size, pattern_entry, left) : "")
    + _match_generate_condition_mid(chunk_size, left)
    ;

str _match_generate_condition_top(tuple[int width, int height] chunk_size, Coords pattern_entry, GenerationPattern left)
    = "size(top) == <chunk_size.width * pattern_entry.y + pattern_entry.x>" 
    + ((size(left.objects) > 1) ? " && "  : "")
    ;

str _match_generate_condition_mid(tuple[int width, int height] chunk_size, GenerationPattern left) 
    = "<for(int i <- [0..size(left.objects)-1]){>size(mid_<i+1>) == <chunk_size.width - size(left.objects[0])><if(i != size(left.objects)-2){> && <}><}>"
    ;

str _match_generate_pattern(GenerationPattern pattern, str side)
    = "[*<if(side == "left"){>str <}>top, <for(int i <- [0..size(pattern.objects)]){><for(str object <- pattern.objects[i]){>\"<object>\", <}><if(i != size(pattern.objects)-1){>*<if(side == "left"){>str <}>mid_<i+1>, <}><}> *<if(side == "left"){>str <}>bottom]"
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

str _match_generate_curly_bracket_open(int tabs)
    = _match_generate_line_break(1)
    + _match_generate_tabbed("{",tabs)
    + _match_generate_line_break(1)
    ;

str _match_generate_curly_bracket_close(int tabs)
    = _match_generate_line_break(1)
    + _match_generate_tabbed("}",tabs)
    + _match_generate_line_break(1)
    ;

str _match_generate_curly_bracket_semicolon_close(int tabs)
    = _match_generate_line_break(1)
    + _match_generate_tabbed("};",tabs)
    + _match_generate_line_break(1)
    ;

str _match_generate_tabbed(str string, int tabs) 
    = _match_generate_tabs(tabs) 
    + string
    ;

str _match_generate_tabs(int tabs) 
    = "<for(_ <- [0..tabs]){>    <}>"
    ;