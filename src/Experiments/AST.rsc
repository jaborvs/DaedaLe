module Experiments::AST

/******************************************************************************/
// --- Data structure defines --------------------------------------------------

data Chunk
    = chunk(list[str] objects)
    ;

data Row
    = row(list[str] objects)
    ;

data Pattern
    = pattern(list[Row] rows)
    ;