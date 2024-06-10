/*
 * @Module: GUI
 * @Desc:   Module that contains de GUI code for the generation tool.
 * @Auth:   Dennis Vet    -> code
 *          Borja Velasco -> code, comments
 */
module PuzzleScript::Interface::GUI

/*****************************************************************************/
// --- General modules imports ------------------------------------------------
import salix::HTML;
import salix::Core;
import salix::App;
import salix::Index;
import salix::ace::Editor;
import salix::Node;

import util::Benchmark;
import util::ShellExec;
import lang::json::IO;

import String;
import List;
import Type;
import Set;
import IO;

// --- Own modules imports ----------------------------------------------------
// import PuzzleScript::Utils;
// import PuzzleScript::AST;
// import PuzzleScript::Load;
// import PuzzleScript::Compiler;
// import PuzzleScript::DynamicAnalyser;
// import PuzzleScript::Verbs;

import PuzzleScript::Utils;
import PuzzleScript::AST;
import PuzzleScript::Load;
import PuzzleScript::Compiler;
import PuzzleScript::Engine;
import PuzzleScript::Tutorials::AST;

/******************************************************************************/
// --- Global defines ----------------------------------------------------------
str limerick_dsl = "tutorial limerick {
    verb topclimb [0]
    verb largeclimb [1]
    verb mediumclimb [2]
    verb normalclimb [3]
    verb push [4]
    verb crawl [5]
    verb eat [6]
    verb eat2 [7]
    verb cancel [8]
    verb snakefall [9]

    lesson 1: Lesson {
        \"In this lesson, the player learns that the snake is able to crawl and climb\"
        learn to crawl
        learn to normalclimb
        learn to mediumclimb
    }
    lesson 2: Lesson {
        \"This lesson teaches that a snake can stack its body on top of each other to reach the goal\"
        learn to crawl
        learn to normalclimb
        learn to mediumclimb
        learn to largeclimb
    }
    lesson 3: Lesson {
        \"This lesson teaches that falling in a gap results in a dead−end\"
        learn to crawl
        learn to normalclimb
        learn to mediumclimb
        learn to largeclimb
        fail if snakefall
    }
    lesson 4: Lesson {
        \"This lessons teaches the player that it can use its own body multiple times to reach great heights\"
        learn to crawl
        learn to normalclimb
        learn to mediumclimb
        learn to largeclimb
    }
    lesson 5: Lesson {
        \"This lesson teaches players that the player can push blocks to fill the gaps\"
        fail if snakefall
        learn to crawl
        learn to normalclimb
        learn to mediumclimb
        learn to largeclimb
    }
    lesson 6: Lesson {
        \"This lesson uses all mechanics combined\"
        learn to crawl
        learn to normalclimb
        learn to mediumclimb
        learn to largeclimb
    }
}";

str blockfaker_dsl = "tutorial blockfaker {
    verb walk []
    verb push [0]
    verb collide [1]
    verb vanishpink [2]
    verb vanishblue [3]
    verb vanishpurple [4]
    verb vanishorange [5]
    verb vanishgreen [6]

    lesson 1: Push {
        \"First, the player is taught how to push a block\"
        learn to push
    }
    
    lesson 2: Vanish {
        \"By using the push mechanic, the player moves blocks to make other blocks vanish\"
        learn to push
        learn to vanishpurple
        learn to vanishorange
    }
    
    lesson 3: Obstacle {
        \"Here a dead end is introduced. If the player vanishes the purple blocks too early, the level can not be completed\"
        learn to push
        learn to vanishpurple
        fail if vanishpink
    }
    lesson 4: Combinations {
        \"Different techniques should be applied to complete the level\"
        learn to push
        learn to vanishgreen
        learn to vanishorange
    }
    lesson 5: Moveables {
        \"This level uses all the moveable objects\"
        learn to push
        learn to vanishpink
        learn to vanishpurple
        learn to vanishorange
        learn to vanishblue
        learn to vanishgreen
    }        
}";

/*****************************************************************************/
// --- Data Structures defines ------------------------------------------------

/*
 *  @Name:  CurrentLine
 *  @Desc:  Current line data structure
 */
data CurrentLine = currentline(
    int column,                                             // Column no.
    int row                                                 // Row no.
    );

/*
 *  @Name:  JsonData (???)
 *  @Desc:  JSON data structure
 */
data JsonData = alldata(
    CurrentLine \start,                                     // Start position 
    str action,                                             // Action 
    list[str] lines,                                        // Lines
    CurrentLine end,                                        // End position
    int id                                                  // Identifier
    );

/*
 *  @Name:  Model
 *  @Desc:  Aplication Model data structure
 */
alias Model = tuple[ 
    str input,                                              // Input
    str title,                                              // Title
    Engine engine,                                          // Engine
    int index,                                              // Index (???)
    int begin_index,                                        // Begin index (???)
    str code,                                               // PuzzleScript code
    str dsl,                                                // DSL code
    bool analyzed,                                          // Analyzed boolean (???)
    Dead_Ends de,                                           // Level dead ends (???)
    Win win,                                                // Win (???)
    str image,                                              // Level image (???)
    tuple[list[str],list[str],list[str]] learning_goals     // Learning goals (???)
    ];

/*
 *  @Name:  Dead_Ends
 *  @Desc:  Dead ends data structure
 */
alias Dead_Ends = tuple[ 
    list[
        tuple[Engine engine,                                // Engine
        list[str] loosing_moves]                            // Loosing moves
        ] loosing_moves_list,                               // Loosing moves list
    real time                                               // Execution time (???)
    ];

/*
 *  @Name:  Win
 *  @Desc:  Win data structure
 */
alias Win = tuple[
    Engine engine,                                          // Engine (???)
    list[str] winning_moves,                                // Winning moves
    real time                                               // Execution time (???)
    ];

/*
 *  @Name:  Msg
 *  @Desc:  Message function
 */
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
    | analyse_all()
    | show(Engine engine, int win, int length)
    ;

/*****************************************************************************/
// --- Backend Functions ------------------------------------------------------

/*
 *  @Name:  coords_to_json
 *  @Desc:  Converts the coordinates to JSON format for the level GUI representation
 *  @Param:
 *      engine  Engine of the application
 *      coords  Coordinates to converted
 *      index   Index (???)
 *  @Ret:   Tuple containing the coordinates in json and the index in json
 */
tuple[str, str] coords_to_json(Engine engine, list[Coords] coords, int index) {
    tuple[int width, int height] level_size = engine.level_checkers[engine.current_level.original].size;
    str json = "[";

    for (Coords coord <- coords) {
        json += "{\"x\":<coord[1]>, \"y\":<coord[0]>},";
    }
    json = json[0..size(json) - 1];
    json += "]";

    return <json, "{\"index\": <index>}">;

}

/*
 *  @Name:  pixel_to_json
 *  @Desc:  Converts a pixel to JSON format for the level GUI representation
 *  @Param:
 *      engine  Engine of the application
 *      index   Index (???)
 *  @Ret:   Tuple containing the coordinates in json, the level size in json 
 *          and the index in json
 */
tuple[str,str,str] pixel_to_json(Engine engine, int index) {
    tuple[int width, int height] level_size = engine.level_checkers[engine.current_level.original].size;
    str json = "[";
    tmp = 0;

    for (int i <- [0..level_size.height]) {
        for (int j <- [0..level_size.width]) {
            if (!(engine.current_level.objects[<i,j>])? || isEmpty(engine.current_level.objects[<i,j>])) {
                continue;
            }

            list[Object] objects = engine.current_level.objects[<i,j>];

            // str name = objects[size(objects) - 1].current_name;
            // ObjectData obj = engine.objects[name];

            several = false;
            if (size(objects) > 1) several = true;

            for (Object my_obj <- objects) {
                str name = my_obj.current_name;
                ObjectData obj = engine.objects[name];

                for (int k <- [0..5]) {
                    for (int l <- [0..5]) {
                        json += "{";
                        json += "\"x\": <j * 5 + l>,";
                        json += "\"y\": <i * 5 + k>,";

                        if(isEmpty(obj.sprite)) {
                            json += "\"c\": \"<COLORS[toLowerCase(obj.colors[0])]>\"";
                        }
                        else {
                            Pixel pix = obj.sprite[k][l];
                            if (pix.color_number == ".") {
                                json += "\"c\": \"......\"";
                            }
                            else if (COLORS[obj.colors[toInt(pix.color_number)]]?) {
                                json += "\"c\": \"<COLORS[obj.colors[toInt(pix.color_number)]]>\"";
                            }
                            // else if (COLORS[pix.color]?) {
                            //     json += "\"c\": \"<COLORS[pix.color]>\"";
                            // }
                            // // I think this never runs (???)
                            // else if (pix.color_number != ".") {
                            //     json += "\"c\": \"<pix.color>\"";
                            // }
                            else {
                                json += "\"c\": \"#FFFFFF\"";
                            }
                        }
                        json += "},";
                    }
                }
            }
        }
    }

    json = json[0..size(json) - 1];
    json += "]";

    return <json, "{\"width\": <level_size.width>, \"height\": <level_size.height>}", "{\"index\": <index>}">;

}

/*
 *  @Name:  get_level_index
 *  @Desc:  Gets the index of the current represented level
 *  @Param:
 *      engine          Engine of the application
 *      current_level   Current represented level
 *  @Ret:   Index of the level (???)
 */
int get_level_index(Engine engine, Level current_level) {
    int index = 0;

    while (engine.levels[index].original != current_level.original) {
        index += 1;
    }

    return index + 1;
}

/*
 *  @Name:  extract_goals
 *  @Desc:  Gets the goals of the current level after it has been solved
 *  @Param:
 *      engine          Engine of the application
 *      win             Boolean that determines the color of the path (1: victory green, 0: defeat red)
 *      length          (???)
 *      model           Application model
 *  @Ret:   Updated model of the application (???)
 */
Model extract_goals(Engine engine, int win, int length, Model model) {
    int level_index = get_level_index(engine, engine.current_level);
    Tutorial tutorial = tutorial_build(model.dsl);
    Lesson lesson = any(Lesson lesson <- tutorial.lessons, lesson.number == level_index) ? lesson : tutorial.lessons[level_index];

    if (!(any(Lesson lesson <- tutorial.lessons, lesson.number == level_index))) {
        return model;
    }
    
    // Get travelled coordinates and generate image that shows coordinates
    // 'win' argument determines the color of the path
    list[Coords] coords = engine.level_applied_data[engine.current_level.original].travelled_coords;
    tuple[str, str, str] json_data = pixel_to_json(engine, model.index + 1);

    data_loc = |project://DaedaLe/src/PuzzleScript/Interface/bin/data.dat|;
    writeFile(data_loc, json_data[0]);
    exec("python3", workingDir=|project://DaedaLe/src/PuzzleScript/Interface/py|, args = ["ImageGenerator.py", resolveLocation(data_loc).path, json_data[1], json_data[2], "1"]);

    tuple[str, str] new_json_data = coords_to_json(engine, coords, model.index + 1);
    tmp = execWithCode("python3", workingDir=|project://DaedaLe/src/PuzzleScript/Interface/py|, args = ["PathGenerator.py", new_json_data[0], win == 0 ? "0" : "1", new_json_data[1]]);
    model.index += 1;
    model.image = "PuzzleScript/Interface/bin/path<model.index>.png";

    map[int,list[RuleData]] rules = engine.level_applied_data[engine.current_level.original].actual_applied_rules;

    model.learning_goals = resolve_verbs(engine, rules, tutorial.verbs, lesson.elems, length);

    return model;
}

/*
 *  @Name:  update
 *  @Desc:  Updates the current GUI representation
 *  @Param:
 *      engine          Engine of the application
 *      model           Application model
 *  @Ret:   Updated model of the application (???)
 */
Model update(Msg msg, Model model){
    bool execute = false;

    if (model.engine.current_level is game_level){
        switch(msg){
            // ''Direction' button has been pressed: LEFT, UP, RIGHT, DOWN
            case direction(int i): {                
                execute = true;
                switch(i){
                    case 37: model.input = "left";
                    case 38: model.input = "up";
                    case 39: model.input = "right";
                    case 40: model.input = "down";
                }
            }
            // 'Reload' button has been pressed
            case reload(): {                            
                model.engine.current_level = model.engine.first_level;
                model.image = "PuzzleScript/Interface/bin/output_image0.png";
            }
            // PuzzleScript code has been changed
            case codeChange(map[str,value] delta): {    
                JsonData json_change = parseJSON(#JsonData, asJSON(delta["payload"]));
                model = update_code(model, json_change, 0);
            }
            // DSL code has been changed
            case dslChange(map[str,value] delta): {
                JsonData json_change = parseJSON(#JsonData, asJSON(delta["payload"]));
                model = update_code(model, json_change, 1);
            }
            // Design has been loaded
            case load_design(): {
                model.index += 1;
                model = reload(model.code, model.index);
                tuple[str, str, str] json_data = pixel_to_json(model.engine, model.index);

                data_loc = |project://DaedaLe/src/PuzzleScript/Interface/bin/data.dat|;
                writeFile(data_loc, json_data[0]);
                exec("python3", workingDir=|project://DaedaLe/src/PuzzleScript/Interface/py|, args = ["ImageGenerator.py", resolveLocation(data_loc).path, json_data[1], json_data[2], "1"]);
            }
            // 'Analyse All' button has been pressed
            case analyse_all(): {
                int i = 0;
                for (Level level <- model.engine.levels) {
                    list[list[Model]] win_models = [];
                    list[Model] losing_models = [];
                    list[list[Model]] all_losing_models = [];

                    Model new_model = model;
                    new_model.engine.current_level = level; 

                    print_level(new_model.engine);                  

                    int before = cpuTime();
                    tuple[Engine engine, list[str] winning_moves] result = bfs(new_model.engine, ["up","down","left","right"], "win", 1);
                    real actual_time = (cpuTime() - before) / 1000000.00;
                    
                    tuple[Engine engine, list[str] winning_moves, real time] result_time = <result[0], result[1], actual_time>;
                    
                    new_model.engine.level_applied_data[model.engine.current_level.original].shortest_path = result.winning_moves;
                    
                    // Save respective engine states
                    new_model.win = result_time;
                    new_model = extract_goals(new_model.win.engine, 0, size(new_model.win.winning_moves), new_model);
                    win_models += [[new_model]];

                    // before = cpuTime();
                    // list[tuple[Engine, list[str]]] results = get_dead_ends(new_model.engine, result.winning_moves);
                    // actual_time = (cpuTime() - before) / 1000000.00;

                    // new_model.de = <results, actual_time>;

                    // for (tuple[Engine, list[str]] dead_ends <- new_model.de[0]) {
                    //     new_model = extract_goals(dead_ends[0], 0, size(dead_ends[1]), new_model);
                    //     losing_models += [new_model];
                    // }

                    // all_losing_models += [losing_models];

                    save_results(win_models, "win");
                    // save_results(all_losing_models, "fails");
                }
            }
            // 'Analyse' button has been pressed
            case analyse(): {
                int before = cpuTime();
                println("1");
                tuple[Engine engine, list[str] winning_moves] result = bfs(model.engine, ["up","down","left","right"], "win", 1);
                println("2");
                real actual_time = (cpuTime() - before) / 1000000.00;
                println("3");
                tuple[Engine engine, list[str] winning_moves, real time] result_time = <result[0], result[1], actual_time>;
                
                model.engine.level_applied_data[model.engine.current_level.original].shortest_path = result.winning_moves;
                
                // Save respective engine states
                model.win = result_time;
                // model.de = get_dead_ends(model.engine, result.winning_moves);     // Doesn't work (???)

                model.analyzed = true;
            }
            // Show has been called
            case show(Engine engine, int win, int length): {
                model = extract_goals(engine, win, length, model);
            }
            // Default case
            default: return model;
        }
        
        println("4");
        // In case we have done a manual move we update the index, check if we have won and update
        // the leve representation
        if (execute) {
            println("5");
            model.index += 1;
            model.engine = execute_move(model.engine, model.input, 0);
            println("6");
            if (check_conditions(model.engine, "win")) {
                model.engine.index += 1;
                model.engine.current_level = model.engine.levels[model.engine.index];
            }
            println("7");
            tuple[str, str, str] json_data = pixel_to_json(model.engine, model.index);
            println("8");
            data_loc = |project://DaedaLe/src/PuzzleScript/Interface/bin/data.dat|;
            writeFile(data_loc, json_data[0]);
            tmp = execWithCode("python3", workingDir=|project://DaedaLe/src/PuzzleScript/Interface/py|, args = ["ImageGenerator.py", resolveLocation(data_loc).path, json_data[1], json_data[2], "1"]);
            execute = false;
            model.image = "PuzzleScript/Interface/bin/output_image<model.index>.png";
        }
    }
    println("9");
    return model;
}

/*
 *  @Name:  update_code
 *  @Desc:  Notifies when PuzzleScript code or the DSL code has been changed
 *  @Param:
 *      model       Application model
 *      jd          PuzzleScript code
 *      category    Boolean that determines whether the PuzzleScript of DSL
*                   code has been changed
 *  @Ret:   Updated model of the application (???)
 */
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

    return model;
}

/*
 *  @Name:  reload
 *  @Desc:  Reloads the current PuzzleScript code
 *  @Param:
 *      src     Location of the game file
 *      index   Index (???)
 *  @Ret:   Default application model
 */
Model reload(str src, int index) {
    GameData game = load(src);
    Engine engine = compile(game);

    str title = get_prelude(engine.game.prelude, "title", "Unknown"); // To be fixed (FIX)
 
    Model init() = <"none", title, engine, index, index, src, "", false, <[], 0.0>, <engine,[], 0.0>, "PuzzleScript/Interface/bin/output_image<index>.png", <[],[],[]>>;
    return init();
}

/*****************************************************************************/
// --- View Functions ---------------------------------------------------------

/*
 *  @Name:  view_panel
 *  @Desc:  Loads the HTML of the movement buttons in the GUI
 *  @Param:
 *      model   Application model
 */
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

/*
 *  @Name:  view_results
 *  @Desc:  Loads the HTML of the analysis' results in the GUI
 *  @Param:
 *      model   Application model
 */
void view_results(Model m) {
    div(class("panel"), () {
        h3("Results");
        LevelAppliedData ad = m.engine.level_applied_data[m.engine.current_level.original];
        p("-- Shortest path --");
        button(onClick(show(m.win.engine, 1, size(m.win.winning_moves))), "<size(m.win.winning_moves)> steps");
        p("-- Dead ends --");
        for (int i <- [0..size(m.de[0])]) {
            button(onClick(show(m.de[i][0], 0, size(m.de[i][1]))), "<i + 1>");
        }

        if (m.learning_goals != <[],[],[]>) {

            p("-- The following verbs have been used --");
            p("<intercalate(", ", m.learning_goals[2])>");

            p("-- The following learning goals are realised --");
            p("<intercalate(", ", m.learning_goals[0])>");

            p("-- The following learning goals are not realised --");
            p("<intercalate(", ", m.learning_goals[1])>");

        }
    });
}

/*
 *  @Name:  view
 *  @Desc:  Loads the HTML of the application in the GUI
 *  @Param:
 *      model   Application model
 */
void view(Model m) {
    div(class("header"), () {
        h1(style(("text-shadow": "1px 1px 2px black", "font-family": "Pixel", "font-size": "50px")), "PuzzleScript");
    });

    div(class("main"), () {

        div(class("left"), () {
            div(class("left_top"), () {
                h1(style(("text-shadow": "1px 1px 2px black", "padding-left": "1%", "text-align": "center", "font-family": "BubbleGum")), "Editor"); 
                ace("myAce", event=onAceChange(codeChange), code = m.code);
                button(onClick(load_design()), "Reload");
            });
            div(class("left_bottom"), () {
                div(class("TutoMate"), () {
                    h1(style(("text-shadow": "1px 1px 2px black", "padding-left": "1%", "text-align": "center", "font-family": "BubbleGum")), "TutoMate");
                    div(class("panel"), () {
                        h3(style(("font-family": "BubbleGum")), "Get insights");
                        button(onClick(analyse()), "Analyse");
                        button(onClick(analyse_all()), "Analyse all");
                    });
                    ace("TutoMate", event=onAceChange(dslChange), code = m.dsl, width="100%", height="15%");
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

/*****************************************************************************/
// --- Main Function ----------------------------------------------------------

/*
 *  @Name:  main()
 *  @Desc:  Runs the application
 *  @Ret:   Call to run the application
 */ 
App[Model] main() {
    game_loc = |project://DaedaLe/src/PuzzleScript/Tutorials/TutorialGames/limerick.PS|;
    // game_loc = |project://DaedaLe/src/PuzzleScript/Tutorials/demo/sokoban_basic.PS|;
    // game_loc = |project://DaedaLe/src/PuzzleScript/Tutorials/demo/nekopuzzle.PS|;

    GameData game = load(game_loc);
    Engine engine = compile(game);

    str title = "Lime Rick";

    tuple[str, str, str] json_data = pixel_to_json(engine, 0);
    data_loc = |project://DaedaLe/src/PuzzleScript/Interface/bin/data.dat|;
    writeFile(data_loc, json_data[0]);
    execWithCode("python3", workingDir=|project://DaedaLe/src/PuzzleScript/Interface/py|, args = ["ImageGenerator.py", resolveLocation(data_loc).path, json_data[1], json_data[2], "1"]);

    Model init() = <"none", title, engine, 0, 0, readFile(game_loc), limerick_dsl, false, <[],0.0>, <engine,[],0.0>, "PuzzleScript/Interface/bin/output_image0.png", <[],[],[]>>;
    Tutorial tutorial = tutorial_build(limerick_dsl);
    SalixApp[Model] counterApp(str id = "root") = makeApp(id, init, withIndex("Test", id, view, css = ["PuzzleScript/Interface/css/style.css"]), update);

    App[Model] counterWebApp() = webApp(counterApp(), |project://DaedaLe/src/|);

    return counterWebApp();
}