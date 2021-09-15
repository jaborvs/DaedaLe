module PuzzleScript::Analyser

import PuzzleScript::Checker;
import PuzzleScript::Messages;
import PuzzleScript::Compiler;
import PuzzleScript::AST;
import IO;

//errors
//	instant_victory
Checker analyse_instant_victory(Engine engine, Checker c){
	for (Level l <- engine.levels){
		if (!(l is level)) continue;
		
		engine.current_level = l;
		if (is_victorious(engine)) c.msgs += [instant_victory(error(), l.original@location)];
	}
	
	return c;
}

Checker analyse_game(Engine engine, Checker c){
	c = analyse_instant_victory(engine, c);
	
	return c;
}
