/*
 * @Module: Exception
 * @Desc:   Module that contains all the exceptions to be thrown by the code
 * @Auth:   Borja Velasco -> code, comments
 */
module Annotation::Exception

/******************************************************************************/
// --- Public verb annotation functions ----------------------------------------

void exception_verb_annotation_dependency_invalid_args() {
    throw "Exception VerbAnnotation: The number of arguments for dependencies must be 0, 1 or 2";
}