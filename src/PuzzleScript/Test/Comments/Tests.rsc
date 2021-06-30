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
		#Sounds,
		|project://AutomatedPuzzleScript/src/PuzzleScript/Test/Comments/Test1.PS|
	);
	
	println("Inline");
	parse(
		#Sounds,
		|project://AutomatedPuzzleScript/src/PuzzleScript/Test/Comments/Test2.PS|
	);
	
	println("Multi line comment");
	parse(
		#Sounds,
		|project://AutomatedPuzzleScript/src/PuzzleScript/Test/Comments/Test3.PS|
	);
	
	print("Nested in code");
	parse(
		#Sounds,
		|project://AutomatedPuzzleScript/src/PuzzleScript/Test/Comments/Test4.PS|
	);
	
	print("Nested in other comment");
	parse(
		#Sounds,
		|project://AutomatedPuzzleScript/src/PuzzleScript/Test/Comments/Test5.PS|
	);
	
	print("All");
	parse(
		#Sounds,
		|project://AutomatedPuzzleScript/src/PuzzleScript/Test/Comments/Test6.PS|
	);
}
