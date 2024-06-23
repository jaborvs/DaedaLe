/*
 * @Module: Level
 * @Desc:   Module that contains the functionality for the generation level draft
 * @Auth:   Borja Velasco -> code, comments
 */
module Generation::ADT::Level

/******************************************************************************/
// --- General modules imports -------------------------------------------------
import List;
import IO;

/******************************************************************************/
// --- Own modules imports -----------------------------------------------------
import Generation::ADT::Chunk;
import Utils;

/******************************************************************************/
// --- Data structure defines --------------------------------------------------

/*
 * @Name:   GenerationLevel
 * @Desc:   Data structure that models a generation level draft
 */
data GenerationLevel
    = generation_level(list[GenerationChunk] chunks)
    | generation_level_empty()
    ;

/*
 * @Name:   Level
 * @Desc:   Data structure that models a level. 
 *          NOTE: The chunk coordinates are as following: moving up implies 
 *                substracting to y, moving down implies adding to y, moving 
 *                right implies addint to x. This has to do with how chunks are 
 *                strings, and to model coords over them we needed to follow
 *                the same abstraction
 */
data Level
    = level(
        str name,
        tuple[int y_max, int x_max, int y_min] abs_size,
        tuple[int width, int height] chunk_size,
        map[Coords coords, Chunk chunks] chunks_generated
        )        
    | level_empty()
    ;

/******************************************************************************/
// --- Public functions --------------------------------------------------------

Level level_init(str name, tuple[int width, int height] chunk_size) {
    return level(name, <0,0,0>, chunk_size, ());
}

list[list[str]] level_get_rows(Level level) {
    list[list[str]] rows= [];

    for (int j <- [level.abs_size.y_min..(level.abs_size.y_max+1)]){

        // Step 1: We take the row formed by chunks
        list[Chunk] row_chunks = [];
        for (int i <- [0..(level.abs_size.x_max+1)]) {
            Chunk chunk = (<i,j> in level.chunks_generated.coords) ? level.chunks_generated[<i,j>] : chunk_init("blank", level.chunk_size);
            row_chunks += [chunk];
        }

        // Step 2: We take the desired row from each of the row chunks
        for (int r <- [0..level.chunk_size.height]) {
            list[str] row = [];
            for (Chunk chunk <- row_chunks) {
                row += chunk_get_row(chunk, r);
            }
            rows += [row];
        }
    }
    return rows;
}

list[str] level_get_row(Level level, int index) {
    return level_get_rows(level)[index];
}

void level_print(Level level, loc file) {
    str level_printed = "";

    level_printed += readFile(file);
    level_printed += level_to_string(level);

    writeFile(file, level_printed);

    return;
} 

str level_to_string(Level level) {
    str level_str = "";
    
    list[list[str]] rows = level_get_rows(level);
    
    level_str += level_print_name(level);
    level_str += level_print_rows(rows);

    return level_str;
}

str level_print_name(Level level) {
    return "\>\>\> Level <level.name>:\n\n";
}

str level_print_rows(list[list[str]] rows) {
    str level_printed = "";

    for(int i <- [0..size(rows)]) {
        for(int j <- [0..size(rows[i])]) {
            level_printed += rows[i][j];
            level_printed += "\t";
        }
        level_printed += "\n";
    }

    return level_printed;
}