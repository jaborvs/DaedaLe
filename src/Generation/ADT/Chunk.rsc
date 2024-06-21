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

/*
 * @Name:   chunk_print
 * @Desc:   Function that prints a chunk in a file
 * @Param:  chunk -> Generation chunk to be printed
 *          width -> Width of the chunk
 *          height -> Height of the chunk
 *          name -> Name of the verb just applied
 *          specification -> Specification of the verb just applied
 * @Ret:    void
 */
void chunk_print(GenerationChunk chunk, int width, str name, str specification) {
    file_loc = |project://daedale/src/Interface/bin/chunk.out|;
    str chunk_printed = readFile(file_loc);

    if (toLowerCase(name) == "initial state") chunk_printed += "\>\>\> <name>:\n\n";
    else                                      chunk_printed += "\>\>\> Verb <name>(<specification>)\n\n";

    int i = 0;
    for (str object <- chunk.objects) {
        chunk_printed += object;
        chunk_printed += "\t";
        i += 1;

        if (i % width == 0) chunk_printed += "\n";
    }

    chunk_printed += "\n<for(_ <- [0..(width-1)*4]){>-<}>\n";
    
    writeFile(file_loc, chunk_printed);
    return;
}