module Experiments::Rewrite

import IO;
import List;
import String;
import Experiments::AST;

void main() {
    Pattern left = pattern([
        row([".","."]),
        row(["P","."])
        ]);
    Pattern right   = pattern([
        row(["P","."]),
        row(["H","."])
        ]);

    int width = 5;
    int height = 5;
    Chunk c = chunk([
        ".",".",".",".",".",
        ".",".",".",".",".",
        ".",".",".",".",".",
        ".",".","P",".",".",
        ".",".","#",".","."
        ]);

    println("\>\>\> Initial chunk state");
    chunk_print(c, width);
    println();

    for(list[str] pattern: [*str top,"P",".",*str mid,"#",".",*str bottom] := c.objects) {
        if (size(mid) == (width - size(left.rows[0].objects))) {
            c.objects = visit(c.objects) {
                case list[str] p:pattern => [*top,"H","P",*mid,"#","#",*bottom]
            };
        }
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