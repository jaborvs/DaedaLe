/*
 * @Module: Pattern
 * @Desc:   Module that contains the functionality for the generation pattern
 * @Auth:   Borja Velasco -> code, comments
 */
module Generation::ADT::Pattern

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