module PuzzleScript::Test::Test

import IO;
import PuzzleScript::Test::Domain;
import Type;


void get_tutorial() {

    loc file = |project://automatedpuzzlescript/src/PuzzleScript/Test/TutorialDSL.cddl|;

    Tutorial tutorial = cddl_build(file);
    println(tutorial);

}