module PuzzleScript::Test::Analyser::Tests

import PuzzleScript::Load;
import PuzzleScript::Compiler;
import PuzzleScript::Checker;
import PuzzleScript::AST;
import PuzzleScript::Analyser;
import PuzzleScript::Messages;

import IO;

void main() {
	PSGAME game;
	Checker checker;
	Engine engine;
	DynamicChecker d_checker;
	
	println("Instant Victory");
	game = load(|project://automatedpuzzlescript/src/PuzzleScript/Test/Analyser/BadGame1InstantVictory.PS|);
	checker = check_game(game);
	engine = compile(checker);
	d_checker = analyse_game(engine);
	print_msgs(d_checker);
	
	println("Rule Similarity");
	game = load(|project://automatedpuzzlescript/src/PuzzleScript/Test/Analyser/BadGame1RuleSimilar.PS|);
	checker = check_game(game);
	engine = compile(checker);
	d_checker = analyse_game(engine);
	print_msgs(d_checker);
	
	println("Unidirectional Solutions");
	game = load(|project://automatedpuzzlescript/src/PuzzleScript/Test/Analyser/BadGame1Unidirectional.PS|);
	checker = check_game(game);
	engine = compile(checker);
	d_checker = analyse_stupid_solution(engine);
	print_msgs(d_checker);
	
	println("Difficulty Increase");
	game = load(|project://automatedpuzzlescript/src/PuzzleScript/Test/Analyser/BadGame1RuleSimilar.PS|);
	checker = check_game(game);
	engine = compile(checker);
	d_checker = analyse_game(engine);
	print_msgs(d_checker);
	
	println("Get Rule type");
	game = load(|project://automatedpuzzlescript/src/PuzzleScript/Test/Analyser/BadGame1RuleCompare.PS|);
	checker = check_game(game);
	engine = compile(checker);
	
	for (Rule r <- engine.rules){
		println(get_rule_type(r));
	}
	
	println("Impossible Victory");
	game = load(|project://automatedpuzzlescript/src/PuzzleScript/Test/Analyser/BadGame1ImpossibleVictory.PS|);
	checker = check_game(game);
	engine = compile(checker);
	//d_checker = analyse_game(engine);
	d_checker = analyse_unrulable_condition(new_dynamic_checker(), engine, engine.conditions[0]);
	println(d_checker.msgs);
	
}
 