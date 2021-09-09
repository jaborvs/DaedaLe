module PuzzleScript::Test::Engine::Tests

import PuzzleScript::Load;
import PuzzleScript::Engine;
import PuzzleScript::Compiler;
import PuzzleScript::Checker;
import PuzzleScript::AST;
import IO;
import util::Eval;
import Type;

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
	
	println("Rule Test");
	game = load(|project://AutomatedPuzzleScript/src/PuzzleScript/Test/Engine/IntermediateGame1.PS|);
	checker = check_game(game);
	engine = compile(checker);
	level = engine.levels[0];
	
	println(engine.rules[1].left[0]);
	println();
	println(engine.rules[1].right[0]);
	
	
	//level = plan_move(level, "up");
	//level = do_move(level);
	//print_level(level);
	//println();
	//
	//level = do_move(level);
	//<engine, level> = rewrite(engine, level, false);
	//level = plan_move(level, "up");
	//level = do_move(level);
	//print_level(level);
	
	
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
	
	//println("Simple Game Test");
	//game = load(|project://AutomatedPuzzleScript/src/PuzzleScript/Test/Games/Game1.PS|);
	//checker = check_game(game);
	//game_loop(checker);
	
	//println("Undo Test");
	//game = load(|project://AutomatedPuzzleScript/src/PuzzleScript/Test/Games/Game1.PS|);
	//checker = check_game(game);
	//engine = compile(checker);
	//level = engine.levels[0];
	//level = plan_move(level, "right");
	//level = do_move(level);
	//level = plan_move(level, "right");
	//level = do_move(level);
	//level = plan_move(level, "down");
	//level = do_move(level);
	//level = plan_move(level, "left");
	//<engine, level> = rewrite(engine, level, false);
	//level = do_move(level);
	//print_level(level);
	//level = undo(level);
	//print_level(level);
	
	//println("Restart Test");
	//game = load(|project://AutomatedPuzzleScript/src/PuzzleScript/Test/Games/Game1.PS|);
	//checker = check_game(game);
	//engine = compile(checker);
	//level = engine.levels[0];
	//level = plan_move(level, "right");
	//level = do_move(level);
	//level = plan_move(level, "right");
	//level = do_move(level);
	//level = plan_move(level, "down");
	//level = do_move(level);
	//level = plan_move(level, "left");
	//<engine, level> = rewrite(engine, level, false);
	//level = do_move(level);
	//print_level(level);
	//level = restart(level);
	//print_level(level);
	
	//println("Checkpoint Test");
	//game = load(|project://AutomatedPuzzleScript/src/PuzzleScript/Test/Games/Game1.PS|);
	//checker = check_game(game);
	//engine = compile(checker);
	//level = engine.levels[0];
	//level = plan_move(level, "right");
	//level = do_move(level);
	//level = checkpoint(level);
	//level = plan_move(level, "right");
	//level = do_move(level);
	//level = plan_move(level, "down");
	//level = do_move(level);
	//level = plan_move(level, "left");
	//<engine, level> = rewrite(engine, level, false);
	//level = do_move(level);
	//print_level(level);
	//level = restart(level);
	//print_level(level);
	
	//println("Mixed Command Test");
	//game = load(|project://AutomatedPuzzleScript/src/PuzzleScript/Test/Games/Game1.PS|);
	//checker = check_game(game);
	//engine = compile(checker);
	//level = engine.levels[0];
	//level = plan_move(level, "right");
	//level = do_move(level);
	//level = plan_move(level, "right");
	//level = do_move(level);
	//level = plan_move(level, "down");
	//level = do_move(level);
	//level = plan_move(level, "left");
	//<engine, level> = rewrite(engine, level, false);
	//level = do_move(level);
	//print_level(level);
	//level = restart(level);
	//print_level(level);
}