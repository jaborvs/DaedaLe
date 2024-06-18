module Experiments::Rewrite

import IO;

data Chunk
    = chunk(list[str] objects)
    ;

data Pattern
    = pattern(list[Row] rows)
    ;

data Row
    = row(list[str] objects)
    ;

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

    println("\>\>\> Initial chunk state");
    chunk_print(c, width);
    println();

    c.objects = visit(c.objects) {
        case list[str] p:[*str top,"P",".",*str mid,"#",".",*str bottom] => [*top,"H","P",*mid,"#","#",*bottom]
    }

    println("\>\>\> Final chunk state");
    chunk_print(c, width);
}

void chunk_print(Chunk chunk, int width) {
    str chunk_printed = "";

    int i = 0;
    for (str object <- chunk.objects) {
        chunk_printed += object;
        i += 1;

        if (i % width == 0) chunk_printed += "\n";
    }
    
    print(chunk_printed);
    return;
}