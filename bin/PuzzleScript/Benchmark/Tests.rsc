module PuzzleScript::Benchmark::Tests

import PuzzleScript::Benchmark::Benchmark;

void main(){
	loc g = |project://automatedpuzzlescript/src/PuzzleScript/Test/Games/Game1.PS|;
	
	benchmark_all(g);
}
