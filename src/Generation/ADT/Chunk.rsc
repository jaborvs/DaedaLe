/*
 * @Module: Chunk
 * @Desc:   Module that contains the functionality for the generation chunk
 * @Auth:   Borja Velasco -> code, comments
 */
module Generation::ADT::Chunk

/******************************************************************************/
// --- General modules imports -------------------------------------------------
import IO;
import String;

/******************************************************************************/
// --- Own modules imports -----------------------------------------------------
import Generation::ADT::VerbExpression;
import Extension::ADT::Verb;

/******************************************************************************/
// --- Data structure defines --------------------------------------------------

/*
 * @Name:   GenerationChunk
 * @Desc:   Data structure that models a generation chunk
 */
data GenerationChunk
    = generation_chunk(str \module, list[GenerationVerbExpression] verbs)
    | generation_chunk_empty()
    ;

/*
 * @Name:   GenerationChunk
 * @Desc:   Data structure that models a chunk
 */
data Chunk
    = chunk(tuple[int width, int height] size, list[str] objects)
    | chunk_empty()
    ;

/******************************************************************************/
// --- Public functions --------------------------------------------------------

Chunk chunk_init(tuple[int width, int height] size) {
    return chunk(size, ["." | _ <- [0..(size.width*size.height)]]);
}

list[list[str]] chunk_get_rows(Chunk chunk) {
    list[list[str]] rows= [];

    for (int j <- [0..chunk.size.height]) {
        rows += [chung_get_row(chunk, j)];
    }

    return rows;
}

list[str] chunk_get_row(Chunk chunk, int index) {
    return chunk.objects[(chunk.size.width*index)..(chunk.size.width*(index+1))];
}

str chunk_print(Chunk chunk) {
    str chunk_printed = "";

    int i = 0;
    for (str object <- chunk.objects) {
        chunk_printed += object;
        chunk_printed += "\t";
        i += 1;

        if (i % chunk.size.width == 0) chunk_printed += "\n";
    }

    return chunk_printed;
}

void chunk_print(Chunk chunk, loc file) {
    str chunk_printed = "";

    chunk_printed += readFile(file);
    chunk_printed += chunk_print(chunk);
    
    writeFile(file, chunk_printed);

    return;
}