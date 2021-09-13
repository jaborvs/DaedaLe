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
	game = load(|project://AutomatedPuzzleScript/src/PuzzleScript/Test/Games/Game1.PS|);
	checker = check_game(game);
	engine = compile(checker);
	load_app(engine)();
	
}