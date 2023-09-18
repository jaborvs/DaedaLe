module PuzzleScript::Verbs

import PuzzleScript::Report;
import PuzzleScript::DynamicAnalyser;
import PuzzleScript::Load;
import PuzzleScript::Engine;
import PuzzleScript::Compiler;
import PuzzleScript::Checker;
import PuzzleScript::AST;
import PuzzleScript::Test::Domain;
import IO;
import util::Eval;
import Type;
import util::Math;
import List;

import util::Benchmark;

list[str] resolve_verbs(Engine engine, list[RuleData] rules, list[Verb] verb_definitions, list[Elem] elems, int win) {

    println(verb_definitions);
    println(elems);
    println(win);
    
    // for (int i <- [0..size(rules)]) {
    //     if (i in engine.applied_data[engine.current_level.original].actual_applied_rules<0>) {
    //         RuleData rd = engine.applied_data[engine.current_level.original].actual_applied_rules[i][0];
    //         resolve_verb(convert_rule(rd.left, rd.right), true, title);
    //     } else {
    //         verbs += ["walk"];
    //     }
    // }

    return verbs;

}
