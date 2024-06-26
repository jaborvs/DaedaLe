/*
 * @Module: VerbExpression
 * @Desc:   Module that contains the functionality for the generation verb expr
 * @Auth:   Borja Velasco -> code, comments
 */
module Generation::ADT::VerbExpression

/******************************************************************************/
// --- Data structure defines --------------------------------------------------

/*
 * @Name:   GenerationVerbExpression
 * @Desc:   Data structure that models a generation verb expression
 */
data GenerationVerbExpression
    = generation_verb_expression(str verb, str specification, str direction, str modifier)
    | generation_verb_expression_empty()
    ;