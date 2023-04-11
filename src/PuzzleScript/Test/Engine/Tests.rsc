module PuzzleScript::Test::Engine::Tests

import PuzzleScript::Load;
import PuzzleScript::Engine;
import PuzzleScript::Compiler;
import PuzzleScript::Checker;
import PuzzleScript::AST;
import IO;
import util::Eval;
import Type;
import util::Math;
import List;

Object randomObject(list[Object] objs){
		int rand = arbInt(size(objs));
		return objs[rand];
	}

void main() {
	PSGame game;
	Checker checker;
	Engine engine;
	Level level;

	// println("Engine Test");
	// game = load(|project://AutomatedPuzzleScript/src/PuzzleScript/Test/Games/Game1.PS|);
	// checker = check_game(game);
	// engine = compile(checker);

    // for (int i <- [0..size(engine.levels)]){
    //     if (engine.levels[i] is message) {
    //         continue;
    //     }
    //     level = plan_move(engine.levels[i], "right");
	//     print_level(level);
    //     break;
    // }
	
	println("Rule Test");
	game = load(|project://AutomatedPuzzleScript/src/PuzzleScript/Test/Engine/IntermediateGame1.PS|);
    checker = check_game(game);

    println("c references = <checker.references>");

    checker.level_data = check_game_per_level(checker);
    return;
	engine = compile(checker);

    for (int i <- [0..size(engine.levels)]){
        if (engine.levels[i] is message) {
            continue;
        }
        level = engine.levels[i];
	    print_level(level);
        break;
    }
	// level = engine.levels[0];
	
    // println("0 right = <engine.rules[0].right>");
    // println("1 right = <engine.rules[1].right>");

	// println(engine.rules[1].left[0]);
	// println();
	// println(engine.rules[1].right[0]);

    println("Level before move: \n");
    print_level(level);

	<engine, level> = rewrite(engine, level, false);
	level = plan_move(level, "right");
    println("Na plan_move");
    print_level(level);
	
    <engine, level> = rewrite(engine, level, false);


    // Do_move suddenly has moving_objects that weren't moving_objects before, rewrite must have changed
	level = do_move(level);
    println("Na do_move");
	print_level(level);
    
    <engine, level> = rewrite(engine, level, true);

    println("Executed move, level looks the following now: \n");
    print_level(level);	

    return;
	
	
	println("Rotate Test");
	game = load(|project://AutomatedPuzzleScript/src/PuzzleScript/Test/Engine/Game1Rotate.PS|);
	checker = check_game(game);
	engine = compile(checker);
	level = rotate_level(engine.levels[0]);
	print_level(level);
	
	println("Movement Test");
	game = load(|project://AutomatedPuzzleScript/src/PuzzleScript/Test/Engine/Game1Movement.PS|);
	checker = check_game(game);
	engine = compile(checker);
	level = engine.levels[0];
	print_level(level);
	level = plan_move(level, "right");
	level = do_move(level);
	print_level(level);
	level = plan_move(level, "right");
	level = do_move(level);
	level = plan_move(level, "down");
	level = do_move(level);
	print_level(level);
	
	println("Victory Test");
	game = load(|project://AutomatedPuzzleScript/src/PuzzleScript/Test/Engine/Game1Victory.PS|);
	checker = check_game(game);
	engine = compile(checker);
	println("Victory: true == <is_victorious(engine)>");
	engine = change_level(engine, engine.index + 1);
	println("Victory: false == <is_victorious(engine)>");
		
	println("Rewrite Test");
	list[str] GAME1_LEVEL1_MOVES = ["down", "left", "up", "right", "right", "right", "down", "left", "up", "left", "left", "down", "down", "right", "up", "left", "up", "right", "up", "up", "left", "down", "down", "right", "down", "right", "right", "up", "left", "down", "left", "up", "up", "down", "down", "down", "left",  "up"];
	list[str] GAME1_LEVEL2_MOVES = ["right", "down", "down", "left", "right", "up", "up", "left", "down", "up", "up", "left", "left", "down", "down", "right"];
	println("Simple Game Test");
	game = load(|project://AutomatedPuzzleScript/src/PuzzleScript/Test/Games/Game1.PS|);
	checker = check_game(game);
	engine = compile(checker);
	game_loop(checker, GAME1_LEVEL1_MOVES + GAME1_LEVEL2_MOVES);
	
	list[str] GAME2_LEVEL1_MOVES = ["left", "up", "up", "right", "down", "left", "down", "right", "right", "down", "down", "right", "right", "right", "up"];
	list[str] GAME2_LEVEL2_MOVES = ["right"];
	println("Intermediate Game Test");
	game = load(|project://AutomatedPuzzleScript/src/PuzzleScript/Test/Engine/IntermediateGame1.PS|);
	checker = check_game(game);
	game_loop(checker, GAME2_LEVEL1_MOVES + GAME2_LEVEL2_MOVES);
	
	list[str] GAME3_LEVEL1_MOVES = ["right"];
	println("Advanced Game Test");
	game = load(|project://AutomatedPuzzleScript/src/PuzzleScript/Test/Engine/AdvancedGame1.PS|);
	checker = check_game(game);
	engine = compile(checker);
	level = engine.levels[0];
	
	print_level(level);
	<engine, level> = do_turn(engine, level, "right");
	print_level(level);
	
	println(engine.rules[0].left[0]);
	println(format_coords(engine.rules[0].indexes[0]));
	println(engine.rules[0].left[1]);
	println(format_coords(engine.rules[0].indexes[1]));
	println(engine.rules[0].indexes);
	println();
	println(engine.rules[0].right[0]);
	println(engine.rules[0].right[1]);
	
	game_loop(checker, GAME3_LEVEL1_MOVES);
	
	println("Undo Test");
	game = load(|project://AutomatedPuzzleScript/src/PuzzleScript/Test/Games/Game1.PS|);
	checker = check_game(game);
	engine = compile(checker);
	level = engine.levels[0];
	level = plan_move(level, "right");
	level = do_move(level);
	level = plan_move(level, "right");
	level = do_move(level);
	level = plan_move(level, "down");
	level = do_move(level);
	level = plan_move(level, "left");
	<engine, level> = rewrite(engine, level, false);
	level = do_move(level);
	print_level(level);
	level = undo(level);
	print_level(level);
	
	println("Restart Test");
	game = load(|project://AutomatedPuzzleScript/src/PuzzleScript/Test/Games/Game1.PS|);
	checker = check_game(game);
	engine = compile(checker);
	level = engine.levels[0];
	level = plan_move(level, "right");
	level = do_move(level);
	level = plan_move(level, "right");
	level = do_move(level);
	level = plan_move(level, "down");
	level = do_move(level);
	level = plan_move(level, "left");
	<engine, level> = rewrite(engine, level, false);
	level = do_move(level);
	print_level(level);
	level = restart(level);
	print_level(level);
	
	println("Checkpoint Test");
	game = load(|project://AutomatedPuzzleScript/src/PuzzleScript/Test/Games/Game1.PS|);
	checker = check_game(game);
	engine = compile(checker);
	level = engine.levels[0];
	level = plan_move(level, "right");
	level = do_move(level);
	level = checkpoint(level);
	level = plan_move(level, "right");
	level = do_move(level);
	level = plan_move(level, "down");
	level = do_move(level);
	level = plan_move(level, "left");
	<engine, level> = rewrite(engine, level, false);
	level = do_move(level);
	print_level(level);
	level = restart(level);
	print_level(level);
	
	println("Mixed Command Test");
	game = load(|project://AutomatedPuzzleScript/src/PuzzleScript/Test/Games/Game1.PS|);
	checker = check_game(game);
	engine = compile(checker);
	level = engine.levels[0];
	level = plan_move(level, "right");
	level = do_move(level);
	level = plan_move(level, "right");
	level = do_move(level);
	level = plan_move(level, "down");
	level = do_move(level);
	level = plan_move(level, "left");
	<engine, level> = rewrite(engine, level, false);
	level = do_move(level);
	print_level(level);
	level = restart(level);
	print_level(level);
}