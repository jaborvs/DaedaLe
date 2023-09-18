module PuzzleScript::Interface::GUI

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
import PuzzleScript::Verbs;
import PuzzleScript::DynamicAnalyser;
import PuzzleScript::Test::Domain;

import String;
import List;
import Type;
import Set;
import IO;

public int i = 0;

data CurrentLine = currentline(int column, int row);
data JsonData = alldata(CurrentLine \start, str action, list[str] lines, CurrentLine end, int id);

alias Model = tuple[str input, str title, Engine engine, Checker checker, int index, int begin_index, str code, str dsl, bool analyzed, Dead_Ends de, Win win, str image];
alias Dead_Ends = list[tuple[Engine, list[str]]];
alias Win = tuple[Engine engine, list[str] winning_moves];

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
    | show(Engine engine, int win)
	;

tuple[str, str] coords_to_json(Engine engine, list[Coords] coords, int index) {

    tuple[int width, int height] level_size = engine.level_data[engine.current_level.original].size;

    str json = "[";

    for (Coords coord <- coords) {
        json += "{\"x\":<coord[1]>, \"y\":<coord[0]>},";
    }
    json = json[0..size(json) - 1];
    json += "]";

    return <json, "{\"index\": <index>}">;

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

int get_level_index(Engine engine, Level current_level) {

    println("1111");

    int index = 0;
    while (engine.converted_levels[index].original != current_level.original) {
        println(index);
        index += 1;
    }
    return index;

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
			case reload(): {
                model.engine.current_level = model.engine.begin_level;
                model.image = "PuzzleScript/Interface/output_image0.png";
            }
            case codeChange(map[str,value] delta): {
                JsonData json_change = parseJSON(#JsonData, asJSON(delta["payload"]));
                model = update_code(model, json_change, 0);
            }
            case dslChange(map[str,value] delta): {
                JsonData json_change = parseJSON(#JsonData, asJSON(delta["payload"]));
                model = update_code(model, json_change, 1);
            }
            case load_design(): {
                model.index += 1;
                model = reload(model.code, model.index);
                tuple[str, str, str] json_data = pixel_to_json(model.engine, model.index);
                exec("./image.sh", workingDir=|project://automatedpuzzlescript/src/PuzzleScript/Interface/|, args = [json_data[0], json_data[1], json_data[2], "0"]);
            }
            case analyse(): {
                tuple[Engine engine, list[str] winning_moves] result = bfs(model.engine, ["up","down","left","right"], model.checker, "win", 1);
                model.engine.applied_data[model.engine.current_level.original].shortest_path = result.winning_moves;
                
                // Save respective engine states
                model.win = result;
                model.de = get_dead_ends(model.engine, model.checker, result.winning_moves);

                model.analyzed = true;
            }
            case show(Engine engine, int win): {
                // Get travelled coordinates and generate image that shows coordinates
                // 'win' argument determines the color of the path

                println("0.00");
                list[Coords] coords = engine.applied_data[engine.current_level.original].travelled_coords;
                tuple[str, str, str] json_data = pixel_to_json(engine, model.index + 1);
                println("0.0");
                exec("./image.sh", workingDir=|project://automatedpuzzlescript/src/PuzzleScript/Interface/|, args = [json_data[0], json_data[1], json_data[2], "1"]);
                tuple[str, str] new_json_data = coords_to_json(engine, coords, model.index + 1);
                println("0.1");
                exec("./path.sh", workingDir=|project://automatedpuzzlescript/src/PuzzleScript/Interface/|, args = [new_json_data[0], win == 0 ? "0" : "1", new_json_data[1]]);
                model.index += 1;
                model.image = "PuzzleScript/Interface/path<model.index>.png";

                println("0.2");

                int level_index = get_level_index(engine, engine.current_level);

                println("\n\n0");
                map[int,list[RuleData]] rules = engine.applied_data[engine.current_level.original].actual_applied_rules;
                println("1");
                Tutorial tutorial = tutorial_build(model.dsl);
                println("2");
                resolve_verbs(engine, rules<1>, tutorial.lessons[level_index].verbs, tutorial.lessons[level_index].elems, win);
                println("3");

            }
			default: return model;
		}
		
        if (execute) {
            model.index += 1;
            model.engine = execute_move(model.engine, model.checker, model.input, 0);
            if (check_conditions(model.engine, "win")) {
                model.engine.index += 1;
                model.engine.current_level = model.engine.converted_levels[model.engine.index];
            }
            tuple[str, str, str] json_data = pixel_to_json(model.engine, model.index);
            exec("./image.sh", workingDir=|project://automatedpuzzlescript/src/PuzzleScript/Interface/|, args = [json_data[0], json_data[1], json_data[2], "1"]);
            execute = false;
            model.image = "PuzzleScript/Interface/output_image<model.index>.png";
        }
	}

    return model;
}

Model update_code(Model model, JsonData jd, int category) {

    str code = category == 0 ? model.code : model.dsl;
    list[str] code_lines = split("\n", code);
    str new_line = "";

    int row = jd.\start.row;
    int begin = jd.\start.column;
    int end = jd.end.column;

    switch(jd.action) {
        case "remove": {
            new_line = code_lines[row][0..begin] + code_lines[row][end..];
        }
        case "insert": {
            new_line = code_lines[row][0..begin] + intercalate("", jd.lines) + code_lines[row][begin..];
        }
    }
    code_lines[jd.\start.row] = new_line;
    str new_code = intercalate("\n", code_lines);
    
    if (category == 0) model.code = new_code;
    else model.dsl = new_code;

    println(model.dsl);

    return model;
}

Model reload(str src, int index) {

	PSGame game = load(src);
	Checker checker = check_game(game);
	Engine engine = compile(checker);

	str title = get_prelude(engine.game.prelude, "title", "Unknown");
 
	Model init() = <"none", title, engine, checker, index, index, src, "", false, [], <engine,[]>, "PuzzleScript/Interface/output_image<index>.png">;
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

void view_results(Model m) {

    println("Showing results");

    div(class("panel"), () {
        h3("Results");
        AppliedData ad = m.engine.applied_data[m.engine.current_level.original];
        p("-- Shortest path --");
        button(onClick(show(m.win.engine, 1)), "<size(m.win.winning_moves)> steps");
        p("-- Dead ends --");
        for (int i <- [0..size(m.de)]) {
            button(onClick(show(m.de[i][0], 0)), "<i + 1>");
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
                img(style(("width": "40vw", "height": "40vh", "image-rendering": "pixelated")), (src("<m.image>")), () {});
            });
            div(class("data"), () {
                div(class(""), () {view_panel(m);});
                if (m.analyzed) view_results(m);
            });
        });
    });
}

App[Model]() main() {

    loc game_loc = |project://automatedpuzzlescript/bin/PuzzleScript/Test/demo/limerick.PS|;
	game = load(game_loc);

	checker = check_game(game);
	engine = compile(checker);

	str title = get_prelude(engine.game.prelude, "title", "Unknown");

    tuple[str, str, str] json_data = pixel_to_json(engine, 0);
    exec("./image.sh", workingDir=|project://automatedpuzzlescript/src/PuzzleScript/Interface/|, args = [json_data[0], json_data[1], json_data[2], "1"]);

	Model init() = <"none", title, engine, checker, 0, 0, readFile(game_loc), "", false, [], <engine,[]>, "PuzzleScript/Interface/output_image0.png">;
    SalixApp[Model] counterApp(str id = "root") = makeApp(id, init, withIndex("Test", id, view, css = ["PuzzleScript/Interface/style.css"]), update);

    App[Model] counterWebApp()
      = webApp(counterApp(), |project://automatedpuzzlescript/src/|);

    return counterWebApp;

}