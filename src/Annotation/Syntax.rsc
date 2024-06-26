/*
 * @Module: AST
 * @Desc:   Module that models the ast of the verbs
 * @Auth:   Borja Velasco -> code, comments
 */
module Annotation::Syntax

/******************************************************************************/
// --- Layout ------------------------------------------------------------------

layout LAYOUTLIST = LAYOUT* !>> [\t-\n \r \ ];
lexical LAYOUT
    = [\t-\n \r \ ]
    | COMMENT
    ;

/******************************************************************************/
// --- Keywords ----------------------------------------------------------------

keyword AnnotationKeyword 
    = "verb" | "chunk"
    ;

/******************************************************************************/
// --- Lexicals ----------------------------------------------------------------

lexical COMMENT = @category="Comment" "//" (![\n)] | COMMENT)*;

lexical ID = [a-z0-9.A-Z_]+ !>> [a-z0-9.A-Z_] \ AnnotationKeyword;

/******************************************************************************/
// --- Syntax ------------------------------------------------------------------

start syntax Annotation 
    = annotation: '(--' AnnotationKeyword ID ('(' {Argument ','}+ ')')? ')'
    ;

syntax Argument
    = argument_single: ID 
    | argument_tuple: '\<' Reference ',' Reference '\>'
    ;

syntax Reference
    = reference: ID ('(' {ID ','}+ ')')?
    ;