module PuzzleScript::Load

import PuzzleScript::Syntax;
import PuzzleScript::AST;
import ParseTree;

PSGame parse(loc path){
	return parse(#PSGame, path);
}

PSGAME implode(PSGame tree) {
	return implode(#PSGAME, tree);
}

PSGAME load(loc path) {
	return implode(annotate(parse(path)));
}

PSGame annotate(PSGame tree) {
	// annotate tree
	
	return tree;
}

PSGAME check(PSGAME game) {
	// check contents, return error message etc...
	
	return game;

}