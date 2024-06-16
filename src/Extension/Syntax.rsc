/*
 * @Module: AST
 * @Desc:   Module that models the ast of the verbs
 * @Auth:   Borja Velasco -> code, comments
 */
module Extension::Syntax

/******************************************************************************/
// --- Layout ------------------------------------------------------------------

layout LAYOUTLIST = LAYOUT* !>> [\t-\n \r \ ];
lexical LAYOUT
    = [\t-\n \r \ ]
    | COMMENT
    ;

/******************************************************************************/
// --- Keywords ----------------------------------------------------------------

keyword ExtensionKeyword 
    = "verb" | "module"
    ;

/******************************************************************************/
// --- Lexicals ----------------------------------------------------------------

lexical COMMENT = @category="Comment" "//" (![\n)] | COMMENT)*;

lexical ID = [a-z0-9.A-Z_]+ !>> [a-z0-9.A-Z_] \ Keywords;

/******************************************************************************/
// --- Syntax ------------------------------------------------------------------

start syntax Extension 
    = extension: '(' ExtensionKeyword ID ')'
    ;