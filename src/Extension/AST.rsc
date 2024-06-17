/*
 * @Module: AST
 * @Desc:   Module that models the ast of the extension
 * @Auth:   Borja Velasco -> code, comments
 */
module Extension::AST

/******************************************************************************/
// --- Extension syntax structure defines --------------------------------------

/*
 * @Name:   Extension
 * @Desc:   Structure to model an extension
 */
data Extension
    = extension(str \type, str name, list[Argument] args)   // Name of the verb/module, list of arguments
    ;

/*
 * @Name:   Extension
 * @Desc:   Structure to model an parameter (single param or tuple)
 */
data Argument
    = argument_single(str val)                            // Single argument
    | argument_tuple(list[str] vals)                      // Tuple argument
    ;

/******************************************************************************/
// --- Other structure defines -------------------------------------------------

/*
 * @Name:   Extension
 * @Desc:   Structure to model an verb
 */
data Verb 
    = verb(
        str name, 
        str specification, 
        str direction, 
        int size, 
        tuple[tuple[str,str] prev, tuple[str,str] next] dependency
        )
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