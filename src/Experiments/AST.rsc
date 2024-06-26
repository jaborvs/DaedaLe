module Experiments::AST

/******************************************************************************/
// --- Data structure defines --------------------------------------------------

data Chunk
    = chunk(list[str] objects)
    ;

data Pattern
    = pattern(list[list[str]] objects)
    ;