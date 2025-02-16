/*
 * @Module: Chunk
 * @Desc:   Module that contains the functionality for the generation chunk
 * @Auth:   Borja Velasco -> code, comments
 */
module Generation::ADT::Chunk

/******************************************************************************/
// --- General modules imports -------------------------------------------------
import IO;

/******************************************************************************/
// --- Own modules imports -----------------------------------------------------
import Generation::ADT::Verb;

/******************************************************************************/
// --- Data structure defines --------------------------------------------------

/*
 * @Name:   GenerationChunk
 * @Desc:   Data structure that models a generation chunk
 */
data GenerationChunk
    = generation_chunk(
        str name, 
        str \module, 
        list[GenerationVerbExpression] win_verbs, 
        list[GenerationVerbExpression] challenge_verbs
        )
    | generation_chunk_empty()
    ;

/*
 * @Name:   GenerationChunk
 * @Desc:   Data structure that models a chunk
 */
data Chunk
    = chunk(str name, tuple[int width, int height] size, list[str] objects)
    | chunk_empty()
    ;

/******************************************************************************/
// --- Public functions --------------------------------------------------------

Chunk chunk_init(str name, tuple[int width, int height] size) {
    return chunk(name, size, ["." | _ <- [0..(size.width*size.height)]]);
}

list[list[str]] chunk_get_rows(Chunk chunk) {
    list[list[str]] rows= [];

    for (int j <- [0..chunk.size.height]) {
        rows += [chunk_get_row(chunk, j)];
    }

    return rows;
}

list[str] chunk_get_row(Chunk chunk, int index) {
    return chunk.objects[(chunk.size.width*index)..(chunk.size.width*(index+1))];
}

str chunk_to_string(Chunk chunk) {
    str chunk_str = "";

    int i = 0;
    for (str object <- chunk.objects) {
        chunk_str += object;
        chunk_str += "\t";
        i += 1;

        if (i % chunk.size.width == 0) chunk_str += "\n";
    }

    return chunk_str;
}

void chunk_print(Chunk chunk, loc file) {
    str chunk_printed = "";

    chunk_printed += readFile(file);
    chunk_printed += chunk_to_string(chunk);
    
    writeFile(file, chunk_printed);

    return;
}