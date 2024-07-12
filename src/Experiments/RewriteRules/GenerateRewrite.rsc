module Experiments::RewriteRules::GenerateRewrite

import IO;
import String;
import List;
import util::Eval;
import Experiments::RewriteRules::AST;

void main() {
    Pattern left = pattern([
        row(["P","."]),
        row(["#","."])
        ]);
    Pattern right   = pattern([
        row(["H","P"]),
        row(["#","#"])
        ]);

    int width = 5;
    int height = 5;
    Chunk c = chunk([
        ".",".",".",".",".",
        ".","P",".",".",".",
        ".","#",".",".",".",
        ".",".",".",".",".",
        ".",".",".",".","."
        ]);

    str program = generate_program(c, left, right);
    println(program);
    if(result(Chunk c) := eval(program)) {
        println(c);
    }
}

str generate_program(Chunk c, Pattern left, Pattern right) {
    str program = "";
    str imports = "";
    str left_str = "";
    str right_str = "";

    imports = readFile(|project://daedale/src/Experiments/AST.rsc|);
    imports 
        = "/******************************************************************************/"
        + split(
            "/******************************************************************************/",
            imports
            )[1];

    left_str  = "[*str top, <for(int i <- [0..size(left.rows)]){><for(str object <- left.rows[i].objects){>\"<object>\", <}><if(i != size(left.rows)-1){>*str mid_<i+1>, <}><}> *str bottom]"; 
    right_str = "[*top, <for(int i <- [0..size(right.rows)]){><for(str object <- right.rows[i].objects){>\"<object>\", <}><if(i != size(right.rows)-1){>*mid_<i+1>, <}><}> *bottom]"; 

    program = "//module Experiments::Crawl
    '
    '<imports>
    '
    '/******************************************************************************/
    '// --- VerbAnnotationrewrite rule function ----------------------------------------------
    ' 
    'public Chunk (Chunk c) crawl = 
    'Chunk (Chunk c) 
    '{
    '   c.objects = visit(c.objects) {
    '       case list[str] p:<left_str> =\> <right_str>
    '   };
    '   return c;
    '};
    '
    'crawl(<c>);";

    return program;
}