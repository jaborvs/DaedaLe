module PuzzleScript::Verbs

import PuzzleScript::Report;
import PuzzleScript::DynamicAnalyser;
import PuzzleScript::Load;
import PuzzleScript::Engine;
import PuzzleScript::Compiler;
import PuzzleScript::Checker;
import PuzzleScript::AST;
import PuzzleScript::Tutorials::AST;
import PuzzleScript::Tutorials::Syntax;
import IO;
import util::Eval;
import Type;
import util::Math;
import List;
import Set;

import util::Benchmark;

tuple[list[str],list[str],list[str]] resolve_verbs(Engine engine, map[int,list[RuleData]] rules, list[Verb] verb_definitions, list[Elem] elems, int length) {

    realised_verbs = [];
    not_realised_verbs = [];
    list[str] all_verbs = [];

    map[str, list[RuleData]] verb_rules = ();

    // Resolve rule data for verbs
    for (Verb verb <- verb_definitions) {

        if (size(verb.numbers) == 0) verb_rules += (verb.name.name: []);

        for (int nr <- verb.numbers) {
            for (RuleData rd <- engine.indexed_rules<0>) {
                if (engine.indexed_rules[rd][0] == nr) {
                    if (verb_rules[verb.name.name]?) verb_rules[verb.name.name] += [rd];
                    else verb_rules += (verb.name.name: [rd]);
                }
            }
        }
    }

    for (int i <- [0..length]) {

        if (!rules[i]?) {
            if (any(Verb verb <- verb_definitions, size(verb.numbers) == 0)) {
                println("Verb <verb.name.name> has 0 rule nrs");
                all_verbs += verb.name.name;
            }
            continue;
        }
        
        list[RuleData] lrd = rules[i];

        for (Verb verb <- verb_definitions) {
            println(verb.name.name);
            if (any(RuleData rd <- verb_rules[verb.name.name], rd.src in [x.src | x <- lrd])) {
                println("1.411");
                all_verbs += verb.name.name;
            }
            println(all_verbs);
        }

    }

    for (Elem elem <- elems) {

        if (elem is description) continue;

        for (ID id_name <- elem.names) {

            str verb = id_name.name;
            for (list[RuleData] lrd <- rules<1>) {
                if (any(RuleData rd <- verb_rules[verb], rd.src in [x.src | x <- lrd]) && !(verb in realised_verbs)) realised_verbs += verb;
            }
            if (!(verb in not_realised_verbs) && !(verb in realised_verbs)) not_realised_verbs += verb;
        }
    }

    return <realised_verbs, not_realised_verbs, all_verbs>;

}
