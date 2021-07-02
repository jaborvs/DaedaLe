module PuzzleScript::Test::Comments::Tests

import PuzzleScript::Syntax;
import ParseTree;
import IO;
import vis::Figure;
import vis::ParseTree;
import vis::Render;

void main(){
	println("Comment");
	parse(
		#Section,
		|project://AutomatedPuzzleScript/src/PuzzleScript/Test/Comments/Test1.PS|
	);
	
	println("Inline");
	parse(
		#Section,
		|project://AutomatedPuzzleScript/src/PuzzleScript/Test/Comments/Test2.PS|
	);
	
	println("Multi line comment");
	parse(
		#Section,
		|project://AutomatedPuzzleScript/src/PuzzleScript/Test/Comments/Test3.PS|
	);
	
	println("Nested in code");
	parse(
		#Section,
		|project://AutomatedPuzzleScript/src/PuzzleScript/Test/Comments/Test4.PS|
	);
	
	println("Nested in other comment");
	parse(
		#Section,
		|project://AutomatedPuzzleScript/src/PuzzleScript/Test/Comments/Test5.PS|
	);
	
	println("All");
	parse(
		#Section,
		|project://AutomatedPuzzleScript/src/PuzzleScript/Test/Comments/Test6.PS|
	);
	
	// currently does not work because the grammar does not accept a game that ends with comments
	//println("Just comments");
	//parse(
	//	#Section,
	//	|project://AutomatedPuzzleScript/src/PuzzleScript/Test/Comments/Test7.PS|
	//);
}
