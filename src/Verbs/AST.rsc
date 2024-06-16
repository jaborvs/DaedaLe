/*
 * @Module: AST
 * @Desc:   Module that models the ast of the verbs
 * @Auth:   Borja Velasco -> code, comments
 */
module Verbs::AST

/******************************************************************************/
// --- Verb structure defines --------------------------------------------------

/*
 * @Name:   Verb
 * @Desc:   Structure to model a verb
 */
data Verb
    = verb(str name)    // Name of the verb
    ;