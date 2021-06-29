module PuzzleScript::Test::Implode::Tests

import PuzzleScript::ADT;
import PuzzleScript::Syntax;
import ParseTree;

void main(){
	Prelude prelude = parse(
		#Prelude,
		|project://AutomatedPuzzleScript/src/PuzzleScript/Test/Implode/Test1.PS|
	);
	
	APrelude pr = implode(
		#APrelude,
		prelude
	);
}