module Experiments::GenerateRewrite

import IO;
import util::Eval;
import Experiments::AST;

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

str generate_program(Chunk c, Pattern left, Pattern right)
  = "//module Experiments::Crawl
    '
    'data Chunk
    '   = chunk(list[str] objects)
    '   ;
    '
    'data Row
    '   = row(list[str] objects)
    '   ;
    '
    'data Pattern
    '   = pattern(list[Row] rows)
    '   ;
    '
    '
    'public Chunk (Chunk c) crawl = 
    'Chunk (Chunk c) 
    '{
    '   c.objects = visit(c.objects) {
    '       case list[str] p:[*str top,\"<left.rows[0].objects[0]>\",\"<left.rows[0].objects[1]>\",*str mid,\"<left.rows[1].objects[0]>\",\"<left.rows[1].objects[1]>\",*str bottom] =\> [*top,\"<right.rows[0].objects[0]>\",\"<right.rows[0].objects[1]>\",*mid,\"<right.rows[1].objects[0]>\",\"<right.rows[1].objects[1]>\",*bottom]
    '   };
    '   return c;
    '};
    '
    'crawl(<c>);";