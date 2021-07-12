module PuzzleScript::Test::Implode::Tests

import PuzzleScript::Syntax;
import PuzzleScript::AST;
import ParseTree;
import IO;

void main(){
	println("Prelude");
	implode(
		#PRELUDE,
		parse(
			#Prelude, 
			|project://AutomatedPuzzleScript/src/PuzzleScript/Test/Sections/Prelude.PS|
		)
	);
	
	println("Object");
	implode(
		#SECTION,
		parse(
			#Section, 
			|project://AutomatedPuzzleScript/src/PuzzleScript/Test/Sections/Objects.PS|
		)
	);
	
	//println("Legend");
	//implode(
	//	#SECTION,
	//	parse(
	//		#Section, 
	//		|project://AutomatedPuzzleScript/src/PuzzleScript/Test/Sections/Legend.PS|
	//	)
	//);
	
	println("Sound");
	implode(
		#SECTION,
		parse(
			#Section, 
			|project://AutomatedPuzzleScript/src/PuzzleScript/Test/Sections/Sounds.PS|
		)
	);
	
	println("Layers");
	implode(
		#SECTION,
		parse(
			#Section, 
			|project://AutomatedPuzzleScript/src/PuzzleScript/Test/Sections/Layers.PS|
		)
	);
	
	//println("Rule");
	//implode(
	//	#SECTION,
	//	parse(
	//		#Section, 
	//		|project://AutomatedPuzzleScript/src/PuzzleScript/Test/Sections/Rules.PS|
	//	)
	//);
	
	println("Condition");
	implode(
		#SECTION,
		parse(
			#Section, 
			|project://AutomatedPuzzleScript/src/PuzzleScript/Test/Sections/Conditions.PS|
		)
	);
	
	println("Level");
	implode(
		#SECTION,
		parse(
			#Section, 
			|project://AutomatedPuzzleScript/src/PuzzleScript/Test/Sections/Levels.PS|
		)
	);
}
