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
    = extension(str \type, str name, list[str] params)  // Name of the verb/module, list of parameters
    ;

/*
 * @Name:   Extension
 * @Desc:   Structure to model an verb
 */
data Verb 
    = verb(str name, str specification, str direction, int size, str dependency)
    | verb_empty()
    ;

/*
 * @Name:   Extension
 * @Desc:   Structure to model an module
 */
data Module
    = \module(str name)
    | module_empty()
    ;