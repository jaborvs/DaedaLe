module PuzzleScript::Test::Implode::Tests

import PuzzleScript::Syntax;
import PuzzleScript::AST;
import ParseTree;

void main(){
	PSGame game = parse(
		#PSGame,
		|project://AutomatedPuzzleScript/src/PuzzleScript/Test/Implode/Test1.PS|
	);
	
	Game g = implode(
		#Game,
		game
	);
}
