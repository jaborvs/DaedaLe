module PuzzleScript::Analyser

import PuzzleScript::Messages;
import PuzzleScript::Compiler;
import PuzzleScript::AST;
import PuzzleScript::Engine;

import IO;
import List;
	
alias DynamicChecker = tuple[
	list[StupidSolutions] solutions,
	list[DynamicMsgs] msgs
];

//This checker does not check for code bug it checks for "gameplay" bugs, which means 
// unintended behavior in the game caused by valid code but unintended interactions
DynamicChecker new_dynamic_checker()
	= <[], []>
	;

//errors
//	instant_victory
DynamicChecker analyse_instant_victory(Engine engine, Level level, DynamicChecker c){
	for (Level l <- engine.levels){
		if (!(l is level)) continue;
		
		engine.current_level = l;
		if (is_victorious(engine, level)) c.msgs += [instant_victory(error(), l.original@location)];
	}
	
	return c;
}

DynamicChecker analyse_rules(DynamicChecker c, Rule r1, Rule r2){
	if (any(RulePart x <- r1.converted_left, x in r2.converted_left)) c.msgs += [similar_rules(error(), r1.original@location)];
	if (any(RulePart x <- r1.converted_right, x in r2.converted_right)) c.msgs += [similar_rules(error(), r1.original@location)];
	
	return c;
}

DynamicChecker analyse_game(Engine engine){
	DynamicChecker c = new_dynamic_checker();

	for (Level level <- engine.levels){
		c = analyse_instant_victory(engine, level, c);
	}
	
	for (int i_r1 <- [0..size(engine.rules)]){
		for (int i_r2 <- [i_r1+1..size(engine.rules)]){
			c = analyse_rules(c, engine.rules[i_r1], engine.rules[i_r2]);
		}
	}
	
	
	return c;
}

DynamicChecker analyse_stupid_solution(Engine engine){
	DynamicChecker c = new_dynamic_checker();
	
	return c;
	
}

void print_msgs(DynamicChecker checker){
	list[DynamicMsgs] error_list = [x | DynamicMsgs x <- checker.msgs, x.t == error()];
	list[DynamicMsgs] warn_list  = [x | DynamicMsgs x <- checker.msgs, x.t == warn()];
	list[DynamicMsgs] info_list  = [x | DynamicMsgs x <- checker.msgs, x.t == info()];
	
	if (!isEmpty(error_list)) {
		println("ERRORS");
		for (DynamicMsgs msg <- error_list) {
			println(toString(msg));
		}
	}
	
	if (!isEmpty(warn_list)) {
		println("WARNINGS");
		for (DynamicMsgs msg <- warn_list) {
			println(toString(msg));
		}
	}
	
	if (!isEmpty(info_list)) {
		println("INFO");
		for (DynamicMsgs msg <- info_list) {
			println(toString(msg));
		}
	}
}
