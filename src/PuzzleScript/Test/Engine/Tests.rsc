module PuzzleScript::Test::Engine::Tests

import PuzzleScript::Load;
import PuzzleScript::Engine;
import PuzzleScript::Checker;
import PuzzleScript::AST;
import IO;

void main() {
	PSGAME game;
	Checker checker;
	Engine engine;

	println("Engine Test");
	game = load(|project://AutomatedPuzzleScript/src/PuzzleScript/Test/Games/Game1.PS|);
	checker = check_game(game);
	engine = compile(checker);
	engine = do_move(engine, "right");
	print_level(engine.current_level);
	
	//println("Movement Test");
	//
	//println("Victory Test");
	//
	//println("Deep Copy Test");
	//
	//println("Rewrite Test");
	
}