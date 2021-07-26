module PuzzleScript::Test::Checker::Tests

import PuzzleScript::Load;
import PuzzleScript::AST;
import PuzzleScript::Checker;
import IO;

void main(){
	println("Legend Errors");
	PSGAME game = load(|project://AutomatedPuzzleScript/src/PuzzleScript/Test/Checker/BadGame1Legend.PS|);
	Checker checker = check_game(game);
	print_msgs(checker);
	println("");
}
