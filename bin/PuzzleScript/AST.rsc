module PuzzleScript::AST

alias Newline = str;
alias Newlines = list[Newline];

data PreludeData 
	= prelude_data(str, list[str], Newlines)
	;
	
data PRELUDE
	= prelude(list[PreludeData])
	| empty(Newlines)
	;

