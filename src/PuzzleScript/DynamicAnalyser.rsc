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

data State = state(Engine engine);
data Move = move(str direction);

void main() {

    loc DemoDir = |project://AutomatedPuzzleScript/src/PuzzleScript/Test/Tutorials|;
    loc ReportDir = |project://AutomatedPuzzleScript/src/PuzzleScript/Results|;

	PSGame game;
	Checker checker;
	Engine engine;
	Level level;

	// game = load(|project://AutomatedPuzzleScript/bin/PuzzleScript/Test/demo/blockfaker.PS|);
	game = load(|project://AutomatedPuzzleScript/bin/PuzzleScript/Test/demo/sokoban_basic.PS|);
	checker = check_game(game);
    checker.level_data = check_game_per_level(checker);

	engine = compile(checker);

    list[str] possible_moves = ["up", "down", "right", "left"];

    State starting_state = state(engine);
    list[str] moves = possible_moves;
    map[State, list[str]] adjacencyList = (starting_state: moves);

    int before = cpuTime();
    list[str] winning_moves = bfs(starting_state, moves, adjacencyList, checker);

    for (int i <- [0..size(winning_moves)]) {
        
        str move = winning_moves[i];
        engine = execute_move(engine, checker, move);
        print_level(engine, checker);

    }

    println("Took: <(cpuTime() - before) / 1000000000.00> sec");


}

list[str] bfs(State starting, list[str] moves, map[State, list[str]] adjacencyList, Checker c) {
    
    set[State] visited = {};
    list[tuple[State, list[str]]] queue = [<starting, []>];

    while (!isEmpty(queue)) {
        tuple[State, list[str]] current = head(queue);
        queue = tail(queue);

        if (check_win_conditions(current[0].engine)) {
            return current[1];  // return the path to the winning state
        }

        visited += {current[0]};

        for (m <- moves) {
            State newState = state(execute_move(current[0].engine, c, m));
            // print_level(newState.engine, c);

            if (!(newState in visited)) {
                queue += [<newState, current[1] + [m]>];
            }
        }
    }

    return [];  // no solution found
}