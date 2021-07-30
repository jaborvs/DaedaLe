module PuzzleScript::Test::Checker::Tests

import PuzzleScript::Load;
import PuzzleScript::AST;
import PuzzleScript::Checker;
import IO;

void main(){
	PSGAME game;
	Checker checker;

	//println("Resolve Reference");
	//game = load(|project://AutomatedPuzzleScript/src/PuzzleScript/Test/Checker/Game1ResolveLegend.PS|);
	//checker = check_game(game);
	//println(checker.objects);
	//println(checker.references);
	//println(checker.combinations);
	//print_msgs(checker);
	//println();

	//println("Legend Errors");
	//game = load(|project://AutomatedPuzzleScript/src/PuzzleScript/Test/Checker/BadGame1Legend.PS|);
	//checker = check_game(game);
	//print_msgs(checker);
	//println();
	
	//println("Layer Errors");
	//game = load(|project://AutomatedPuzzleScript/src/PuzzleScript/Test/Checker/BadGame1Layers.PS|);
	//checker = check_game(game);
	//print_msgs(checker);
	//println();
	
	//println("Level Errors");
	//game = load(|project://AutomatedPuzzleScript/src/PuzzleScript/Test/Checker/BadGame1Levels.PS|);
	//checker = check_game(game);
	//print_msgs(checker);
	//println();
	
	//println("Sound Errors");
	//game = load(|project://AutomatedPuzzleScript/src/PuzzleScript/Test/Checker/BadGame1Sounds.PS|);
	//checker = check_game(game);
	//println(checker.sound_events);
	//print_msgs(checker);
	//println();
	
	//println("Condition Errors");
	//game = load(|project://AutomatedPuzzleScript/src/PuzzleScript/Test/Checker/BadGame1Conditions.PS|);
	//checker = check_game(game);
	//println(checker.conditions);
	//print_msgs(checker);
	//println();
	
	println("Prelude Errors");
	game = load(|project://AutomatedPuzzleScript/src/PuzzleScript/Test/Checker/BadGame1Prelude.PS|);
	checker = check_game(game);
	print_msgs(checker);
	println();
}
