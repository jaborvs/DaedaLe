module PuzzleScript::Test::Engine::EvalExample

import util::Eval;
import IO;

data Animal = dog() | cat();

void main(){	
	bool boolean = [*_, cat(), *_] := [dog(), cat()];
	if (boolean) println("True 1");
	
	println("[*_, cat(), *_] := [dog(), cat()];");
	Result[bool] re = eval(#bool, "[*_, cat(), *_] := [dog(), cat()];");
	if (re.val) println("True 2");

}
