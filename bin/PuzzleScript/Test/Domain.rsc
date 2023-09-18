module PuzzleScript::Test::Domain

import ParseTree;

start syntax Tutorial
  = tutorial: "tutorial" ID "{" {Lesson";"}* "}";

syntax Lesson
  = lesson: "lesson" Number "{" "{" Verb* verbs "}" "{" Elem* elems "}" "}";

syntax Elem
    = dead_end: "fails if" {ID ","}* names
    | win_condition: "learns to" {ID ","}* names;

syntax Verb
  = verb: ID name "[" Number* numbers "]";

layout LAYOUTLIST
  = LAYOUT* !>> "//" !>> "/*";

lexical LAYOUT
  = Comment
  | [\t-\n \r \ ];
  
lexical Comment
  = "//" ![\n]* [\n];

lexical Number
 = [0-9]+ val;

lexical ID = [a-z0-9.A-Z#_+]+ !>> [a-z0-9.A-Z#_+];

data Tutorial = tutorial(str)
            | tutorial(str, list[Lesson] lessons);

data Lesson = lesson(int number)
            | lesson(int number, list[Verb] verbs)
            | lesson(int number, list[Verb] verbs, list[Elem] elems);

data Elem 
    = dead_end(list[str] names)
    | win_condition(list[str] names);

data Verb
    = verb(str name)
    | verb(str name, list[int] numbers);


// public start[Tutorial] tutorial_parse(str input, loc file) = parse(#start[Tutorial], input, file);
public start[Tutorial] tutorial_parse(str content) = parse(#start[Tutorial], content);

public Tutorial tutorial_build(str content) = implode(#Tutorial, tutorial_parse(content));
