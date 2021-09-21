module PuzzleScript::Analyser

import PuzzleScript::Messages;
import PuzzleScript::Compiler;
import PuzzleScript::AST;
import PuzzleScript::Engine;
import IO;

// a list of stupid solutions that game designers probably want to avoid making possible
data StupidSolutions
	// solving the game by only going in one direction or by pressing the action button
	= unidirectional(str dir, MsgType t, loc pos)
	
	// solving a level without using any rules, this means the win condition requires
	// the player object and optionally some other already fulfilled condition
	| unruled(MsgType t, loc pos)
	;

// a list of msgs that are detected through semi-dynamic analysis, we don't always
// have to run the game to figure them out but we do have to compile it
data DynamicMsgs
	// we have a level that matches our required win conditions before
	// the player even interacts with it
	= instant_victory(MsgType t, loc pos)
	
	// we have levels that cannot be solved because the rules do not spawn 
	// the necessary items and they are not available off the bat
	| unsolvable_rules_missing_items(MsgType t, loc pos)
	
	// levels should increase in difficulty, increasing difficulty is
	// defined as a mix of increased size, increased number of items
	// and using more rules than the previous ones
	| difficulty_not_increasing(MsgType t, loc pos)
	
	// a solution to a level has been found but some rules have gone unused
	// a rule is unused if it is never fully succesffuly matched, it is fine
	// if it doesn't change anything, as long as it can match, or is it?
	| unused_rule(MsgType t, loc pos)
	
	// a rule is too similar to another rule, not simply the string but
	// what it does and what it references
	| similar_rules(MsgType t, loc pos)
	;
	
public str toString(DynamicMsgs m: instant_victory(MsgType t, loc pos))
	= "Level can be won without playing interaction. <pos>";
	
alias DynamicChecker = tuple[
	list[StupidSolutions] stupid_solutions,
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

DynamicChecker analyse_game(Engine engine){
	DynamicChecker c = new_dynamic_checker();

	for (Level level <- engine.levels){
		c = analyse_instant_victory(engine, level, c);
	}
	
	
	return c;
}
