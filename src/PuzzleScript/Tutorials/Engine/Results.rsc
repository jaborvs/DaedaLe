module PuzzleScript::Tutorials::Engine::Results

import util::ShellExec;
import lang::json::IO;

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


void main() {

    loc DemoDir = |project://DaedaLe/src/PuzzleScript/Test/Tutorials|;
    loc ReportDir = |project://DaedaLe/src/PuzzleScript/Results|;

    PSGame game;
    Checker checker;
    Engine engine;
    Level level;

    game = load(|project://DaedaLe/bin/PuzzleScript/Tutorials/demo/limerick.PS|);

    checker = check_game(game);
    engine = compile(checker);

    engine.current_level = engine.converted_levels[0];
    Level save_level = engine.current_level;

    list[str] possible_moves = ["up", "right", "left", "down"];

    str title = "";
    for(PreludeData p <- engine.game.prelude){
        if(p.keywrd == "title") {
            title = toLowerCase(replaceAll(p.string, ",", " "));
            title = toLowerCase(replaceAll(title, " ", ""));
            break;
        }
    }

    println(title);
    
    for (int i <- [0..3]) {

        engine.current_level = engine.converted_levels[i];
        engine.applied_data[engine.current_level.original].actual_applied_rules = ();

        list[str] moves = ["right","up","up","up", "up", "right"];
        for (str move <- moves) {
            println("Executing move <move>");
            engine = execute_move(engine, checker, move, 0);
            print_level(engine, checker);
        }

        // println(engine.applied_data[engine.current_level.original].applied_moves);
        // println(engine.applied_data[engine.current_level.original].actual_applied_rules);
        return;

        // Get succesful path and corresponding skills
        tuple[Engine engine, list[str] winning_moves] result = bfs(engine, possible_moves, checker, "win", 1);
        println("Winning moves: <size(result.winning_moves)>");
        
        
        // list[str] winning_moves_rules = [];

        // for (list[RuleData] rd <- result.engine.level_checkers[engine.current_level.original].actual_applied_rules<1>) {
        //     RuleData rd = rd[0];
        //     if (any(RuleData rd2 <- engine.game.rules, rd2.src == rd.src)) {
        //         winning_moves_rules += engine.indexed_rules[rd2][1];
        //     }
        // }


        for (int i <- [0..size(result.winning_moves)]) {
            if (i in result.engine.applied_data[engine.current_level.original].actual_applied_rules<0>) {
                RuleData rd = result.engine.applied_data[engine.current_level.original].actual_applied_rules[i][0];
                resolve_verb(convert_rule(rd.left, rd.right), true, title);
            } else {
                println("crawl");
            }
        }

        println("##### Dead ends ##### \n");
        // Now get all the dead_ends and the skills that lead to this dead end
        list[tuple[Engine engine, list[str] dead_ends]] result_dead_ends = get_dead_ends(engine, checker, result.winning_moves);

        for (int i <- [0..size(result_dead_ends)]) {

            list[str] rules = result_dead_ends[i].dead_ends;
            Engine engine = result_dead_ends[i].engine;
            
            for (int i <- [0..size(rules)]) {
                if (i in engine.applied_data[engine.current_level.original].actual_applied_rules<0>) {
                    RuleData rd = engine.applied_data[engine.current_level.original].actual_applied_rules[i][0];
                    resolve_verb(convert_rule(rd.left, rd.right), true, title);
                } else {
                    println("walk");
                }
            }
            resolve_verbs(rules, false, title);
        }

        // println(dead_ends);

        println(size(result.winning_moves));
    }



    // println(dead_ends);
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
    engine.applied_data[engine.current_level.original].actual_applied_rules = [];

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
    for (RuleData rd <- engine.level_checkers[engine.current_level.original].applied_rules) {

        println(convert_rule(rd.left, rd.right));

    }
    
    engine.current_level = save_level;
    engine.applied_data[engine.current_level.original].actual_applied_rules = [];


    list[str] losing_moves = ["up", "up"];

    for (int i <- [0..size(losing_moves)]) {
        
        str move = losing_moves[i];
        engine = execute_move(engine, checker, move);

    }

    println("Win conditions not satisfied after wrong moves: <!check_conditions(engine, "win")>");

    println("\n=== Mutliple rule test ====");

    engine.current_level = save_level;
    engine.applied_data[engine.current_level.original].actual_applied_rules = [];

    old_player_pos = engine.current_level.player[0];
    engine = execute_move(engine, checker, "up");
    new_player_pos = engine.current_level.player[0];

    println("Player is able to move multiple consecutive blocks: <old_player_pos != new_player_pos>");

}