module PuzzleScript::DynamicAnalyser

// import util::IDEServices;
// import vis::Charts;
// import vis::Presentation;
// import vis::Layout;
// import util::Web;

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

alias TupleObjects = list[tuple[str name, Coords coords]];

void main() {

    loc DemoDir = |project://automatedpuzzlescript/src/PuzzleScript/Test/Tutorials|;
    loc ReportDir = |project://automatedpuzzlescript/src/PuzzleScript/Results|;

	PSGame game;
	Checker checker;
	Engine engine;
	Level level;

	game = load(|project://automatedpuzzlescript/bin/PuzzleScript/Test/demo/heroes_of_sokoban.PS|);
	// game = load(|project://automatedpuzzlescript/bin/PuzzleScript/Test/demo/blockfaker.PS|);
	// game = load(|project://automatedpuzzlescript/bin/PuzzleScript/Test/demo/blockfaker.PS|);

	checker = check_game(game);
	engine = compile(checker);

    int before = cpuTime();

    for (int i <- [0..size(engine.converted_levels)]) {

        engine.current_level = engine.converted_levels[i];

        print_level(engine, checker);

        list[str] possible_moves = ["up", "down", "right", "left"];

        Engine starting_state = engine;
        list[str] moves = possible_moves;

        list[str] winning_moves = bfs(starting_state, moves, checker, "win");
        println(winning_moves);
        println("Took: <(cpuTime() - before) / 1000000000.00> sec");

    }

    println("Took: <(cpuTime() - before) / 1000000000.00> sec");


}

// Calling this function with "win" as condition will result in the winning_moves, any other string will result in a dead-end
// list[str] bfs(Engine starting, list[str] moves, map[Engine, list[str]] adjacencyList, Checker c, str condition) {
    
//     set[Engine] visited = {};
//     list[tuple[Engine, list[str]]] queue = [<starting, []>];
//     map[list[str], int] moveSequences = ();

//     while (!isEmpty(queue)) {
//         tuple[Engine, list[str]] current = head(queue);
//         queue = tail(queue);

//         if (condition != "same_state") {
//             if (check_conditions(current[0], condition)) {
//                 return current[1];
//             }
//         }
//         visited += {current[0]};

//         for (m <- moves) {

//             Engine beforeState = current[0];
//             Engine newState = execute_move(current[0], c, m);

//             if (condition == "same_state" && beforeState == newState) {
//                 if (current[1] in moveSequences<0>) moveSequences[current[1]] += 1;
//                 else moveSequences += (current[1]: 1);

//                 if (moveSequences[current[1]] == 4) return current[1];
//             }    

//             if (!(newState in visited)) {
//                 queue += [<newState, current[1] + [m]>];
//             }  
//         }
//     }

//     return [];
// }

list[str] bfs(Engine starting, list[str] moves, Checker c, str condition) {
    
    // set[Engine] visited = {};
    set[TupleObjects] visited = {};
    list[tuple[Engine, list[str], real]] queue = [<starting, [], 0.0>];
    map[list[str], int] moveSequences = ();

    while (!isEmpty(queue)) {
        queue = sort(queue, bool(tuple[Engine, list[str], real] a, tuple[Engine, list[str], real] b){return a[2] < b[2]; });
        tuple[Engine, list[str], real] current = head(queue);
        queue = tail(queue);

        if (condition != "same_state") {
            if (check_conditions(current[0], condition)) {
                return current[1];
            }
        }
        visited += {convert_tuples(current[0])};

        for (m <- moves) {

            Engine beforeState = current[0];
            Engine newState = execute_move(current[0], c, m);

            if (condition == "same_state" && beforeState == newState) {
                if (current[1] in moveSequences<0>) moveSequences[current[1]] += 1;
                else moveSequences += (current[1]: 1);

                if (moveSequences[current[1]] == 4) return current[1];
            }    

            if (!(convert_tuples(newState) in visited)) {
                real heuristic = calculate_heuristic(newState);
                queue += [<newState, current[1] + [m], heuristic>];
            }  
        }
    }

    return [];
}


// list[list[str]] all_bfs(Engine starting, list[str] moves, Checker c, str condition) {

//     set[Engine] visited = {};
//     list[tuple[Engine, list[str]]] queue = [<starting, []>];
//     list[list[str]] solutions = [];  

//     while (!isEmpty(queue)) {
//         tuple[Engine, list[str]] current = head(queue);
//         queue = tail(queue);

//         if (check_conditions(current[0], condition)) {
//             solutions += [current[1]];           
//             continue;
//         }
//         visited += {current[0]};

//         for (m <- moves) {

//             Engine newState = execute_move(current[0], c, m);

//             if (!(newState in visited)) {
//                 queue += [<newState, current[1] + [m]>];
//             }        
//         }
//     }

//     return solutions;
// }

TupleObjects convert_tuples(Engine engine) {

    list[tuple[str, Coords]] converted = [];

    for (Coords coord <- engine.current_level.objects<0>) {
        for (Object object <- engine.current_level.objects[coord]) {
            converted += [<object.current_name, object.coords>];
        }
    }

    return converted;


}

list[list[str]] all_bfs(Engine starting, list[str] moves, Checker c, str condition) {
    
    // set[Engine] visited = {};
    set[TupleObjects] visited = {};
    list[tuple[Engine, list[str], real]] queue = [<starting, [], 0.0>];
    map[list[str], int] moveSequences = ();
    list[list[str]] solutions = [];
    int shortest_solution = 0;

    int current = 0;
    int batch_sort_nr = 20;

    while (!isEmpty(queue)) {

        current += 1;

        // if (current mod batch_sort_nr == 0) queue = sort(queue, bool(tuple[Engine, list[str], real] a, tuple[Engine, list[str], real] b){return a[2] < b[2]; });
        queue = sort(queue, bool(tuple[Engine, list[str], real] a, tuple[Engine, list[str], real] b){return a[2] < b[2]; });
        // else queue = queue;
        tuple[Engine, list[str], real] current = head(queue);
        queue = tail(queue);

        if (condition != "same_state") {
            if (check_conditions(current[0], condition)) {
                solutions += [current[1]];
                println(current[1]);
                if (shortest_solution == 0) shortest_solution = size(current[1]);
                continue;
            }
            if (shortest_solution != 0 && size(current[1]) > shortest_solution + (shortest_solution / 2)) return solutions;
        }
        visited += {convert_tuples(current[0])};

        for (m <- moves) {

            Engine beforeState = current[0];
            Engine newState = execute_move(current[0], c, m);

            if (condition == "same_state" && beforeState == newState) {
                if (current[1] in moveSequences<0>) moveSequences[current[1]] += 1;
                else moveSequences += (current[1]: 1);

                if (moveSequences[current[1]] == 4) return current[1];
            }    

            if (!(convert_tuples(newState) in visited)) {

                if (!isEmpty(solutions) && size(current[1]) >= size(solutions[0]) / 4 && any(list[str] solution <- solutions, all(int i <- [0..size(solution) / 4], current[1][i] == solution[i]))) {
                    continue;
                }
                real heuristic = calculate_heuristic(newState);
                queue += [<newState, current[1] + [m], heuristic>];
            }  
        }
    }

    return solutions;
}
