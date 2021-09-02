module PuzzleScript::Test::Engine::Tests

import PuzzleScript::Load;
import PuzzleScript::Engine;
import PuzzleScript::Compiler;
import PuzzleScript::Checker;
import PuzzleScript::AST;
import IO;
import util::Eval;

void main() {
	PSGAME game;
	Checker checker;
	Engine engine;
	Level level;

	//println("Engine Test");
	//game = load(|project://AutomatedPuzzleScript/src/PuzzleScript/Test/Games/Game1.PS|);
	//checker = check_game(game);
	//engine = compile(checker);
	//level = plan_move(engine.levels[0], "right");
	//print_level(level);
	
	println("Test Compile");
	game = load(|project://AutomatedPuzzleScript/src/PuzzleScript/Test/Engine/Game1Rules.PS|);
	checker = check_game(game);
	engine = compile(checker);
	println(engine.rules[0].left[0]);
	println();
	println(engine.rules[0].right[0]);
	//println(engine.levels[0].layers);
	//Result[bool] re = eval(#bool, "<engine.rules[0].left[0]> := <engine.levels[0].layers>;");
	//if (result(true) := re) println("Is True");
	
	//for (x <- engine.rules) println(" late: <x.late>\n commands: <x.commands>\n left: <x.left>\n right: <x.right>");
	
	//println("Rotate Test");
	//game = load(|project://AutomatedPuzzleScript/src/PuzzleScript/Test/Engine/Game1Rotate.PS|);
	//checker = check_game(game);
	//engine = compile(checker);
	//level = rotate_level(engine.levels[0]);
	//print_level(level);
	
	//println("Movement Test");
	//game = load(|project://AutomatedPuzzleScript/src/PuzzleScript/Test/Engine/Game1Movement.PS|);
	//checker = check_game(game);
	//engine = compile(checker);
	//level = engine.levels[0];
	//print_level(level);
	//level = plan_move(level, "right");
	//level = do_move(level);
	//print_level(level);
	//level = plan_move(level, "right");
	//level = do_move(level);
	//level = plan_move(level, "down");
	//level = do_move(level);
	//print_level(level);
	
	//println("Victory Test");
	//game = load(|project://AutomatedPuzzleScript/src/PuzzleScript/Test/Engine/Game1Victory.PS|);
	//checker = check_game(game);
	//engine = compile(checker);
	//println("Victory: true == <is_victorious(engine)>");
	//engine = change_level(engine, engine.index + 1);
	//println("Victory: false == <is_victorious(engine)>");
		
	//println("Rewrite Test");
	
	
}