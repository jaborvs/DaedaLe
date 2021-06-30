module PuzzleScript::Test::Games::Tests

import PuzzleScript::Syntax;
import ParseTree;
import IO;
import vis::Figure;
import vis::ParseTree;
import vis::Render;

void main(){
	println("Game 1");
	parse(
		#PSGame,
		|project://AutomatedPuzzleScript/src/PuzzleScript/Test/Games/Game1.PS|
	);
	
	println("Game 2");
	parse(
		#PSGame,
		|project://AutomatedPuzzleScript/src/PuzzleScript/Test/Games/Game2.PS|
	);
	
	println("Game 3");
	parse(
		#PSGame,
		|project://AutomatedPuzzleScript/src/PuzzleScript/Test/Games/Game2.PS|
	);
	
	println("Game 4");
	parse(
		#PSGame,
		|project://AutomatedPuzzleScript/src/PuzzleScript/Test/Games/Game4.PS|
	);
	
	//println("Game 5");
	//parse(
	//	#PSGame,
	//	|project://AutomatedPuzzleScript/src/PuzzleScript/Test/Games/Game5.PS|
	//);
	
	println("Game 5b");
	parse(
		#PSGame,
		|project://AutomatedPuzzleScript/src/PuzzleScript/Test/Games/Game5b.PS|
	);
	
	println("Game 6");
	parse(
		#PSGame,
		|project://AutomatedPuzzleScript/src/PuzzleScript/Test/Games/Game6.PS|
	);
	
	println("Game 7");
	parse(
		#PSGame,
		|project://AutomatedPuzzleScript/src/PuzzleScript/Test/Games/Game7.PS|
	);
	

}