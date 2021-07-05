module PuzzleScript::Test::Implode::Tests

import PuzzleScript::AST;
import PuzzleScript::Syntax;
import ParseTree;

void main(){
	Prelude prelude = parse(
		#Prelude,
		|project://AutomatedPuzzleScript/src/PuzzleScript/Test/Implode/Test1.PS|
	);
	
	PRELUDE pr = implode(
		#PRELUDE,
		prelude
	);
}
