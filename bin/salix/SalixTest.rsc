module salix::SalixTest

import PuzzleScript::Report;
import PuzzleScript::Load;
import PuzzleScript::Engine;
import PuzzleScript::Compiler;
import PuzzleScript::Checker;
import PuzzleScript::AST;
import IO;
import util::Eval;
import Type;
import util::Math;
import List;
import String;

import salix::HTML;
import salix::Core;
import salix::App;
import salix::Index;

alias Model = tuple[str input, str title, Engine engine, int update];
// alias App = SalixApp[Model];

data Msg  
     = roll()
     | newFace(int face)
     ;


void main() {

	PSGame game;
	Checker checker;
	Engine engine;
	Level level;

    println("1");
	game = load(|project://AutomatedPuzzleScript/bin/PuzzleScript/Test/demo/blockfaker.PS|);
    println("2");

	checker = check_game(game);
    println("3");

    engine = compile(checker);
    println("4");

	Model init() = <"none", "test", engine, 0>;
    println("5");

	SalixApp[Model] gameApp(str appId = "root") = makeApp(appId, init, view, update);
    println("6");

    
    println("Making gameWebApp");

	App[str] gameWebApp()
	  = webApp(
	      gameApp(), 
	      |project://AutomatedPuzzleScript/src/PuzzleScript/Interface/index.html|, 
	      |project://AutomatedPuzzleScript/src|
	    );
	    
	return gameWebApp;


}

Model update(Msg msg, Model model){
	int start_time = userTime();
	
	if (model.engine.current_level is level){
		switch(msg){
			case direction(int i): {
				switch(i){
					case 37: model.input = "left";
					case 38: model.input = "up";
					case 39: model.input = "right";
					case 40: model.input = "down";
				}
			}
			case action(): model.input = "action";
			case undo(): model.input = "undo";
			case restart(): model.input = "restart";
			case win(): model.engine.win_keyword = true;
			default: return model;
		}
		
		model.engine.msg_queue = [];
		<model.engine, model.engine.current_level> = do_turn(model.engine, model.engine.current_level, model.input);
	}
	
	bool victory = is_victorious(model.engine, model.engine.current_level);
	if (victory && is_last(model.engine)){
		model.engine = do_victory(model.engine);
	} else if (victory) {
		model.engine = change_level(model.engine, model.engine.index + 1);
	}
	
	model.engine.abort = false;
	model.update = userTime() - start_time;
	return model;
}

void view(Model m){
	int start_time = userTime();
	div(class("main"), () {
		//p(m.input);
		h2(m.title);
		//p("View: <view_time/1000000> ms");
		//p("Update: <m.update/1000000> ms");
	});
	
	
}
