module PuzzleScript::Tutorials::TutorialParseTest

import IO;
import PuzzleScript::Tutorials::Syntax;
import PuzzleScript::Tutorials::AST;
import Type;


void get_tutorial() {

    loc file = |project://automatedpuzzlescript/src/PuzzleScript/Test/TutorialDSL.cddl|;
    str content = readFile(file);

    println(content);

    Tutorial tutorial = tutorial_build(content);
    println(tutorial);

}