module PuzzleScript::Test::Test

import IO;
import PuzzleScript::Test::Syntax;
import PuzzleScript::Test::AST;
import Type;


void get_tutorial() {

    loc file = |project://automatedpuzzlescript/src/PuzzleScript/Test/TutorialDSL.cddl|;
    str content = readFile(file);

    println(content);

    Tutorial tutorial = tutorial_build(content);
    println(tutorial);
    // for (Lesson lesson <- tutorial.lessons) {
    //     println("Player learns the following verbs in lesson <lesson.number>");
    //     for (Elem elem <- lesson.elems) {
    //         println(elem.dead_end);
    //         println(elem.dead_end);
    //     }
    // }

}