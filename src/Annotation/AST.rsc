/*
 * @Module: AST
 * @Desc:   Module that models the ast of the extension
 * @Auth:   Borja Velasco -> code, comments
 */
module Annotation::AST

/******************************************************************************/
// --- Extension syntax structure defines --------------------------------------

/*
 * @Name:   Annotation
 * @Desc:   Structure to model an annotation
 */
data Annotation
    = annotation(str \type, str name, list[Argument] args)   // Name of the verb/module, list of arguments
    ;

/*
 * @Name:   Extension
 * @Desc:   Structure to model an parameter (single param or tuple)
 */
data Argument
    = argument_single(str arg)                            // Single argument
    | argument_tuple(Reference prev, Reference next)      // Tuple argument
    ;

/*
 * @Name:   Reference
 * @Desc:   Structure to model an reference (none or verb)
 */
data Reference
    = reference(str verb_name, list[str] args)
    ;
