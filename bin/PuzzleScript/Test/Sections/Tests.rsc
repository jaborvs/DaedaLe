module PuzzleScript::Test::Sections::Tests

import PuzzleScript::Syntax;
import ParseTree;
import IO;
import vis::Figure;
import vis::ParseTree;
import vis::Render;

bool ambi = false;

void main(){
	println("Prelude");
	parse(
		#Prelude, 
		|project://AutomatedPuzzleScript/src/PuzzleScript/Test/Sections/Prelude.PS|,
		allowAmbiguity=ambi
	);
	
	println("Object");
	parse(
		#Objects, 
		|project://AutomatedPuzzleScript/src/PuzzleScript/Test/Sections/Objects.PS|,
		allowAmbiguity=ambi
	);
	
	println("Legend");
	parse(
		#Legend, 
		|project://AutomatedPuzzleScript/src/PuzzleScript/Test/Sections/Legend.PS|,
		allowAmbiguity=ambi
	);
	
	println("Sound");
	parse(
		#Sounds, 
		|project://AutomatedPuzzleScript/src/PuzzleScript/Test/Sections/Sounds.PS|,
		allowAmbiguity=ambi
	);
	
	println("Layers");
	parse(
		#Layers, 
		|project://AutomatedPuzzleScript/src/PuzzleScript/Test/Sections/Layers.PS|,
		allowAmbiguity=ambi
	);
	
	println("Rule");
	parse(
		#Rules, 
		|project://AutomatedPuzzleScript/src/PuzzleScript/Test/Sections/Rules.PS|,
		allowAmbiguity=ambi
	);
	
	println("Condition");
	parse(
		#WinConditions, 
		|project://AutomatedPuzzleScript/src/PuzzleScript/Test/Sections/Conditions.PS|,
		allowAmbiguity=ambi
	);
	
	println("Level");
	parse(
		#Levels, 
		|project://AutomatedPuzzleScript/src/PuzzleScript/Test/Sections/Levels.PS|,
		allowAmbiguity=ambi
	);
}