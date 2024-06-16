// /*
//  * @Module: Engine
//  * @Desc:   Module that includes all the functionality to generate the desired 
//  *          tutorial levels
//  * @Auth:   Borja Velasco -> code, comments
//  */
module Generation::Engine

// /******************************************************************************/
// // --- General modules imports -------------------------------------------------
// import util::Math;
// import List;
// import IO;

// /******************************************************************************/
// // --- Own modules imports -----------------------------------------------------
// import PuzzleScript::Utils; // Imported just to get the coords

// /******************************************************************************/
// // --- Data Structure Defninitons ----------------------------------------------

// /*
//  * @Name:   Level
//  * @Desc:   Data structure that models a generated level 
//  */
// data Level 
//     = level(
//         map[Coords, Chunk] tilemap
//         )
//     | level_empty()
//     ;

// /*
//  * @Name:   Chunk
//  * @Desc:   Data structure that models a chunk
//  */
// data Chunk
//     = chunk(list[Row] rows)
//     | chunk_empty()
//     ;

// /*
//  * @Name:   Row
//  * @Desc:   Data structure that models a row of a chunk
//  */
// data Row
//     = row(list[Cell] cells)
//     | row_empty()
//     ;

// /*
//  * @Name:   Cell
//  * @Desc:   Data structure that models a cell of a row
//  */
// data Cell
//     = cell(str object)
//     ;

// /******************************************************************************/
// // --- Public Generation Functions ---------------------------------------------

// // /*
// //  * @Name:   generate
// //  * @Desc:   Function that generates all the specified levels
// //  * @Params: 
// //  * @Ret:    list[list[str]] given that a level is a list[str] and we are
// //  *          returning all levels generated
// //  */
// // list[list[str]] generate(GenerationEngine engine) {
// //     list[list[str]] generated_levels = [];

// //     generated_levels = _generate_levels(engine);

// //     return generated_levels;
// // }

// // /******************************************************************************/
// // // --- Private Generation Functions --------------------------------------------

// // /*
// //  * @Name:   _generate_levels
// //  * @Desc:   Function that generates all the specified levels
// //  * @Params: 
// //  * @Ret:    list[list[str]] given that a level is a list[str] and we are
// //  *          returning all levels generated
// //  */
// // list[list[str]] _generate_levels(GenerationEngine engine) {
// //     list[list[str]] generated_levels = [_generate_level(engine, level_draft) | LevelDraftData level_draft <- engine.level_drafts];
// //     return generated_levels;
// // }

// // /*
// //  * @Name:   _generate_level
// //  * @Desc:   Function that generates a single level from a given draft
// //  * @Params: 
// //  * @Ret:    list[list[str]] given that a level is a list[str] and we are
// //  *          returning all levels generated
// //  */
// // list[str] _generate_level(GenerationEngine engine, LevelData level) {
// //     list[Chunk] generated_chunks = [_generate_chunk() | ChunkData chunk_dt <- level.chunks];
// //     return [];
// // }

// // /*
// //  * @Name:   _generate_chunk
// //  * @Desc:   Function that generates a chunk from a given chunk data
// //  * @Params:
// //  * @Ret:    Generated chunk object
// //  */
// // Chunk _generate_chunk(ChunkData chunk_dt) {
// //     Chunk generated_chunk = _chunk_init();


// //     return;
// // }


// /******************************************************************************/
// // --- Private Chunk Functions -------------------------------------------------

// /*
//  * @Name:   _chunk_init
//  * @Desc:   Function to create a blank chunk that is only filled with background
//  *          objects
//  * @Params:
//  * @Ret:    A blank chunk object
//  */
// Chunk _chunk_init(int height, int width) {
//     return chunk([_row_init(width) | _ <- [0..height]]);
// }

// /*
//  * @Name:   _chunk_concretize
//  * @Desc:   Function that concretizes the verbs to be applied in a chunk. It 
//  *          transforms a regular-like expresion such as [crawl+, climb+] to an
//  *          specific sequence of verbs
//  * @Param:
//  * @Ret:    List of concretized verbs
//  */
// list[str] _chunk_concretize(list[str] verb_dts, Coords position_start, int height, int width) {
//     int subchunk_nums = size(verb_dts);
//     list[list[str]] verbs_concretized = [[] | _ <- [0..subchunk_nums]];

//     tuple[int up, int right, int down] verbs_to_exit_num = <
//         height - position_start.y,
//         width - position_start.x,
//         position_start.y + 1
//         >;
//     println(verbs_to_exit_num);

//     tuple[bool up, bool right, bool down] exited = <
//         false, 
//         false, 
//         false
//         >;

//     tuple[int up, int right, int down] verbs_used_num = <
//         0,
//         0,
//         0
//         >;

//     while (!exited.up && !exited.right && !exited.down) {
//         int i = arbInt(subchunk_nums);
//         verbs_concretized[i] += [verb_dts[i]];

//         if      (verb_dts[i] == "climb") verbs_used_num.up += 1;
//         else if (verb_dts[i] == "crawl") verbs_used_num.right += 1;
//         else if (verb_dts[i] == "fall")  verbs_used_num.down += 1;

//         println("   <i>: <verbs_used_num>");

//         if      (verbs_used_num.up    == verbs_to_exit_num.up)    exited.up = true;
//         else if (verbs_used_num.right == verbs_to_exit_num.right) exited.right = true;
//         else if (verbs_used_num.down  == verbs_to_exit_num.down)  exited.down = true;
//     }

//     return concat(verbs_concretized);
// }

// /******************************************************************************/
// // --- Private Row Functions ---------------------------------------------------

// /*
//  * @Name:   _row_init
//  * @Desc:   Function to create a blank row filled only with background objects
//  * @Params:
//  * @Ret:    A blank row
//  */
// Row _row_init(int length) {
//     return row([_cell_init() | _ <- [0..length]]);
// }

// /******************************************************************************/
// // --- Private Cell Functions --------------------------------------------------

// /*
//  * @Name:   _cell_init
//  * @Desc:   Function to create a blan cell filled with a background object
//  * @Params:
//  * @Ret:    A blank cell
//  */
// Cell _cell_init() {
//     return cell(".");
// }