module PuzzleScript::Tutorials::AST

import PuzzleScript::Tutorials::Syntax;
import ParseTree;

data Tutorial = tutorial(ID name, list[Verb] verbs, list[Lesson] lessons);

data Lesson = lesson(int number, list[Elem] elems)
            | lesson(int number, ID name, list[Elem] elems);

data Elem 
    = description(str text)
    | dead_end(list[ID] names)
    | win_condition(list[ID] names);

data VerbAnnotation= verb(ID name, list[int] numbers);

data ID = id(str name);


// public start[Tutorial] tutorial_parse(str input, loc file) = parse(#start[Tutorial], input, file);
public start[Tutorial] tutorial_parse(str content) = parse(#start[Tutorial], content);

public Tutorial tutorial_build(str content) = implode(#Tutorial, tutorial_parse(content));
