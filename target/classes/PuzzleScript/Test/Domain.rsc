module PuzzleScript::Test::Domain

import ParseTree;

start syntax Tutorial
  = tutorial: "tutorial" Identifier name "{" {Lesson";"}* "}";

syntax Lesson
  = lesson: "lesson" Identifier name "{" Elem* elems "}";

syntax Elem 
    = dead_end: "fails if" Identifier name "in corner"
    | win_condition: "learn to" {Identifier name","}*
    | verb_definition: "verb" Identifier name "=" Mechanism mechanism;

// syntax Verb  //climb, fall
//   = verb: Identifier name "[" Mechanism* mechanisms "]";

syntax Mechanism
  = mechanism: "[" {Number "," }* rule_nrs "]";
//   = mechanism: "[" INT* rule_nrs "]"; 

lexical Identifier
  = id: ([a-zA-Z_$] [a-zA-Z0-9_$]* !>> [a-zA-Z0-9_$]) val;

// layout LAYOUTLIST
//   = LAYOUT* !>> [\t-\n \r \ ] !>> "//" !>> "/*";

layout LAYOUTLIST
  = LAYOUT* !>> "//" !>> "/*";


lexical LAYOUT
  = Comment
  | [\t-\n \r \ ];
  
lexical Comment
  // "/*" (![*] | [*] !>> [/])* "*/" 
  = "//" ![\n]* [\n];

lexical Number
 = [0-9]+ val;

// syntax Trace
//   = "[" {Action ","}* "]";

// syntax Action
//   = Identifier key "@" Time time
//   | Identifier key;



// data Action
//   = action(Identifier key)
//   | action(Identifier key, Time tine)
//   | action(Identifier key, Time time, Identifier mechanism);

data Tutorial = tutorial(Identifier name)
              | tutorial(Identifier name, list[Lesson] lessons);

data Identifier
  = id(str val);

data Lesson = lesson(Identifier name)
            | lesson(Identifier name, list[Elem] elems);

data Elem 
    = dead_end(Identifier name)
    | win_condition(Identifier name)
    | verb_definition(Identifier name, Mechanism mechansism);

// data End =
//     end(Identifier name);

// data Verb
//     = verb(Identifier name, list[Mechanism] mechansisms);

data Mechanism 
    = mechanism(list[Number] rule_nrs);



public start[Tutorial] cddl_parse(str input, loc file) = parse(#start[Tutorial], input, file);
  
public start[Tutorial] cddl_parse(loc file) = parse(#start[Tutorial], file);

public Tutorial cddl_build(loc file) = implode(#Tutorial, cddl_parse(file));
