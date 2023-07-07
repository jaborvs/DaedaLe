module PuzzleScript::Interface::Interface

import PuzzleScript::Compiler;
import PuzzleScript::Engine;
import PuzzleScript::Load;
import PuzzleScript::Checker;
import PuzzleScript::AST;
import PuzzleScript::Analyser;
import PuzzleScript::Messages;

import salix::HTML;
import salix::App;

import List;
import String;
import IO;
import util::Benchmark;
import util::Math;
import Message;

// alias Model = tuple[str input, str title, Engine engine, Checker checker, int update, set[Msg] msgs];
alias Model = tuple[str input, str title, Engine engine, Checker checker, int update];

data Msg 
	= left() 
	| right() 
	| up() 
	| down() 
	| action() 
	| undo() 
	| restart()
	| win()
	| direction(int i)
	;

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
			// case win(): model.engine.win_keyword = true;
			default: return model;
		}
		
		// model.engine.msg_queue = [];
		<model.engine, model.engine.current_level> = execute_move(model.engine, model.engine, model.input);
	}

    return model;
	
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

void view_sprite(Model m, str _ : "trans"){
	table(class("sprite"), class("cell"), () {
		for (int _ <- [0..5]){
			tr((){
				for (int _ <- [0..5]){
					td(class("pixel"), class("transparent"));
				}
			});
		}
	});
}



default void view_sprite(Model m, str name){
	ObjectData obj = m.engine.objects[name];
	table(class("sprite"), class("cell"), () {
		for (int i <- [0..5]){
			tr((){
				for (int j <- [0..5]){
					if(isEmpty(obj.sprite)){
						td(class("pixel"), class(toLowerCase(obj.colors[0])));
					} else {
						Pixel pix = obj.sprite[i][j];
						if (pix.pixel == "."){
							td(class("pixel"), class("transparent"));
						} else {
							td(class("pixel"), class(toLowerCase(obj.colors[toInt(pix.pixel)])));
						}
					}
					
				}
			});
		}
	});
}

void view_background(Model m){
	int s = size(m.engine.current_level.background);
	str name = m.engine.current_level.background[arbInt(s)];
	
	table(class("layer"), class("background"), () {
		for (int _ <- [0..m.engine.current_level.size.height]){
			tr(() {
				for (int _ <- [0..m.engine.current_level.size.width]){
					td(class(name), class("cell"), () {view_sprite(m, name);});
				}
			});
		}
	});
}

void view_level(Model m){
	if (m.engine.current_level is message){
		p("#####################################################");
		p(m.engine.current_level.msg);
		p("#####################################################");
	} else {
		list[Layer] layers = m.engine.current_level.layers;
		view_background(m);

        for (Coords coord <- m.engine.current_level.objects<0>) {

            if (size(m.engine.current_level.objects[coord]) > 0) {

                Object obj = m.engine.current_level.objects[coord][size(m.engine.current_level.objects[coord]) - 1];
                td(class(obj.name), class("cell"), () {view_sprite(m, obj.name);});

            } else {
                td(class("transparent"), class("cell"), () {view_sprite(m, "transparent");});
            }


        }

		// for (Layer lyr <- layers){
		// 	table(class("layer"), () {
		// 		for (Line line <- lyr) {
		// 			tr(() {
		// 				for (Object obj <- line) {
		// 					td(class(obj.name), class("cell"), () {view_sprite(m, obj.name);});
		// 				}
		// 			});
		// 		}
				
		// 	});
		// }
	}
}

// void view_panel(Model m){
// 	h3("Buttons");
// 	button(onClick(direction(37)), "left");
// 	button(onClick(direction(39)), "right");
// 	button(onClick(direction(38)), "up");
// 	button(onClick(direction(40)), "down");
// 	button(onClick(action()), "action");
// 	button(onClick(restart()), "restart");
// 	button(onClick(undo()), "undo");
// 	button(onClick(win()), "win");

// 	h3("Victory Conditions");
// 	for (Condition cond <- m.engine.conditions){
// 		bool met;
// 		if (m.engine.current_level is message){
// 			met = true;
// 		} else {
// 			met = is_met(cond, m.engine.current_level);
// 		}
// 		p(() {
// 			span("<toString(cond)>: ");
// 			b(class("<met>"), "<met>");
// 		});
// 	}
	
// 	h3("Rules");
// 	for (int i <- [0..size(m.engine.rules)]){
// 		Rule rule = m.engine.rules[i];
// 		str left_original = intercalate(" ", [toString(x) | x <- rule.original.left]);
// 		str right_original = intercalate(" ", [toString(x) | x <- rule.original.right]);
// 		str message = "";
// 		if (!isEmpty(rule.original.message)) message = "message <rule.original.message[0]>";
		
// 		p(() {
// 			button(\type("button"), class("collapsible"), "+");
// 			span("\t <left_original> -\> <right_original> <message>: ");
// 			b(class("<rule.used > 0>"), "<rule.used>");
// 		});
		
// 		div(class("content"), () {
// 			for (str r <- rule.left) p(class("rule"), r);
// 			br();
// 			for (str r <- rule.right) p(class("rule"), r);
// 		});
// 	}
// }

void view_panel(Model m){
    div(class("panel"), () {
        h3("Buttons");
        button(onClick(direction(37)), "left");
        button(onClick(direction(39)), "right");
        button(onClick(direction(38)), "up");
        button(onClick(direction(40)), "down");
        button(onClick(action()), "action");
        button(onClick(restart()), "restart");
        button(onClick(undo()), "undo");
        button(onClick(win()), "win");
    });
}

void view_layers(Model m){
	h3("Layers");
	if (m.engine.current_level is message){
		p("#####################################################");
		p(m.engine.current_level.msg);
		p("#####################################################");
	} else {
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
	}
}

void view(Model m){
	int start_time = userTime();
	
    div(class("main"), () {
		p(m.input);
		h2(m.title);
		div(class("left"), () {
            view_panel(m);
        });
		// div(class("left"), () {view_layers(m);});
		// div(class("left"), onKeyDown(direction), () {
		// 	h3("Level");
		// 	div(class("grid"), () {view_level(m);});
		// });
		int view_time = userTime() - start_time;
	});
}

App[str]() load_app(){
    
	PSGame game = load(|project://automatedpuzzlescript/bin/PuzzleScript/Test/Tutorials/heroes_of_sokoban.PS|);
	Checker checker = check_game(game);
	Engine engine = compile(checker);
	
	return load_app(engine);
}

App[str]() load_app(Engine engine, Checker checker){

    println("Loading app");

	str title = get_prelude(engine.game.prelude, "title", "Unknown");
	// DynamicChecker dc = analyse_game(engine);

    println("Past DynamicChecker");
	
	// Model init() = <"none", title, engine, 0, toMessages(dc.msgs)>;
	Model init() = <"none", title, engine, checker>;
	SalixApp[Model] gameApp(str appId = "root") = makeApp(appId, init, view, update);
    
    println("Making gameWebApp");

	App[str] gameWebApp()
	  = webApp(
	      gameApp(), 
	      |project://automatedpuzzlescript/src/PuzzleScript/Interface/index.html|, 
	      |project://automatedpuzzlescript/src|
	    );
	    
	return gameWebApp;
}

//Test
//import PuzzleScript::Interface::Interface;
// load_app(|project://automatedpuzzlescript/src/PuzzleScript/IDE/Game1.PS|)();
// load_app(|project://automatedpuzzlescript/src/PuzzleScript/Test/DEMO.PS|)();


