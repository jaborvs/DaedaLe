module PuzzleScript::Test::Tests

import PuzzleScript::Load;
import IO;
import ParseTree;

void main(){
	println("Game 1");
	Tree t = ps_parse(|project://AutomatedPuzzleScript/src/PuzzleScript/Test/Game1.txt|);	  
	visit(t){
		case c: appl(prod(def, symbols, {\tag("category"("orange"))}), args): {
			println(c);
		}
	}
	
}
