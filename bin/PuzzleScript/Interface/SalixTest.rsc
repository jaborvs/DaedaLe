module PuzzleScript::Interface::SalixTest

import salix::HTML;
import salix::Core;
import salix::App;
import salix::Index;
import salix::ace::Editor;
import salix::Node;

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

data CurrentLine = currentline(int column, int row);
data JsonData = alldata(CurrentLine \start, str action, list[str] lines, CurrentLine end, int id);

alias Model = tuple[str input, str title, Engine engine, Checker checker, int index, int begin_index, str code, str dsl, bool analyzed];
// alias Model = tuple[str input, str title, Engine engine, Checker checker, int index, str code];

data Msg 
	= left() 
	| right() 
	| up() 
	| down() 
	| action() 
	| undo() 
	| reload()
	| win()
	| direction(int i)
    | codeChange(map[str,value] delta)
    | dslChange(map[str,value] delta)
    | textUpdated()
    | load_design()
    | analyse()
    | show(list[str] movements)
	;

tuple[str, str, str] coords_to_json(Engine engine, list[Coords] coords, int index) {

    tuple[int width, int height] level_size = engine.level_data[engine.current_level.original].size;

    str json = "[";

    for (Coords coord <- coords) {
        json += "{\"x\":<coord[1]>, \"y\":<coord[0]>},";
    }
    json = json[0..size(json) - 1];
    json += "]";

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
			case reload(): model.engine.current_level = model.engine.begin_level;
            case codeChange(map[str,value] delta): {
                JsonData json_change = parseJSON(#JsonData, asJSON(delta["payload"]));
                println("Hoooi1");
                model = update_code(model, json_change, 0);
            }
            case dslChange(map[str,value] delta): {
                println("Hoooi2");
                println(asJSON(delta["payload"]));
                JsonData json_change = parseJSON(#JsonData, asJSON(delta["payload"]));
                println(json_change);
                model = update_code(model, json_change, 1);
            }
            case load_design(): {
                model.index += 1;
                model = reload(model.code, model.index);
                tuple[str, str, str] json_data = pixel_to_json(model.engine, model.index);
                exec("./image.sh", workingDir=|project://automatedpuzzlescript/src/PuzzleScript/Interface/|, args = [json_data[0], json_data[1], json_data[2], "0"]);
            }
            case analyse(): {
                model.analyzed = true;
                println(model.dsl);
                // list[str] winning_moves = bfs(model.engine, ["up","down","left","right"], model.checker, "win");
                // model.engine.level_data[model.engine.current_level.original].shortest_path = winning_moves;
                // model.engine.level_data[model.engine.current_level.original].dead_ends = get_dead_ends(model.engine, model.checker, winning_moves);
            }
            case show(list[str] movements): {
                exec("./dead_end.sh", workingDir=|project://automatedpuzzlescript/src/PuzzleScript/Interface/|, args = [json_data[0], json_data[1], json_data[2], "0"]);
            }
			default: return model;
		}
		
        if (execute) {
            model.index += 1;
            println(model.input);
            model.engine = execute_move(model.engine, model.checker, model.input);
            tuple[str, str, str] json_data = pixel_to_json(model.engine, model.index);
            exec("./image.sh", workingDir=|project://automatedpuzzlescript/src/PuzzleScript/Interface/|, args = [json_data[0], json_data[1], json_data[2], "1"]);
            execute = false;
        }
	}

    return model;
}

Model update_code(Model model, JsonData oink, int category) {

    str code = category == 0 ? model.code : model.dsl;
    list[str] code_lines = split("\n", code);
    str new_line = "";

    int row = oink.\start.row;
    int begin = oink.\start.column;
    int end = oink.end.column;

    switch(oink.action) {
        case "remove": {
            new_line = code_lines[row][0..begin] + code_lines[row][end..];
        }
        case "insert": {
            println(code_lines[row][0..begin]);
            println(code_lines[row][begin..]);
            new_line = code_lines[row][0..begin] + intercalate("", oink.lines) + code_lines[row][begin..];
        }
    }
    code_lines[oink.\start.row] = new_line;
    str new_code = intercalate("\n", code_lines);
    
    if (category == 0) model.code = new_code;
    else model.dsl = new_code;

    println(new_line);

    return model;
}

Model reload(str src, int index) {

	PSGame game = load(src);
	Checker checker = check_game(game);
	Engine engine = compile(checker);

	str title = get_prelude(engine.game.prelude, "title", "Unknown");
 
	Model init() = <"none", title, engine, checker, index, index, src, "", false>;
    return init();

}

void view_panel(Model m){
    div(class("panel"), () {
        h3(style(("font-family": "BubbleGum")), "Buttons");
        button(onClick(direction(37)), "Left");
        button(onClick(direction(39)), "Right");
        button(onClick(direction(38)), "Up");
        button(onClick(direction(40)), "Down");
        button(onClick(reload()), "Restart");
    });
}

// void view_options(Model m){
//     div(class("panel"), () {
//         h3(style(("font-family": "BubbleGum")), "Get insights");
//         button(onClick(analyse()), "Analyse");
//     });
// }

void view_results(Model m) {
    div(class("panel"), () {
        h3("Results");
        LevelChecker lc = m.engine.level_data[m.engine.current_level.original];
        p("DSL = <m.dsl>");
        p("Shortest path = <size(lc.shortest_path)> steps");
        for (int i <- [0..size(lc.dead_ends)]) {
            p(onMouseEnter(show(lc.dead_ends[i])), "<i>");
        }
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
                ace("myAce", event=onAceChange(codeChange), code = m.code);
                button(onClick(load_design()), "Reload");
            });
            div(class("left_bottom"), () {
                div(class("tutomate"), () {
                    h1(style(("text-shadow": "1px 1px 2px black", "padding-left": "1%", "text-align": "center", "font-family": "BubbleGum")), "Tutomate");
                    ace("tutomate", event=onAceChange(dslChange), code = m.dsl, width="100%", height="15%");
                    div(class("panel"), () {
                        h3(style(("font-family": "BubbleGum")), "Get insights");
                        button(onClick(analyse()), "Analyse");
                    });
                });
            });
        });
        div(class("right"), onKeyDown(direction), () {
            div(style(("width": "40vw", "height": "40vh")), onKeyDown(direction), () {
                int index = 0;
                index = (m.index == m.begin_index) ? m.begin_index : m.index;
                img(style(("width": "40vw", "height": "40vh", "image-rendering": "pixelated")), (src("PuzzleScript/Interface/output_image<index>.png")), () {});
            });
            div(class("data"), () {
                div(class(""), () {view_panel(m);});
                // div(class(""), () {view_options(m);});
                if (m.analyzed) view_results(m);
            });
        });
    });
}

App[Model]() main() {

    loc game_loc = |project://automatedpuzzlescript/bin/PuzzleScript/Test/demo/limerick.PS|;
	// game = load(|project://automatedpuzzlescript/bin/PuzzleScript/Test/Tutorials/coincounter.PS|);
	// loc game_loc = |project://automatedpuzzlescript/bin/PuzzleScript/Test/Tutorials/push.PS|;
	// loc game_loc = |project://automatedpuzzlescript/bin/PuzzleScript/Test/demo/blockfaker.PS|;
    // loc game_loc = |project://automatedpuzzlescript/bin/PuzzleScript/Test/demo/sokoban_basic.PS|;
	game = load(game_loc);
	// game = load(|project://automatedpuzzlescript/bin/PuzzleScript/Test/demo/byyourside.PS|);

	checker = check_game(game);
	engine = compile(checker);

	str title = get_prelude(engine.game.prelude, "title", "Unknown");

    tuple[str, str, str] json_data = pixel_to_json(engine, 0);
    exec("./image.sh", workingDir=|project://automatedpuzzlescript/src/PuzzleScript/Interface/|, args = [json_data[0], json_data[1], json_data[2], "1"]);

	Model init() = <"none", title, engine, checker, 0, 0, readFile(game_loc), "", false>;
    SalixApp[Model] counterApp(str id = "root") = makeApp(id, init, withIndex("Test", id, view, css = ["PuzzleScript/Interface/style.css"]), update);
    // SalixApp[Model] counterApp(str id = "root") = makeApp(id, init, withIndex("Test", id, view), update);

    App[Model] counterWebApp()
    //   = webApp(counterApp(), |project://automatedpuzzlescript/src/PuzzleScript/Interface/index.html|, |project://automatedpuzzlescript/src|);
    //   = webApp(counterApp(), |project://automatedpuzzlescript/src/PuzzleScript/Interface/index.html|);
      = webApp(counterApp(), |project://automatedpuzzlescript/src/|);

    return counterWebApp;

}