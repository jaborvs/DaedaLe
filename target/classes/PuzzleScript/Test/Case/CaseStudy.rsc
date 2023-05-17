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
	println("Unidirectional Case");
	PSGAME game = load(|project://AutomatedPuzzleScript/src/PuzzleScript/Test/Case/Modification1.PS|);
	Checker checker = check_game(game);
	Engine engine = compile(checker);
	DynamicChecker d_checker = analyse_stupid_solution(engine);
	println(d_checker.solutions);
}

// Remove rule \#2
void modif_2(){
	println("Impossible Win Case");
	PSGAME game = load(|project://AutomatedPuzzleScript/src/PuzzleScript/Test/Case/Modification2.PS|);
	Checker checker = check_game(game);
	Engine engine = compile(checker);
	DynamicChecker d_checker = analyse_game(engine);
	print_msgs(d_checker);
}

// Remove Exit objects from levels
void modif_3(){
	println("Missing Objects");
	PSGAME game = load(|project://AutomatedPuzzleScript/src/PuzzleScript/Test/Case/Modification3.PS|);
	Checker checker = check_game(game);
	Engine engine = compile(checker);
	DynamicChecker d_checker = analyse_game(engine);
	print_msgs(d_checker);
}

void modif_4(){

}


void main(){
	//modif_1();
	//modif_2();
	modif_3();
}