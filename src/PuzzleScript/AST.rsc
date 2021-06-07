module PuzzleScript::AST

data ID = id(str id);

data Game
 	= game(
 		//Prelude prelude 
 		Objects objects 
 		//Legend legend, 
 		//Sounds sounds, 
 		//Layers layers, 
 		//Rules rules, 
 		//WinConditions win,
 		//Levels levels
 	);

// need to fix prelude currently the storage system is very dumb
// Prelude is currently is a list of PreludeData and PreludeData 
// is an item that can have one of either title, author or homepage
// as attributes, ideally, I'd just want to store them as a map or a 
// list of key-value tuples but I don't know how to.
// I have:
//[PreludeData(author=["John", "Doe"]), PreludeData(title=["Simple", "Game"])]
//
// I want something like:
//[
//	PreludeData(key=PreludeKey.author, value=["John", "Doe"]), 
//	PreludeData(key=PreludeKey.title, value=["Simple", "Game"])
//]
data Prelude
	= prelude(list[PreludeData] preludes)
	|empty_prelude()
	;
	
data PreludeData
	= title(list[ID] title)
	|author(list[ID] author)
	|homepage(list[ID] homepage)
	;

data Objects
	= objects(list[ObjectData] objects)
	|empty_objects()
	;

data ObjectData
	= object(ID name, list[Color] colors, Sprite sprite);
	
data Color
   = black()
    |white()
    |lightgray()
    |gray()
    |darkgray()
    |red()
    |darkred()
    |lightred()
    |brown()
    |darkbrown()
    |lightbrown()
    |orange()
    |yellow()
    |green()
    |darkgreen()
    |lightgreen()
    |blue()
    |lightblue()
    |darkblue()
    |purple()
    |pink()
    |transparent()
    ;
    
data Sprite = sprite(list[str] sprite);

data Legend
	= empty()
	;

data Sounds
	= empty()
	;

data Layers
	= empty()
	;

data Rules
	= empty()
	;
	
data WinConditions
	= empty()
	;
	
data Levels
	= empty()
	;