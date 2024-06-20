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
    | argument_tuple(Reference prev, Reference next)      // Tuple argument
    ;

/*
 * @Name:   Extension
 * @Desc:   Structure to model an reference (none or verb)
 */
data Reference
    = reference_none(str val)
    | reference_verb(str verb_name, str verb_specification)
    ;
