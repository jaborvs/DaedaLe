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

lexical ID = [a-z0-9.A-Z_]+ !>> [a-z0-9.A-Z_] \ ExtensionKeyword;

/******************************************************************************/
// --- Syntax ------------------------------------------------------------------

start syntax Extension 
    = extension: '(' ExtensionKeyword ID ('(' {Argument ','}+ ')')? ')'
    ;

syntax Argument
    = argument_single: ID 
    | argument_tuple: '\<' Reference ',' Reference '\>'
    ;

syntax Reference
    = reference_none: ID
    | reference_verb: ID '(' ID ')'
    ;