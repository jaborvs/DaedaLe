/*
 * @Module: DynamicAnalyser
 * @Desc:   Module to dynamically analyse PuzzleScript
 * @Auth:   Dennis Vet    -> code
 *          Borja Velasco -> comments
 */

module PuzzleScript::DynamicAnalyser

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


tuple[Engine, list[str]] bfs(Engine starting, list[str] moves, Checker c, str condition, int heuristics) {
    
    int cycles = 0;
    set[TupleObjects] visited = {};
    list[tuple[Engine, list[str], real]] queue = [<starting, [], 0.0>];
    map[list[str], int] moveSequences = ();

    while (!isEmpty(queue)) {
        if (heuristics == 1) {
            queue = sort(queue, bool(tuple[Engine, list[str], real] a, tuple[Engine, list[str], real] b){return a[2] < b[2]; });
        }
        tuple[Engine, list[str], real] current = head(queue);
        queue = tail(queue);

        if (condition != "same_state") {
            if (check_conditions(current[0], condition)) {
                return <current[0], current[1]>;
            }
        }
        visited += {convert_tuples(current[0])};

        for (m <- moves) {

            Engine beforeState = current[0];
            Engine newState = execute_move(current[0], c, m, 0);
            cycles += 1;

            // println("Trying <current[1] + [m]>");

            if (condition == "same_state" && beforeState == newState) {
                if (current[1] in moveSequences<0>) moveSequences[current[1]] += 1;
                else moveSequences += (current[1]: 1);

                if (moveSequences[current[1]] == 4) return <current[0], current[1]>;
            }    

            if (!(convert_tuples(newState) in visited)) {
                real heuristic = 0.0;
                if (heuristics == 1) heuristic = calculate_heuristic(newState);
                queue += [<newState, current[1] + [m], heuristic>];
            }  
        }
    }
    return <starting, []>;
}

TupleObjects convert_tuples(Engine engine) {

    list[tuple[str, Coords]] converted = [];

    for (Coords coord <- engine.current_level.objects<0>) {

        list[Object] sorted = sort(engine.current_level.objects[coord], bool(Object a, Object b){return a.current_name < b.current_name; });

        // for (Object object <- engine.current_level.objects[coord]) {
        for (Object object <- sorted) {
            converted += [<object.current_name, object.coords>];
        }
    }
    return converted;
}