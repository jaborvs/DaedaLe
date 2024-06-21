/*
 * @Module: Pattern
 * @Desc:   Module that contains the functionality for the generation pattern
 * @Auth:   Borja Velasco -> code, comments
 */
module Generation::ADT::Pattern

/******************************************************************************/
// --- Data structure defines --------------------------------------------------

/*
 * @Name:   GenerationRow
 * @Desc:   Data structure that models a generation row
 */
data GenerationRow
    = generation_row(list[str] objects)
    ;

/*
 * @Name:   GenerationPattern
 * @Desc:   Data structure that models a generation pattern
 */
data GenerationPattern
    = generation_pattern(list[GenerationRow] rows)
    | generation_pattern_empty()
    ;