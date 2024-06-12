/*
 * @Module: Engine
 * @Desc:   Module that includes all the functionality to generate the desired 
 *          tutorial levels
 * @Auth:   Borja Velasco -> code, comments
 */
module Generation::Engine

/******************************************************************************/
// --- Own modules imports -----------------------------------------------------
import PuzzleScript::Utils; // Imported just to get the coords

/******************************************************************************/
// --- Data Structure Defninitons ----------------------------------------------

data Level 
    = level(
        Chunk origin,
        map[Coords, Chunk] tilemap
        )
    | level_empty()
    ;

data Chunk
    = chunk(
        Chunk up, bool connected_up,
        Chunk right, bool connected_right,
        Chunk down, bool connected_down
        )
    | chunk_empty()
    ;

/******************************************************************************/
// --- Public Generation Functions ---------------------------------------------

/*
 * @Name:   generate
 * @Desc:   Function that generates all the specified levels
 * @Params: 
 * @Ret:    list[list[str]] given that a level is a list[str] and we are
 *          returning all levels generated
 */
list[list[str]] generate(GenerationEngine engine) {
    list[list[str]] generated_levels = [];

    generated_levels = _generate_levels(engine);

    return generated_levels;
}

/******************************************************************************/
// --- Private Generation Functions --------------------------------------------

/*
 * @Name:   _generate_levels
 * @Desc:   Function that generates all the specified levels
 * @Params: 
 * @Ret:    list[list[str]] given that a level is a list[str] and we are
 *          returning all levels generated
 */
list[list[str]] _generate_levels(GenerationEngine engine) {
    list[list[str]] generated_levels = [_generate_level(engine, level_draft) | LevelDraftData level_draft <- engine.level_drafts];
    return generated_levels;
}

/*
 * @Name:   _generate_level
 * @Desc:   Function that generates a single level from a given draft
 * @Params: 
 * @Ret:    list[list[str]] given that a level is a list[str] and we are
 *          returning all levels generated
 */
list[str] _generate_level(GenerationEngine engine, LevelData level) {
    
    return [];
}