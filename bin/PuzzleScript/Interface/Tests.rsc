module PuzzleScript::Interface::Tests

import PuzzleScript::Interface::Interface;
import PuzzleScript::Compiler;
import PuzzleScript::Engine;
import PuzzleScript::Load;
import PuzzleScript::Checker;

import salix::HTML;
import salix::App;

import IO;

void main(){
	println("Interface Test");
	game = load(|project://automatedpuzzlescript/Tutomate/src/PuzzleScript/Test/DEMO.PS|);
	checker = check_game(game);
	engine = compile(checker);
	load_app(engine)();
	
}