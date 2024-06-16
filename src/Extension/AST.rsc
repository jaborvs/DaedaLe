/*
 * @Module: AST
 * @Desc:   Module that models the ast of the extension
 * @Auth:   Borja Velasco -> code, comments
 */
module Extension::AST

/******************************************************************************/
// --- Extension structure defines ---------------------------------------------

/*
 * @Name:   Extension
 * @Desc:   Structure to model an extension
 */
data Extension
    = extension(str \type, str name)    // Name of the verb/module
    ;