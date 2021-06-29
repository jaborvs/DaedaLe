module PuzzleScript::AST

data PreludeData 
	= prelude_data(str key, list[str id])
	| prelude_empty()
	;
	
data APrelude 
	= prelude(list[PreludeData])
	| empty()
	;

