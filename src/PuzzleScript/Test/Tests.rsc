module PuzzleScript::Test::Tests

import PuzzleScript::Load;
import IO;

void main(){
	println("Game 1");
	ps_parse(
		|project://AutomatedPuzzleScript/src/PuzzleScript/Test/GameTest/actiontest.txt|
	);
}
