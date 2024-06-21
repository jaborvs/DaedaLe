/*
 * @Module: LevelDraft
 * @Desc:   Module that contains the functionality for the generation level draft
 * @Auth:   Borja Velasco -> code, comments
 */
module Generation::ADT::LevelDraft

/******************************************************************************/
// --- Own modules imports -----------------------------------------------------
import Generation::ADT::Chunk;

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