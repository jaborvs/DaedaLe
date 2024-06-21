/*
 * @Module: Verb
 * @Desc:   Module that contains all the module extension functionality
 * @Auth:   Borja Velasco -> code, comments
 */

module Extension::ADT::Module

/******************************************************************************/
// --- Data structure defines --------------------------------------------------

/*
 * @Name:   Extension
 * @Desc:   Structure to model an module
 */
data Module
    = \module(str name)
    | module_empty()
    ;