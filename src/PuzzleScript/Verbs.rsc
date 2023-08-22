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

public map[str, map[str, list[str]]] verbs = ("limerick": ("crawl": [" [ \> Player No Obstacle  ]  -\>  [ PlayerBodyH PlayerHead1  ] "],
                                                            "climb": [" [ UP PlayerHead1 No Obstacle  ]  -\>  [ PlayerBodyV PlayerHead2  ] ", 
                                                                    " [ UP PlayerHead2 No Obstacle  ]  -\>  [ PlayerBodyV PlayerHead3  ] ",
                                                                    " [ UP PlayerHead3 No Obstacle  ]  -\>  [ PlayerBodyV PlayerHead4  ] ",
                                                                    " [ UP PlayerHead4 No Obstacle  ]  -\>  [ PlayerHead4  ] "],
                                                            "fall": [" [ Player No Obstacle  ]  -\>  [ PlayerBodyV PlayerHead1  ] "],
                                                            "eat": [" [ Player Apple  |  ]  [ PlayerBody  ]  -\>  [ Player Apple  |  ]  [  ] ",
                                                                    " [ Player Apple  ]  -\>  [ Player  ] "],
                                                            "push": ["horizontal [ \> Player Crate No Obstacle  ]  -\>  [ PlayerBodyH  | PlayerHead1  | Crate  |  ] "]),
                                                "modality": ("push": [" [ \> Player Black Crate Black  ]  -\>  [ \> Player Black \> Crate Black  ] "],
                                                            "push2": [" [ \> Player Nonblack Crate Nonblack  ]  -\>  [ \> Player Nonblack \> Crate Nonblack  ] "]),
                                                "blockfaker": ("vanish": [" [ PurpleBlock PurpleBlock PurpleBlock  ]  -\>  [  ] "],
                                                            "vanish2": [" [ GreenBlock GreenBlock GreenBlock  ]  -\>  [  ] "],
                                                            "vanish3": [" [ OrangeBlock OrangeBlock OrangeBlock  ]  -\>  [  ] "],
                                                            "vanish4": [" [ BlueBlock BlueBlock BlueBlock  ]  -\>  [  ] "],
                                                            "vanish5": [" [ PinkBlock PinkBlock PinkBlock  ]  -\>  [  ] "],
                                                            "push": [" [ \> Moveable Moveable  ]  -\>  [ \> Moveable \> Moveable  ] "]));

// public str CRAWL = "horizontal [ \> Player No Obstacle  ]  -\>  [ PlayerBodyH  | PlayerHead1  |  ] ";
// public list[str] CLIMB = ["UP [ UP PlayerHead1 No Obstacle  ]  -\>  [ PlayerBodyV  | PlayerHead2  |  ] ", 
//                           "UP [ UP PlayerHead2 No Obstacle  ]  -\>  [ PlayerBodyV  | PlayerHead3  |  ] "];
// public str FALL = "DOWN [ Player No Obstacle  ]  -\>  [ PlayerBodyV PlayerHead1  ] ";

// public map[str, map[str, [RuleData]]] verbs_per_game = ("LimeRick": ("stuck": []));  

void main() {

}


void resolve_verbs(list[str] sequence_rules, bool winning, str title) {

    map[str, list[str]] game_verbs = verbs[title];

    for (str rule <- sequence_rules) {
        for (str verb <- game_verbs<0>) {
            if (rule in game_verbs[verb]) println(verb);
        }
    }
}

void resolve_verb(str rule, bool winning, str title) {

    // println("#####");
    // println(rule + "H");

    map[str, list[str]] game_verbs = verbs[title];

    for (str verb <- game_verbs<0>) {

        // println(rule in game_verbs[verb]);
        // println(game_verbs[verb]);

        if (rule in game_verbs[verb]) println(verb);
    }
}