module PuzzleScript::Interface::SalixTest

import salix::HTML;
import salix::Core;
import salix::App;
import salix::Index;
import salix::ace::Editor;

import util::Benchmark;
import util::ShellExec;
import lang::json::IO;

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

alias Model = tuple[str input, str title, Engine engine, Checker checker, int index, str code, int path_index];
// alias Model = tuple[str input, str title, Engine engine, Checker checker, int index, str code];

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
    | show(list[str] movements)
	;

tuple[str, str, str] coords_to_json(Engine engine, list[Coords] coords, int index) {

    tuple[int width, int height] level_size = engine.level_data[engine.current_level.original].size;

    println("a");
    str json = "[";

    for (Coords coord <- coords) {
        json += "{\"x\":<coord[1]>, \"y\":<coord[0]>},";
    }
    println("b");
    json = json[0..size(json) - 1];
    json += "]";

    println("c");
    return <json, "{\"width\": <level_size.width>, \"height\": <level_size.height>}", "{\"index\": <index>}">;

}

tuple[str,str,str] pixel_to_json(Engine engine, int index) {

    tuple[int width, int height] level_size = engine.level_data[engine.current_level.original].size;

    str json = "[";

    for (int i <- [0..level_size.height]) {

        for (int j <- [0..level_size.width]) {

            if (!(engine.current_level.objects[<i,j>])? || isEmpty(engine.current_level.objects[<i,j>])) {
                continue;
            }

            list[Object] objects = engine.current_level.objects[<i,j>];

            str name = objects[size(objects) - 1].current_name;
            ObjectData obj = engine.objects[name];

            for (int k <- [0..5]) {
                for (int l <- [0..5]) {

                    json += "{";
                    json += "\"x\": <j * 5 + l>,";
                    json += "\"y\": <i * 5 + k>,";
                    if(isEmpty(obj.sprite)) json += "\"c\": \"<COLORS[toLowerCase(obj.colors[0])]>\"";
                    else {
                        Pixel pix = obj.sprite[k][l];
                        if (COLORS[pix.color]?) json += "\"c\": \"<COLORS[pix.color]>\"";
						else if (pix.pixel != ".") json += "\"c\": \"<pix.color>\"";
                        else json += "\"c\": \"#FFFFFF\"";
                    }
                    json += "},";
                }
            }
        }
    }
    json = json[0..size(json) - 1];
    json += "]";

    return <json, "{\"width\": <level_size.width>, \"height\": <level_size.height>}", "{\"index\": <index>}">;

}


Model update(Msg msg, Model model){

    bool execute = false;

	if (model.engine.current_level is level){
		switch(msg){
			case direction(int i): {
                execute = true;
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
                list[str] winning_moves = ["up","up","up","down"];
                model.engine.level_data[model.engine.current_level.original].shortest_path = winning_moves;
                model.engine.level_data[model.engine.current_level.original].dead_ends = [winning_moves];
                // model.engine.level_data[model.engine.current_level.original].dead_ends = get_dead_ends(model.engine, model.checker, winning_moves);
                
                
                // model.engine.level_data[model.engine.current_level.original].shortest_path = bfs(model.engine, ["up","down","left","right"], model.checker, "win");
            }
            case show(list[str] movements): {
                list[Coords] coords = [model.engine.current_level.player[0]];
                for (int i <- [0..size(movements)]) {
                    model.engine = execute_move(model.engine, model.checker, movements[i]);
                    coords += [model.engine.current_level.player[0]];
                }

                tuple[str, str, str] json_data = coords_to_json(model.engine, coords, model.index);
                exec("./dead_end.sh", workingDir=|project://automatedpuzzlescript/src/PuzzleScript/Interface/|, args = [json_data[0], json_data[1], json_data[2]]);

            }
			default: return model;
		}
		
        if (execute) {
            model.index += 1;
            println(model.input);
            model.engine = execute_move(model.engine, model.checker, model.input);
            tuple[str, str, str] json_data = pixel_to_json(model.engine, model.index);
            exec("./image.sh", workingDir=|project://automatedpuzzlescript/src/PuzzleScript/Interface/|, args = [json_data[0], json_data[1], json_data[2]]);
            execute = false;
        }
	}

    return model;
}

// void show_moves(list[str] movements, Model model) {

//     list[Msg] messages = [];

//     for (str move <- movements) {
//         switch(move) {
//             case "left": direction(37);
//             case "up": direction(38);
//             case "right": direction(39);
//             case "down": direction(40);
//             default: println("None found");
//         }
//     }


// }

Model reload(str src) {

	PSGame game = load(src);
	Checker checker = check_game(game);
	Engine engine = compile(checker);

	str title = get_prelude(engine.game.prelude, "title", "Unknown");
 
	Model init() = <"none", title, engine, checker, 0, src, 0>;
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
        LevelChecker lc = m.engine.level_data[m.engine.current_level.original];
        p("Dead ends = <size(lc.shortest_path)> steps");
        p("Shortest path = <size(lc.shortest_path)> steps");
        for (int i <- [0..size(lc.dead_ends)]) {
            p(onMouseEnter(show(lc.dead_ends[i])), "<i>");
        }
        // button(onClick(show(m.engine.level_data[m.engine.current_level.original].shortest_path, 1)), "Next move");
        // button(onClick(show(m.engine.level_data[m.engine.current_level.original].shortest_path, -1)), "Previous move");

    });
}

void view(Model m) {

    div(class("header"), () {
        h1(style(("text-shadow": "1px 1px 2px black", "font-family": "Pixel", "font-size": "50px")), "PuzzleScript");
    });

    div(class("main"), () {

        div(class("left"), () {
            // ace("myAce", event=onAceChange(editorChange), code = m.code);
            div(class("left_top"), () {
                h1(style(("text-shadow": "1px 1px 2px black", "padding-left": "1%", "text-align": "center", "font-family": "BubbleGum")), "Editor"); 
                ace("myAce", code = m.code);
                button(onClick(load_design()), "reload");
            });
            div(class("left_bottom"), () {
                div(class("tutomate"), () {
                    h1(style(("text-shadow": "1px 1px 2px black", "padding-left": "1%", "text-align": "center", "font-family": "BubbleGum")), "Tutomate");
                    textarea(class("textfield"), "Hello");
                });
            });
        });
        div(class("right"), onKeyDown(direction), () {
            div(style(("width": "40vw", "height": "40vh")), onKeyDown(direction), () {
                img(style(("width": "40vw", "height": "40vh", "image-rendering": "pixelated")), (src("PuzzleScript/Interface/output_image<m.index>.png")), () {});
            });
            div(class("data"), () {
                div(class(""), () {view_panel(m);});
                div(class(""), () {view_options(m);});
                if (m.engine.level_data[m.engine.current_level.original].shortest_path != []) view_results(m);
            });
        });
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

    println("Current level");

    tuple[str, str, str] json_data = pixel_to_json(engine, 0);
    exec("./image.sh", workingDir=|project://automatedpuzzlescript/src/PuzzleScript/Interface/|, args = [json_data[0], json_data[1], json_data[2]]);

	Model init() = <"none", title, engine, checker, 0, readFile(game_loc), 0>;
    SalixApp[Model] counterApp(str id = "root") = makeApp(id, init, withIndex("Test", id, view, css = ["PuzzleScript/Interface/style.css"]), update);
    // SalixApp[Model] counterApp(str id = "root") = makeApp(id, init, withIndex("Test", id, view), update);

    App[Model] counterWebApp()
    //   = webApp(counterApp(), |project://automatedpuzzlescript/src/PuzzleScript/Interface/index.html|, |project://automatedpuzzlescript/src|);
    //   = webApp(counterApp(), |project://automatedpuzzlescript/src/PuzzleScript/Interface/index.html|);
      = webApp(counterApp(), |project://automatedpuzzlescript/src/|);

    return counterWebApp;

}