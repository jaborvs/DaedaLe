module PuzzleScript::AST

data Newlines
	= lines(list[str])
	;

data SyntaxDelimiter
	= delimite(str, Newlines)
	;

data PreludeData 
	= prelude_data(str key, list[str] values, Newlines)
	;
	
data Prelude
	= prelude(list[PreludeData] prelude)
	| empty(Newlines)
	;

data Game
 	= game(Prelude pr, list[Section] sect)
 	| empty(Newlines)
 	;
 	
data Section
 	= objects(Objects objects)
 	//| legend(Legend legend)
 	//| sounds(Sounds sounds)
 	//| layers(Layers layers)
 	//| rules(Rules rules)
 	//| conditions(WinConditions conditions)
 	//| levels(Levels levels)
 	| empty(str, Newlines)
 	;
 	
data Objects
	= objects(SyntaxDelimiter, str, Newlines, SyntaxDelimiter, list[ObjectData] objects)
	;
	
data ObjectData
	= object_data(list[str] id, list[str] colors, Sprite sprite)
	//| object_empty(Newlines)
	;
	
data Sprite 
    =  sprite(list[str])
    ;
