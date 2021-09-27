module PuzzleScript::Test::Analyser::Tests

import PuzzleScript::Load;
import PuzzleScript::Compiler;
import PuzzleScript::Checker;
import PuzzleScript::AST;
import PuzzleScript::Analyser;
import PuzzleScript::Messages;

import IO;

void main() {
	PSGAME game;
	Checker checker;
	Engine engine;
	DynamicChecker d_checker;
	
	//println("Instant Victory");
	//game = load(|project://AutomatedPuzzleScript/src/PuzzleScript/Test/Analyser/BadGame1InstantVictory.PS|);
	//checker = check_game(game);
	//engine = compile(checker);
	//d_checker = analyse_game(engine);
	//print_msgs(checker);
	
	println("Rule Similarity");
	game = load(|project://AutomatedPuzzleScript/src/PuzzleScript/Test/Analyser/BadGame1InstantVictory.PS|);
	checker = check_game(game);
	engine = compile(checker);
	d_checker = analyse_game(engine);
	print_msgs(d_checker);
	
}
 