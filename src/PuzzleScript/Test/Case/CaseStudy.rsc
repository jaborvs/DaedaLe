module PuzzleScript::Test::Case::CaseStudy

import PuzzleScript::Load;
import PuzzleScript::Compiler;
import PuzzleScript::Checker;
import PuzzleScript::AST;
import PuzzleScript::Analyser;
import PuzzleScript::Messages;

import IO;

// Remove the "No Objective" win condition
void modif_1(){

	PSGAME game;
	Checker checker;
	Engine engine;
	DynamicChecker d_checker;

	println("Unidirectional Case");
	game = load(|project://AutomatedPuzzleScript/src/PuzzleScript/Test/Case/Modification1.PS|);
	checker = check_game(game);
	engine = compile(checker);
	d_checker = analyse_stupid_solution(engine);
	print_msgs(d_checker);
}

// Remove rule \#2
void modif_2(){

}

// Remove Exit objects from levels
void modif_3(){

}

void modif_4(){

}


void main(){
	modif_1();
}