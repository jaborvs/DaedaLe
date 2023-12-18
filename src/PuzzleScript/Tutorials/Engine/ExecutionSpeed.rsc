module PuzzleScript::Tutorials::Engine::ExecutionSpeed

// import PuzzleScript::IDE::IDE;
import util::ShellExec;
import lang::json::IO;

import PuzzleScript::Report;
import PuzzleScript::DynamicAnalyser;
import PuzzleScript::Load;
import PuzzleScript::Engine;
import PuzzleScript::Compiler;
import PuzzleScript::Checker;
import PuzzleScript::AST;
import PuzzleScript::Verbs;
import IO;
import util::Eval;
import Type;
import util::Math;
import List;
import String;

import util::Benchmark;

// Object randomObject(list[Object] objs){
// 		int rand = arbInt(size(objs));
// 		return objs[rand];
// 	}

void main() {

    loc DemoDir = |project://automatedpuzzlescript/Tutomate/src/PuzzleScript/Tutorials/TutorialGames|;
    loc ReportDir = |project://automatedpuzzlescript/Tutomate/src/PuzzleScript/Results|;

	PSGame game;
	Checker checker;
	Engine engine;
	Level level;

	game = load(|project://automatedpuzzlescript/Tutomate/bin/PuzzleScript/Tutorials/demo/blockfaker.PS|);

	checker = check_game(game);
	engine = compile(checker);

    engine.current_level = engine.converted_levels[0];
    Level save_level = engine.current_level;

    list[str] possible_moves = ["right", "right", "right", "right"];

    LevelChecker lc = engine.level_data[engine.current_level.original];
    println(size(lc.applied_rules) + size(lc.applied_late_rules));
    println(size(engine.rules) + size(engine.late_rules));

    for (int i <- [0..2]) {
        i == 0 ? println("May rules") : println("\nAll rules");

        engine.current_level = save_level;

        for (str move <- possible_moves) {

            int before = cpuTime();
            engine = execute_move(engine, checker, move, i);
            println((cpuTime() - before) / 1000000000.00);
            print_level(engine, checker);

        }

    }


    return;

    list[list[str]] all_winning = all_bfs(engine, ["up", "left", "down", "right"], checker, "win");
    println(all_winning);
    engine.current_level = save_level;
    print_level(engine, checker);
    list[list[str]] all_losing = all_bfs(engine, ["up", "left", "down", "right"], checker, "same_state");
    println(all_losing);

    return;

    // println("==== Multiple layer object test ====");

    // list[str] sokoban_moves = ["down", "left", "up", "right", "right", "right", "down", "left", "up", "left", "left", "down", "down", "right", "up", "left", "up", "right", "up", "up", "left", "down", "right", "down", "down", "right", "right", "up", "left", "down", "left", "up", "up"];

    // for (int i <- [0..size(sokoban_moves)]) {
        
    //     str move = sokoban_moves[i];
    //     engine = execute_move(engine, checker, move);

    // }

    engine.current_level = save_level;

    Coords begin_player_pos = engine.current_level.player[0];
    Coords old_player_pos = <0,0>;
    Coords new_player_pos = <1,1>;

    println("==== Collision test ====");
    list[str] collision_moves = ["left", "left", "left", "down", "left", "up", "up", "up"];
    for (int i <- [0..size(collision_moves)]) {
        
        str move = collision_moves[i];

        engine = execute_move(engine, checker, move);
        print_level(engine, checker);

        if (i == size(collision_moves) - 2) old_player_pos = engine.current_level.player[0];
        if (i == size(collision_moves) - 1) new_player_pos = engine.current_level.player[0];

    }
    print_level(engine, checker);
    println(check_conditions(engine, "poep"));

    println("Player was unable to push block: <old_player_pos == new_player_pos && new_player_pos != begin_player_pos>");
    println("Win conditions satisfied after correct moves: <check_conditions(engine, "win")>");

    return;
    engine.current_level = save_level;
    engine.level_data[engine.current_level.original].actual_applied_rules = [];

    old_player_pos = engine.current_level.player[0];
    engine = execute_move(engine, checker, "right");
    new_player_pos = engine.current_level.player[0];

    println("Player was unable to move into a wall: <old_player_pos == new_player_pos>");

    engine.current_level = save_level;

    println("\n=== Win test ====");
    // list[str] winning_moves = ["up", "up", "up", "up", "left", "left", "left", "left", "down", "down", "right", 
    //     "up", "left", "up", "right", "right", "right", "right", "up", "right", "down", "down", "right", "right", "right"];

    list[str] winning_moves = ["up","up","up","up","left","left","left","left","down","down","right","up","left","up","right","right","right","up","right","down","down","right","right","right"];

    for (int i <- [0..size(winning_moves)]) {
        
        str move = winning_moves[i];
        engine = execute_move(engine, checker, move);
        print_level(engine, checker);

    }

    println("Win conditions satisfied after correct moves: <check_conditions(engine, "win")>");
    println("Applied rules to get there:");
    for (RuleData rd <- engine.level_data[engine.current_level.original].applied_rules) {

        println(convert_rule(rd.left, rd.right));

    }
    
    engine.current_level = save_level;
    engine.level_data[engine.current_level.original].actual_applied_rules = [];


    list[str] losing_moves = ["up", "up"];

    for (int i <- [0..size(losing_moves)]) {
        
        str move = losing_moves[i];
        engine = execute_move(engine, checker, move);

    }

    println("Win conditions not satisfied after wrong moves: <!check_conditions(engine, "win")>");

    println("\n=== Mutliple rule test ====");

    engine.current_level = save_level;
    engine.level_data[engine.current_level.original].actual_applied_rules = [];

    old_player_pos = engine.current_level.player[0];
    engine = execute_move(engine, checker, "up");
    new_player_pos = engine.current_level.player[0];

    println("Player is able to move multiple consecutive blocks: <old_player_pos != new_player_pos>");

}