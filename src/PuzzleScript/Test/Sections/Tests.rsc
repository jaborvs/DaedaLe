module PuzzleScript::Test::Sections::Tests

import PuzzleScript::Syntax;
import ParseTree;
import IO;
import vis::Figure;
import vis::ParseTree;
import vis::Render;

void main(){
	println("Prelude");
	parse(
		#Prelude, 
		|project://AutomatedPuzzleScript/src/PuzzleScript/Test/Sections/Prelude.PS|
	);
	
	println("Object");
	parse(
		#Objects, 
		|project://AutomatedPuzzleScript/src/PuzzleScript/Test/Sections/Objects.PS|
	);
	
	println("Legend");
	parse(
		#Legend, 
		|project://AutomatedPuzzleScript/src/PuzzleScript/Test/Sections/Legend.PS|
	);
	
	println("Sound");
	parse(
		#Sounds, 
		|project://AutomatedPuzzleScript/src/PuzzleScript/Test/Sections/Sounds.PS|
	);
	
	println("Layers");
	parse(
		#Layers, 
		|project://AutomatedPuzzleScript/src/PuzzleScript/Test/Sections/Layers.PS|
	);
	
	println("Rule");
	parse(
		#Rules, 
		|project://AutomatedPuzzleScript/src/PuzzleScript/Test/Sections/Rules.PS|
	);
	
	println("Condition");
	parse(
		#WinConditions, 
		|project://AutomatedPuzzleScript/src/PuzzleScript/Test/Sections/Conditions.PS|
	);
	
	println("Level");
	parse(
		#Levels, 
		|project://AutomatedPuzzleScript/src/PuzzleScript/Test/Sections/Levels.PS|
	);
}