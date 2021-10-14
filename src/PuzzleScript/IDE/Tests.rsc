module PuzzleScript::IDE::Tests

import PuzzleScript::IDE::IDE;
import IO;
import PuzzleScript::Load;
import ParseTree;

void main(){
	println("Test");
	tree = ps_parse(|project://AutomatedPuzzleScript/src/PuzzleScript/Test/Games/Game2.PS|);
	//ps_outline(tree);
	//ps_check(tree);
	//
	//visit(tree){
	//	case c: appl(prod(def, symbols, tags), args): {
	//		println("<c>: <tags>");
	//		println();
	//	}
	//}
	
	//run_game(tree, |project://AutomatedPuzzleScript/src/PuzzleScript/IDE/Tests.rsc|);
	
	build_game(tree);


}