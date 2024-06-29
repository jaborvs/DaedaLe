/*
 * @Module: Pattern
 * @Desc:   Module that contains the functionality for the generation pattern
 * @Auth:   Borja Velasco -> code, comments
 */
module Generation::ADT::Pattern

/******************************************************************************/
// --- General modules imports -------------------------------------------------
import List;

/******************************************************************************/
// --- Own modules imports -----------------------------------------------------
import Utils;

/******************************************************************************/
// --- Data structure defines --------------------------------------------------

/*
 * @Name:   GenerationPattern
 * @Desc:   Data structure that models a generation pattern
 */
data GenerationPattern
    = generation_pattern(list[list[str]] objects)
    | generation_pattern_empty()
    ;

/******************************************************************************/
// --- Pattern functions -------------------------------------------------------

/*
 * @Name:   generation_pattern_get_player_coords
 * @Desc:   Function to get the coords of a player inside a patter. Only used
 *          for enter, idle and exit patterns
 * @Param:  pattern -> Pattern to check
 * @Ret:    Coords of the player
 */
Coords generation_pattern_get_player_coords(GenerationPattern pattern) {
    for (int i <- [0..size(pattern.objects)]) {
        for (int j <- [0..size(pattern.objects[i])]) {
            if (pattern.objects[i][j] == "p" || pattern.objects[i][j] == "ph1") return <j,i>;
        }
    }
    return <-1,-1>;
}