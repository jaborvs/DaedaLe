module PuzzleScript::Test::Domain

import ParseTree;

start syntax Tutorial
  = tutorial: "tutorial" ID name "{" {Lesson";"}* "}";

syntax Lesson
  = lesson: "lesson" ID name "{" Elem* elems "}";

syntax Elem 
    = dead_end: "fails if" ID name "in corner"
    | win_condition: "learn to" {ID name","}*
    | verb_definition: "verb" ID name "=" Mechanism mechanism;

// syntax Verb  //climb, fall
//   = verb: ID name "[" Mechanism* mechanisms "]";

syntax Mechanism
  = mechanism: "[" {Number "," }* rule_nrs "]";
//   = mechanism: "[" INT* rule_nrs "]"; 

keyword Keyword
  = "deck" | "dimension" | "cardType" | "cards" | "card" | "of"
  | "top" | "middle" | "bottom" 
  | "left" | "center"  | "right"
  | "small" | "large" | "huge"
  | "image" | "text" | "color";

lexical ID
  = id: ([a-zA-Z_$] [a-zA-Z0-9_$]* !>> [a-zA-Z0-9_$]) val \ Keyword;

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
//   = ID key "@" Time time
//   | ID key;



// data Action
//   = action(ID key)
//   | action(ID key, Time tine)
//   | action(ID key, Time time, ID mechanism);

data Tutorial = tutorial(ID name)
              | tutorial(ID name, list[Lesson] lessons);

data ID
  = id(str val);

data Lesson = lesson(ID name)
            | lesson(ID name, list[Elem] elems);

data Elem 
    = dead_end(ID name)
    | win_condition(ID name)
    | verb_definition(ID name, Mechanism mechansism);

// data End =
//     end(ID name);

// data Verb
//     = verb(ID name, list[Mechanism] mechansisms);

data Mechanism 
    = mechanism(list[Number] rule_nrs);



public start[Tutorial] cddl_parse(str input, loc file) = parse(#start[Tutorial], input, file);
  
public start[Tutorial] cddl_parse(loc file) = parse(#start[Tutorial], file);

public Tutorial cddl_build(loc file) = implode(#Tutorial, cddl_parse(file));
