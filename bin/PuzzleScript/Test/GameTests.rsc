module PuzzleScript::Test::GameTests

import IO;
import List;
import PuzzleScript::Load;

bool try_parse(loc pos){
	try
		ps_parse(pos);
	catch: return false;
	
	return true;
}

//bool try_parse(loc pos){
//	ps_parse(pos);
//	
//	return true;
//}

void main(){
	loc pos = |project://AutomatedPuzzleScript/src/PuzzleScript/Test/GameTest|;
	list[str] ignored = ["README.md"];
	list[str] entries = [x | str x <- listEntries(pos), x notin ignored];
	list[str] s = [];
	list[str] f = [];
	
	for (str x <- entries) {
		bool success = try_parse(pos + x);
		if (success){
			s += [x];
		} else {
			f += [x];
			println("Failed: <x> - <pos + x>");
		}
		
	}
	println();
	
	println("Checked <size(entries)> games");
	println(" - Success: <size(s)>");
	println(" - Failures: <size(f)>");
}
