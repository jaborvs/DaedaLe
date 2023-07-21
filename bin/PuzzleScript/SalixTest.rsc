module PuzzleScript::SalixTest

import salix::HTML;
import salix::Core;
import salix::App;
import salix::Index;
import salix::ace::Editor;

import util::Benchmark;

import PuzzleScript::Load;
import PuzzleScript::Engine;
import PuzzleScript::Compiler;
import PuzzleScript::Checker;
import PuzzleScript::AST;
import PuzzleScript::DynamicAnalyser;

import String;
import List;
import Type;
import Set;
import IO;

public int i = 0;

alias Model = tuple[str input, str title, Engine engine, Checker checker, int update, str code];

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
    | editorChange(map[str,value] delta)
    | load_design()
    | analyse()
	;

Model update(Msg msg, Model model){

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
			case restart(): model.input = "restart";
            case editorChange(map[str,value] delta):
                println(delta);
            case load_design(): { 
                println("Reloading"); 
                model = reload(model.code);
            }
            case analyse(): {
                model.engine.level_data[model.engine.current_level.original].shortest_path = bfs(model.engine, ["up","down","left","right"], model.checker, "win");
            }
			default: return model;
		}
		
		// model.engine.msg_queue = [];
        if (msg is direction) model.engine = execute_move(model.engine, model.checker, model.input);
	}

    return model;
}

Model reload(str src) {

    println("Reloading game");

	PSGame game = load(src);
	Checker checker = check_game(game);
	Engine engine = compile(checker);

	str title = get_prelude(engine.game.prelude, "title", "Unknown");
 
	Model init() = <"none", title, engine, checker, 0, readFile(src)>;
    return init();

}

void view_panel(Model m){
    div(class("panel"), () {
        h3("Buttons");
        button(onClick(direction(37)), "left");
        button(onClick(direction(39)), "right");
        button(onClick(direction(38)), "up");
        button(onClick(direction(40)), "down");
    });
}

void view_options(Model m){
    div(class("panel"), () {
        h3("Get insights");
        button(onClick(analyse()), "Analyse");
    });
}

void view_results(Model m) {
    div(class("panel"), () {
        h3("Results");
        p("Shortest path = <m.engine.level_data[m.engine.current_level.original].shortest_path>");

    });
}

void view(Model m) {

    div(class("header"), () {
        h1(style(("text-shadow": "1px 1px 2px black")), "PuzzleScript");
    });

    div(class("main"), () {

		div(class("left"), () {
            // ace("myAce", event=onAceChange(editorChange), code = m.code);
            ace("myAce", code = m.code);
            button(onClick(load_design()), "reload");
        });
		// div(class("left"), () {view_layers(m);});
		// div(class("left"), onKeyDown(direction), () {
		// 	h3("Level");
        // div(class("simple"), () {view_level_simple(m);});
        div(class("middle"), onKeyDown(direction), () {
            div (class("grid"), () {view_level(m);});
            div(class("data"), () {
                div(class(""), () {view_panel(m);});
                div(class(""), () {view_options(m);});
                if (m.engine.level_data[m.engine.current_level.original].shortest_path != []) view_results(m);
            });
        });
        div(class("right"), () {
            div(class("tutomate"), () {

                h1(style(("text-shadow": "1px 1px 2px black", "padding-left": "1%")), "Tutomate");
                form("Hello");

            });
            // if (m.engine.level_data[m.engine.current_level.original].shortest_path != []) view_results(m);
        });
		// });
	});
    // div(class("footer"), () {
    //     h1(style(("text-shadow": "1px 1px 2px black", "padding-left": "1%")), "Tutomate");
    // });
}

void view_level_simple(Model m) {

	if (m.engine.current_level is message){
		p("#####################################################");
		p(m.engine.current_level.msg);
		p("#####################################################");
	} else {
        tuple[int width, int height] level_size = m.engine.level_data[m.engine.current_level.original].size;
        // println(level_size);
        for (int i <- [0..level_size.height]) {

            list[str] line = [];

            for (int j <- [0..level_size.width]) {

                if (m.engine.current_level.objects[<i,j>]?) {
                    list[Object] objects = m.engine.current_level.objects[<i,j>];
                    
                    if (size(objects) > 1) line += objects[size(objects) - 1].char;
                    else if (size(objects) == 1) line += objects[0].char;
                }
                else line += ".";
            }

            p(intercalate("", line));
            line = [];
        }
        p("");
    }

}



void view_level(Model m) {
	if (m.engine.current_level is message){
		p("#####################################################");
		p(m.engine.current_level.msg);
		p("#####################################################");
	} else {
		// list[Layer] layers = m.engine.current_level.layers;
		// view_background(m);

        println("Resolving sprites");

        tuple[int width, int height] level_size = m.engine.level_data[m.engine.current_level.original].size;

        for (int i <- [0..level_size.height]) {

            div(class("row"), () {
            for (int j <- [0..level_size.width]) {

                if (m.engine.current_level.objects[<i,j>]?) {
                    Object obj;
                    if (size(m.engine.current_level.objects[<i,j>]) > 0) {
                        obj = m.engine.current_level.objects[<i,j>][size(m.engine.current_level.objects[<i,j>]) - 1];
                    } else {
                        div(class("transparent"), class("cell"), () {view_sprite(m, "transparent");});
                        continue;
                    }
                    div(class(obj.current_name), class("cell"), () {view_sprite(m, obj.current_name);});
                }
                else {
                    div(class("transparent"), class("cell"), () {view_sprite(m, "transparent");});
                }

            }
            ;});
        }

        println("Done");

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

default void view_sprite(Model m, str name){

    // if (!m.engine.objects[name]?) return;
	ObjectData obj = m.engine.objects[name];
	// table(class("sprite"), class("cell"), () {

    // real before = cpuTime() / 1000000000.00;

	div(class("sprite"), () {
		for (int i <- [0..5]){
			div(class("divflex"), (){
				for (int j <- [0..5]){
					if(isEmpty(obj.sprite)){
						div(class("pixel"), class(toLowerCase(obj.colors[0])));
					} else {
						Pixel pix = obj.sprite[i][j];
						if (pix.pixel == "."){
							div(class("pixel"), class("transparent"));
						} else {
                            // println(pix.color[0]);
                            div(class("pixel"), style(("background-color": pix.color)));
							// else div(class("pixel"), class(toLowerCase(obj.colors[toInt(pix.pixel)])));
						}
					}
					
				}
			});
		}
	});

    // println((cpuTime() - before) / 1000000000.00);
}

void view_sprite(Model m, str _ : "transparent"){
	div(class("sprite"), () {
		for (int _ <- [0..5]){
			div(class("divflex"), (){
				for (int _ <- [0..5]){
					div(class("pixel"), class("transparent"));
				}
			});
		}
	});
}



App[Model]() main() {

    // loc game_loc = |project://automatedpuzzlescript/bin/PuzzleScript/Test/demo/limerick.PS|;
	// game = load(|project://automatedpuzzlescript/bin/PuzzleScript/Test/Tutorials/coincounter.PS|);
	// loc game_loc = |project://automatedpuzzlescript/bin/PuzzleScript/Test/Tutorials/push.PS|;
	loc game_loc = |project://automatedpuzzlescript/bin/PuzzleScript/Test/demo/blockfaker.PS|;
    // loc game_loc = |project://automatedpuzzlescript/bin/PuzzleScript/Test/demo/sokoban_basic.PS|;
	game = load(game_loc);
	// game = load(|project://automatedpuzzlescript/bin/PuzzleScript/Test/demo/byyourside.PS|);

	checker = check_game(game);
	engine = compile(checker);

	str title = get_prelude(engine.game.prelude, "title", "Unknown");

	Model init() = <"none", title, engine, checker, 0, readFile(game_loc)>;
    SalixApp[Model] counterApp(str id = "root") = makeApp(id, init, withIndex("Test", id, view, css = ["PuzzleScript/Interface/style.css"]), update);
    // SalixApp[Model] counterApp(str id = "root") = makeApp(id, init, withIndex("Test", id, view), update);

    App[Model] counterWebApp()
    //   = webApp(counterApp(), |project://automatedpuzzlescript/src/PuzzleScript/Interface/index.html|, |project://automatedpuzzlescript/src|);
    //   = webApp(counterApp(), |project://automatedpuzzlescript/src/PuzzleScript/Interface/index.html|);
      = webApp(counterApp(), |project://automatedpuzzlescript/src/|);

    return counterWebApp;

}