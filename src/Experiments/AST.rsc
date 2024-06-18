module Experiments::AST

data Chunk
    = chunk(list[str] objects)
    ;

data Pattern
    = pattern(list[Row] rows)
    ;

data Row
    = row(list[str] objects)
    ;