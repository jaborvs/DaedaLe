/*
 * @Module: Verb
 * @Desc:   Module that contains the functionality for the generation verbs
 * @Auth:   Borja Velasco -> code, comments
 */
module Generation::ADT::Verb

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

/*
 * @Name:   GenerationVerbExpression
 * @Desc:   Data structure that models a concretized generation verb
 */
data GenerationVerbConcretized
    = generation_verb_concretized(str name, str specification, str direction)
    | generation_verb_concretized_empty()
    ;