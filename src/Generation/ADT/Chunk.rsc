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
    = generation_chunk(str \module, list[GenerationVerbExpression] verbs, list[str] objects)
    | generation_chunk_empty()
    ;

/******************************************************************************/
// --- Public functions --------------------------------------------------------

void chunk_print(GenerationChunk chunk, int width) {
    file_loc = |project://daedale/src/Interface/bin/chunk.out|;
    str chunk_printed = readFile(file_loc);

    chunk_printed += "\>\>\> Chunk:\n";

    int i = 0;
    for (str object <- chunk.objects) {
        chunk_printed += object;
        chunk_printed += "\t";
        i += 1;

        if (i % width == 0) chunk_printed += "\n";
    }

    chunk_printed += "\n<for(_ <- [0..(width-1)*4]){>-<}>\n\n";
    writeFile(file_loc, chunk_printed);
    return;
}

/*
 * @Name:   chunk_print_verb
 * @Desc:   Function that prints the modification of a verb in chunk
 * @Param:  chunk -> Generation chunk to be printed
 *          width -> Width of the chunk
 *          verb  -> Verb that rewrote the chunk
 * @Ret:    void
 */
void chunk_print_verb(GenerationChunk chunk, int width, Verb verb) {
    file_loc = |project://daedale/src/Interface/bin/chunk.out|;
    str chunk_printed = readFile(file_loc);

    chunk_printed += "\>\>\> Chunk after <verb.name>(<verb.specification>):\n";

    int i = 0;
    for (str object <- chunk.objects) {
        chunk_printed += object;
        chunk_printed += "\t";
        i += 1;

        if (i % width == 0) chunk_printed += "\n";
    }

    chunk_printed += "\n<for(_ <- [0..(width-1)*4]){>-<}>\n\n";
    
    writeFile(file_loc, chunk_printed);
    return;
}