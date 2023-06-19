module PuzzleScript::DynamicAnalyser

import util::IDEServices;
import vis::Charts;
import vis::Presentation;
import vis::Layout;
import util::Web;

import PuzzleScript::Report;
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

import util::Benchmark;

void main() {

    loc DemoDir = |project://AutomatedPuzzleScript/src/PuzzleScript/Test/Tutorials|;
    loc ReportDir = |project://AutomatedPuzzleScript/src/PuzzleScript/Results|;

	PSGame game;
	Checker checker;
	Engine engine;
	Level level;

	// game = load(|project://AutomatedPuzzleScript/bin/PuzzleScript/Test/demo/blockfaker.PS|);
	game = load(|project://AutomatedPuzzleScript/bin/PuzzleScript/Test/demo/sokoban_basic.PS|);
	// game = load(|project://AutomatedPuzzleScript/bin/PuzzleScript/Test/demo/sokoban_match3.PS|);
	checker = check_game(game);
    checker.level_data = check_game_per_level(checker);

	engine = compile(checker);

    int before = cpuTime();

    for (int i <- [0..size(engine.converted_levels)]) {

        engine.current_level = engine.converted_levels[i];

        list[str] possible_moves = ["up", "down", "right", "left"];

        Engine starting_state = engine;
        list[str] moves = possible_moves;
        map[Engine, list[str]] adjacencyList = (starting_state: moves);

        list[str] winning_moves = bfs(starting_state, moves, adjacencyList, checker);

        for (int i <- [0..size(winning_moves)]) {
            
            str move = winning_moves[i];
            engine = execute_move(engine, checker, move);
            // print_level(engine, checker);

        }
        println(check_win_conditions(engine));
    }


    println("Took: <(cpuTime() - before) / 1000000000.00> sec");


}

list[str] bfs(Engine starting, list[str] moves, map[Engine, list[str]] adjacencyList, Checker c) {
    
    set[Engine] visited = {};
    list[tuple[Engine, list[str]]] queue = [<starting, []>];

    while (!isEmpty(queue)) {
        tuple[Engine, list[str]] current = head(queue);
        queue = tail(queue);

        if (check_win_conditions(current[0])) {
            return current[1];  // return the path to the winning state
        }

        visited += {current[0]};

        for (m <- moves) {
            Engine newState = execute_move(current[0], c, m);
            // print_level(newState.engine, c);

            Coords difference = get_dir_difference(m);

            int x_difference = newState.current_level.player[0][0] - difference[0];
            int y_difference = newState.current_level.player[0][1] - difference[1];

            bool in_bounds = (x_difference > 0 && x_difference < newState.current_level.additional_info.size[0] &&
                 x_difference > 0 && x_difference < newState.current_level.additional_info.size[1]);

            if (!(newState in visited) && in_bounds) {
                queue += [<newState, current[1] + [m]>];
            }
        }
    }

    return [];  // no solution found
}