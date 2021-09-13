module PuzzleScript::Interface::Interface

import PuzzleScript::Compiler;
import PuzzleScript::Engine;
import PuzzleScript::Load;
import PuzzleScript::Checker;
import PuzzleScript::AST;

import salix::HTML;
import salix::App;

import List;

alias Model = tuple[str input, str title, Engine engine];

data Msg 
	= left() 
	| right() 
	| up() 
	| down() 
	| action() 
	| undo() 
	| restart()
	| win()
	;

Model update(Msg msg, Model model){
	switch(msg){
		case left(): model.input = "left";
		case right(): model.input = "right";
		case up(): model.input = "up";
		case down(): model.input = "down";
		case action(): model.input = "action";
		case undo(): model.input = "undo";
		case restart(): model.input = "restart";
		case win(): model.engine.win_keyword = true;
	}
	
	model.engine.msg_queue = [];
	<model.engine, model.engine.current_level> = do_turn(model.engine, model.engine.current_level, model.input);
	
	bool victory = is_victorious(model.engine, model.engine.current_level);
	if (victory && is_last(model.engine)){
		model.engine = do_victory(model.engine);
	} else if (victory) {
		model.engine = change_level(model.engine, model.engine.index + 1);
	}
	
	model.engine.abort = false;
	return model;
}

void view(Model m){
	div(() {
		h2(m.title);
		div(class("left"), () {
			h3("Buttons");
			button(onClick(left()), "left");
			button(onClick(right()), "right");
			button(onClick(up()), "up");
			button(onClick(down()), "down");
			button(onClick(action()), "action");
			button(onClick(restart()), "restart");
			button(onClick(undo()), "undo");
			button(onClick(win()), "win");
		
			h3("Victory Conditions");
			for (Condition cond <- m.engine.conditions){
				bool met = is_met(cond, m.engine.current_level);
				p(() {
					span("<toString(cond)>: ");
					b(class("<met>"), "<met>");
				});
			}
			
			h3("Rules");
			for (int i <- [0..size(m.engine.rules)]){
				Rule rule = m.engine.rules[i];
				str left_original = intercalate(" ", [toString(x) | x <- rule.original.left]);
				str right_original = intercalate(" ", [toString(x) | x <- rule.original.right]);
				str message = "";
				if (!isEmpty(rule.original.message)) message = "message <rule.original.message[0]>";
				
				p(() {
					button(\type("button"), class("collapsible"), "+");
					span("\t <left_original> -\> <right_original> <message>: ");
					b(class("<rule.used > 0>"), "<rule.used>");
				});
				
				div(class("content"), () {
					for (str r <- rule.left) p(class("rule"), r);
					br();
					for (str r <- rule.right) p(class("rule"), r);
				});
			}
			
			h3("Messages");
			for (str msg <- m.engine.msg_queue){
				p(msg);
			}
			
		});
		
		
		if (m.engine.current_level is message){
			div(class("left"), () {
				p("#####################################################");
				p(m.engine.current_level.msg);
				p("#####################################################");
			});
		} else {
			div(class("left"), () {
				h3("Layers");
				list[Layer] layers = reverse(m.engine.current_level.layers);
				for (Layer lyr <- layers){
					table(() {
						for (Line line <- lyr) {
							tr(() {
								for (Object obj <- line) {
									str c = "object";
									if (obj is transparent) {
										td(class(c), class("trans"), obj.name[0]);
									} else {
										td(class(c), obj.name[0]);
									}	
									
								}
								td(class("trans"), "t");
								td(class("objects"), "\t\t" + intercalate(", ", dup([x.name | x <- line, !(x is transparent)])));
							});
						}
						
					});
					
					br();
				}
			});
		}
	});

}

App[str]() load_app(loc src){
	PSGAME game = load(src);
	Checker checker = check_game(game);
	Engine engine = compile(checker);
	
	return load_app(engine);
}

App[str]() load_app(Engine engine){
	str title = get_prelude(engine.game.prelude, "title", "Unknown");

	Model init() = <"none", title, engine>;
	SalixApp[Model] gameApp(str appId = "root") = makeApp(appId, init, view, update);
	
	App[str] gameWebApp()
	  = webApp(
	      gameApp(), 
	      |project://AutomatedPuzzleScript/src/PuzzleScript/Interface/index.html|, 
	      |project://AutomatedPuzzleScript/src|
	    );
	    
	return gameWebApp;
}

//Test
//import PuzzleScript::Interface::Interface;
// load_app(|project://AutomatedPuzzleScript/src/PuzzleScript/Test/Games/Game1.PS|)();
// load_app(|project://AutomatedPuzzleScript/src/PuzzleScript/Test/Engine/AdvancedGame1.PS|)();


