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
	Level level;

	//println("Engine Test");
	//game = load(|project://AutomatedPuzzleScript/src/PuzzleScript/Test/Games/Game1.PS|);
	//checker = check_game(game);
	//engine = compile(checker);
	//engine = plan_move(engine, "right");
	//print_level(engine.current_level);
	
	println("Test Compile");
	game = load(|project://AutomatedPuzzleScript/src/PuzzleScript/Test/Engine/Game1Compile.PS|);
	checker = check_game(game);
	engine = compile(checker); 
	for (x <- engine.rules) println(" late: <x.late>\n commands: <x.commands>\n left: <x.left>\n right: <x.right>");
	
	//println("Rotate Test");
	//game = load(|project://AutomatedPuzzleScript/src/PuzzleScript/Test/Engine/Game1Rotate.PS|);
	//checker = check_game(game);
	//engine = compile(checker);
	//level = rotate_level(engine.levels[0]);
	//print_level(level);
	
	
	//println("Movement Test");
	
	//println("Victory Test");
	//game = load(|project://AutomatedPuzzleScript/src/PuzzleScript/Test/Engine/Game1Victory.PS|);
	//checker = check_game(game);
	//engine = compile(checker);
	//println("Victory: true == <is_victorious(engine)>");
	//engine = change_level(engine, engine.index + 1);
	//println("Victory: false == <is_victorious(engine)>");
	
	//println("Deep Copy Test");
	
	//println("Rewrite Test");
	
}