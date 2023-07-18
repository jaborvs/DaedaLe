module PuzzleScript::Verbs

import PuzzleScript::Report;
import PuzzleScript::DynamicAnalyser;
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

public str CRAWL = "horizontal [ \> Player No Obstacle  ]  -\>  [ PlayerBodyH  | PlayerHead1  |  ] ";
public list[str] CLIMB = ["UP [ UP PlayerHead1 No Obstacle  ]  -\>  [ PlayerBodyV  | PlayerHead2  |  ] ", 
                          "UP [ UP PlayerHead2 No Obstacle  ]  -\>  [ PlayerBodyV  | PlayerHead3  |  ] "];
public str FALL = "DOWN [ Player No Obstacle  ]  -\>  [ PlayerBodyV PlayerHead1  ] ";

// public map[str, map[str, [RuleData]]] verbs_per_game = ("LimeRick": ("stuck": []));  

void main() {

}


void resolve_verbs(list[str] sequence_rules, bool winning) {

    list[str] verbs = [];
    bool climbing = false;

    for (str rule <- sequence_rules) {

        if (climbing && !(rule in CLIMB)) {
            verbs += ["climb, "];
            climbing = false;
        }

        if (rule == CRAWL) verbs += ["crawl, "];
        else if (rule == CLIMB[0]) climbing = true;
        else if (rule == FALL) verbs += ["fall, "];
        // else if (rule == EAT) verbs += ["eat"];
    }

    if (!winning) verbs += ["stuck"];

    for (str verb <- verbs) {
        println(verb);
    }

}