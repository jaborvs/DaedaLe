module PuzzleScript::Test::Tests

import PuzzleScript::Syntax;
import ParseTree;
import IO;
import vis::Figure;
import vis::ParseTree;
import vis::Render;

void main(){
	render(visParsetree(parse(
		#RuleData, 
		|project://AutomatedPuzzleScript/src/PuzzleScript/Test/Test.PS|
	)));
}