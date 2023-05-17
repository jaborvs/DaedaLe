module PuzzleScript::Benchmark::Benchmark

import util::Benchmark;
import IO;

import PuzzleScript::Interface::Interface;
import PuzzleScript::AST;
import PuzzleScript::Syntax;
import PuzzleScript::Load;
import PuzzleScript::Compiler;
import PuzzleScript::Checker;
import PuzzleScript::Engine;

void benchmark_interface(loc src){
	PSGAME game = load(src);
	Checker checker = check_game(game);
	Engine engine = compile(checker);
	
	Model m = <"none", "Benchmark Test", engine>;
	
	int view_time = cpuTime( (){ view(m); } );
	println("View: <view_time>");
	
	int update_time = cpuTime( (){ update(right(), m); } );
	println("Update: <update_time>");
	
}

void benchmark_load(loc src){
	PSGame tree;
	
	int parse_time = cpuTime( (){ tree = ps_parse(src); } );
	println("Parse: <parse_time>");
	
	int implode_time = cpuTime( (){ ps_implode(tree); } );
	println("Implode: <implode_time>");
	
	int load_time = cpuTime( (){ load(src); } );
	println("Load: <load_time>");
	
}

void benchmark_compile(loc src){
	PSGAME game = load(src);
	Engine engine;
	Checker checker;
	
	int checker_time = cpuTime( (){ checker = check_game(game); } );
	println("Check: <checker_time>");
	
	int compile_time = cpuTime( (){ engine = compile(checker); } );
	println("Compile: <compile_time>");

}

void benchmark_loop(loc src){
	PSGAME game = load(src);
	Checker checker = check_game(game);
	Engine engine = compile(checker);
	
	int turn_time = cpuTime( (){ <engine, engine.current_level> = do_turn(engine, engine.current_level, "left"); } );	
	println("Turn: <turn_time>");
}

void benchmark_all(loc src){

	PSGAME game = load(src);
	Checker checker = check_game(game);
	Engine engine = compile(checker);
	
	str title = get_prelude(game.prelude, "title", "Unknown");

	println(title);
	println("LOAD");
	benchmark_load(src);
	println();
	
	println("COMPILE");
	benchmark_compile(src);
	println();
	
	println("LOOP");
	benchmark_loop(src);
	println();
}


