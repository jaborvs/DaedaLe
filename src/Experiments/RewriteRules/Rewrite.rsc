module Experiments::RewriteRules::Rewrite

import IO;
import List;
import String;
import Experiments::RewriteRules::AST;
import util::Math;

void main() {
    Pattern left = pattern([
        ["."],
        ["."]
        ]);
    Pattern right   = pattern([
        ["P"],
        ["#"]
        ]);

    int width = 5;
    int height = 5;
    Chunk c = chunk([
        ".",".",".",".",".",
        ".",".",".",".",".",
        ".",".",".",".",".",
        ".",".",".",".",".",
        ".",".",".",".","."
        ]);

    println("\>\>\> Initial chunk state");
    chunk_print(c, width);
    println();
    println((toInt(height/2)-1) * width);

    for(list[str] pattern: [*str top,".",*str mid, ".",*str bottom] := c.objects) {
        if (size(top) == ((toInt(height/2) - 1) * width)
            && size(mid) == (width - size(left.objects[0]))) {
            c.objects = visit(c.objects) {
                case list[str] p:pattern => [*top,"P",*mid,"#",*bottom]
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