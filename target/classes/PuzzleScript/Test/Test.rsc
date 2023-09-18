module PuzzleScript::Test::Test

import IO;
import PuzzleScript::Test::Domain;
import Type;


void get_tutorial() {

    loc file = |project://automatedpuzzlescript/src/PuzzleScript/Test/TutorialDSL.cddl|;

    Tutorial tutorial = tutorial_build(file);
    // for (Lesson lesson <- tutorial.lessons) {
    //     println("Player learns the following verbs in lesson <lesson.number>");
    //     for (Elem elem <- lesson.elems) {
    //         println(elem.dead_end);
    //         println(elem.dead_end);
    //     }
    // }

}