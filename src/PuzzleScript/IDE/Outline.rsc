module PuzzleScript::IDE::Outline

import ParseTree;
import PuzzleScript::AST;

anno loc node@\loc;
anno str node@label;

public node outlineGame(PSGAME g) = outline(g);

node outline(PSGAME g) 
	= "outline"([outline(g.objects)]);

node outline(list[OBJECTDATA] objs) 
	= "objects"([ outline(obj) | obj <- objs])[@label = "Objects"];

node outline(obj:object_data(str id, list[str] _, list[str] _, list[list[PIXEL]] _)) 
	= "object"()[@label=id][@\loc=obj@location];


