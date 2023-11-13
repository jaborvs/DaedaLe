module PuzzleScript::Tutorials::Syntax

import PuzzleScript::Tutorials::AST;
import ParseTree;

start syntax Tutorial
  = tutorial: "tutorial" ID "{" Verb* verbs Lesson* lessons "}";

syntax Lesson
  = lesson: "lesson" Number ":" ID name "{" Elem* elems "}";

syntax Elem
    = description: STRING text
    | dead_end: "fail if" {ID ","}* names
    | win_condition: "learn to" {ID ","}* names;

syntax Verb
  = verb: "verb" ID name "[" {Number","}* numbers "]";

layout LAYOUTLIST
  = LAYOUT* !>> "//" !>> "/*";

lexical LAYOUT
  = Comment
  | [\t-\n \r \ ];
  
lexical STRING
    = [\"] ![\"]* [\"];

lexical Comment
  = "//" ![\n]* [\n];

lexical Number
 = [0-9]+ val;

lexical ID = id: [a-z0-9.A-Z#_+]+ !>> [a-z0-9.A-Z#_+] \ Keywords;

keyword Keywords = "lesson" | "verb";
