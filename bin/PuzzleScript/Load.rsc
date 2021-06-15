module PuzzleScript::Load

import PuzzleScript::Syntax;
import ParseTree;

void main(){
	PSGame game1 = parse(#PSGame, |project://AutomatedPuzzleScript/src/PuzzleScript/Test/Test.PS|);
}

//import PuzzleScript::AST;
//game2 = implode(#Game, game1);
