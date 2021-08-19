module PuzzleScript::Test::Analyser::Tests

import PuzzleScript::Load;
import PuzzleScript::Engine;
import PuzzleScript::Checker;
import PuzzleScript::AST;
import PuzzleScript::Analyser;
import PuzzleScript::Messages;

import IO;

void main() {
	PSGAME game;
	Checker checker;
	Engine engine;
	
	println("Instant Victory");
	game = load(|project://AutomatedPuzzleScript/src/PuzzleScript/Test/Analyser/BadGame1InstantVictory.PS|);
	checker = check_game(game);
	engine = compile(checker);
	checker = analyse_game(engine, checker);
	print_msgs(checker);
}
 