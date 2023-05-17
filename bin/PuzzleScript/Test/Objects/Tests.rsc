module PuzzleScript::Test::Objects::Tests

import PuzzleScript::Syntax;
import ParseTree;
import IO;
import vis::Figure;
import vis::ParseTree;
import vis::Render;

void main(){
	println("Prelude");
	parse(
		#PreludeData, 
		|project://AutomatedPuzzleScript/src/PuzzleScript/Test/Objects/PreludeData.PS|
	);
	
	println("Object");
	parse(
		#ObjectData, 
		|project://AutomatedPuzzleScript/src/PuzzleScript/Test/Objects/ObjectData1.PS|
	);
	
	parse(
		#ObjectData, 
		|project://AutomatedPuzzleScript/src/PuzzleScript/Test/Objects/ObjectData2.PS|
	);
	
	parse(
		#ObjectData, 
		|project://AutomatedPuzzleScript/src/PuzzleScript/Test/Objects/ObjectData3.PS|
	);
	
	println("Legend");
	parse(
		#LegendData, 
		|project://AutomatedPuzzleScript/src/PuzzleScript/Test/Objects/LegendData1.PS|
	);
	parse(
		#LegendData, 
		|project://AutomatedPuzzleScript/src/PuzzleScript/Test/Objects/LegendData2.PS|
	);
	parse(
		#LegendData, 
		|project://AutomatedPuzzleScript/src/PuzzleScript/Test/Objects/LegendData3.PS|
	);
	
	println("Sound");
	parse(
		#SoundData, 
		|project://AutomatedPuzzleScript/src/PuzzleScript/Test/Objects/SoundData.PS|
	);
	
	println("Layer");
	parse(
		#LayerData, 
		|project://AutomatedPuzzleScript/src/PuzzleScript/Test/Objects/LayerData.PS|
	);
	
	println("Rule");
	parse(
		#RuleData, 
		|project://AutomatedPuzzleScript/src/PuzzleScript/Test/Objects/RuleData.PS|
	);
	
	println("Condition");
	parse(
		#ConditionData, 
		|project://AutomatedPuzzleScript/src/PuzzleScript/Test/Objects/ConditionData.PS|
	);
	
	println("Level");
	parse(
		#LevelData, 
		|project://AutomatedPuzzleScript/src/PuzzleScript/Test/Objects/LevelData.PS|
	);
}