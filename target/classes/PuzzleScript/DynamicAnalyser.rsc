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
import Set;

import util::Benchmark;

void main() {

    loc DemoDir = |project://AutomatedPuzzleScript/src/PuzzleScript/Test/Tutorials|;
    loc ReportDir = |project://AutomatedPuzzleScript/src/PuzzleScript/Results|;

	PSGame game;
	Checker checker;
	Engine engine;
	Level level;

	// game = load(|project://AutomatedPuzzleScript/bin/PuzzleScript/Test/demo/blockfaker.PS|);
	// game = load(|project://AutomatedPuzzleScript/bin/PuzzleScript/Test/demo/sokoban_basic.PS|);
	// game = load(|project://AutomatedPuzzleScript/bin/PuzzleScript/Test/demo/sokoban_match3.PS|);
	// game = load(|project://AutomatedPuzzleScript/bin/PuzzleScript/Test/Tutorials/push.PS|);
	// game = load(|project://AutomatedPuzzleScript/bin/PuzzleScript/Test/Tutorials/modality.PS|);
	game = load(|project://AutomatedPuzzleScript/bin/PuzzleScript/Test/Tutorials/heroes_of_sokoban.PS|);

	checker = check_game(game);
	engine = compile(checker);

    int before = cpuTime();

    for (int i <- [0..size(engine.converted_levels)]) {

        engine.current_level = engine.converted_levels[i];

        list[str] possible_moves = ["up", "down", "right", "left"];

        Engine starting_state = engine;
        list[str] moves = possible_moves;
        map[Engine, list[str]] adjacencyList = (starting_state: moves);

        // list[list[str]] dead_ends = bfs(starting_state, moves, adjacencyList, checker, "poep");
        // println(size(dead_ends));

        list[str] winning_moves = bfs(starting_state, moves, adjacencyList, checker, "win");
        println(winning_moves);

        // for (int i <- [0..size(winning_moves)]) {
            
        //     str move = winning_moves[i];
        //     engine = execute_move(engine, checker, move);
        //     // print_level(engine, checker);

        // }
    }


    println("Took: <(cpuTime() - before) / 1000000000.00> sec");


}

// Calling this function with "win" as condition will result in the winning_moves, any other string will result in a dead-end
list[str] bfs(Engine starting, list[str] moves, map[Engine, list[str]] adjacencyList, Checker c, str condition) {
    
    set[Engine] visited = {};
    list[tuple[Engine, list[str]]] queue = [<starting, []>];

    while (!isEmpty(queue)) {
        tuple[Engine, list[str]] current = head(queue);
        queue = tail(queue);

        if (check_conditions(current[0], condition)) {
            return current[1];
        }
        visited += {current[0]};

        for (m <- moves) {

            Engine newState = execute_move(current[0], c, m);
            // print_level(newState.engine, c);

            Coords difference = get_dir_difference(m);

            int x_difference = newState.current_level.player[0][0] - difference[0];
            int y_difference = newState.current_level.player[0][1] - difference[1];

            if (!(newState in visited)) {
                queue += [<newState, current[1] + [m]>];
            }     
        }
    }

    return [];  // no solution found
}

list[list[str]] all_bfs(Engine starting, list[str] moves, map[Engine, list[str]] adjacencyList, Checker c, str condition) {

    set[Engine] visited = {};
    list[tuple[Engine, list[str]]] queue = [<starting, []>];
    list[list[str]] solutions = [];  // Store all found solutions

    while (!isEmpty(queue)) {
        tuple[Engine, list[str]] current = head(queue);
        queue = tail(queue);

        if (check_conditions(current[0], condition)) {
            solutions += [current[1]];  // Add found solution to solutions list            
            continue;  // Don't return, continue to find more solutions
        }
        visited += {current[0]};

        for (m <- moves) {

            Engine newState = execute_move(current[0], c, m);
            // print_level(newState.engine, c);

            Coords difference = get_dir_difference(m);

            int x_difference = newState.current_level.player[0][0] - difference[0];
            int y_difference = newState.current_level.player[0][1] - difference[1];

            if (!(newState in visited)) {
                queue += [<newState, current[1] + [m]>];
            }        
        }
    }

    return solutions;  // Return all found solutions
}
