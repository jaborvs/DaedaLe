/*
 * @Module: GUI
 * @Desc:   Module that contains de GUI code for the generation tool.
 * @Auth:   Dennis Vet    -> code
 *          Borja Velasco -> code, comments
 */
module Interface::GUI

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
import Utils;
import PuzzleScript::Utils;
import PuzzleScript::AST;
import PuzzleScript::Load;
import PuzzleScript::Compiler;
import PuzzleScript::Engine;
import Generation::Load;
import Generation::AST;
import Generation::Compiler;
import Generation::Engine;

/*****************************************************************************/
// --- Data Structures defines ------------------------------------------------

/*
 *  @Name:  Model
 *  @Desc:  Aplication Model data structure
 */
alias Model = tuple[ 
    int index,                          // Turn of the game
    Engine engine,                      // Engine
    str puzzlescript_code,              // PuzzleScript code
    GenerationEngine generation_engine, // Generation engine
    str papyrus_code,                   // DSL code
    str image,                          // Image displayed
    str input                           // Input
];

/*
 *  @Name:  Msg
 *  @Desc:  Message function
 */
data Msg 
    = restart()
    | direction(int i)
    | reload()
    | puzzlescript_code_change(map[str,value] delta)
    | generate()
    | papyrvs_code_change(map[str,value] delta)
    ;

/*
 *  @Name:  JsonData (???)
 *  @Desc:  JSON data structure
 */
data JsonData 
    = alldata(
        CurrentLine \start,                                     // Start position 
        str action,                                             // Action 
        list[str] lines,                                        // Lines
        CurrentLine end,                                        // End position
        int id                                                  // Identifier
    );

/*
 *  @Name:  CurrentLine
 *  @Desc:  Current line data structure
 */
data CurrentLine = currentline(
    int column,                                             // Column no.
    int row                                                 // Row no.
    );

/*****************************************************************************/
// --- Main Function ----------------------------------------------------------

/*
 *  @Name:  main()
 *  @Desc:  Runs the application
 *  @Ret:   Application run
 */ 
App[Model] main() {
    game_loc = |project://daedale/src/PuzzleScript/demo/limerick.ps|;
    // game_loc = |project://daedale/src/PuzzleScript/demo/sokoban_basic.ps|;
    // game_loc = |project://daedale/src/PuzzleScript/demo/nekopuzzle.ps|;

    pprs_loc = |project://daedale/src/Generation/demo/limerick.pprs|;
    // pprs_loc = |project://daedale/src/Generation/demo/sokoban_basic.pprs|;
    // pprs_loc = |project://daedale/src/Generation/demo/nekopuzzle.pprs|;

    // We load and compile the game
    GameData game = ps_load(game_loc);
    Engine engine = ps_compile(game);

    // We represent the level on its initial state
    draw(engine, 0);

    // We load and compile the generation
    PapyrusData pprs = papyrus_load(pprs_loc);
    GenerationEngine generation_engine = papyrus_compile(pprs);

    // We start our GUI model
    Model init() = <
        0, 
        engine, 
        readFile(game_loc), 
        generation_engine, 
        readFile(pprs_loc), 
        "Interface/bin/output_image0.png", 
        ""
        >;
    SalixApp[Model] counterApp(str id = "root") = makeApp(id, init, withIndex("daedale", id, view, css = ["Interface/css/styles.css"]), update);
    App[Model] counterWebApp() = webApp(counterApp(), |project://daedale/src/|);

    return counterWebApp();
}

/******************************************************************************/
// --- Public GUI Functions ----------------------------------------------------

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
            // 'Restart' button has been pressed
            case restart(): {
                model.engine.current_level = model.engine.levels[model.engine.index];
                model.image = "Interface/bin/output_image0.png";
            }
            // PuzzleScript code has been changed
            case puzzlescript_code_change(map[str,value] delta): {    
                JsonData json_change = parseJSON(#JsonData, asJSON(delta["payload"]));
                model = update_code(model, json_change, 0);
            }
            // DSL code has been changed
            case papyrvs_code_change(map[str,value] delta): {
                JsonData json_change = parseJSON(#JsonData, asJSON(delta["payload"]));
                model = update_code(model, json_change, 1);
            }
            // Reload PuzzleScript code
            case reload(): {
                model.index += 1;
                model = reload_code(model.puzzlescript_code, model.index);

                draw(model.engine, model.index);
            }
            // Generate button
            case generate(): {
                list[list[str]] generated_levels = generate(model.generation_engine);
            }
            // Default case
            default: return model;
        }
        
        // In case we have done a manual move we update the index, check if we have won and update
        // the leve representation
        if (execute) {
            model.index += 1;
            model.engine = execute_move(model.engine, model.input, 0);
            if (check_conditions(model.engine)) {
                model.index = 0;
                model.engine.index += 1;
                model.engine.current_level = model.engine.levels[model.engine.index];
            }

            draw(model.engine, model.index);
            model.image = "Interface/bin/output_image<model.index>.png";

            execute = false;
        }
    }

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
    str code = category == 0 ? model.puzzlescript_code : model.papyrus_code;
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
    
    if (category == 0) model.puzzlescript_code = new_code;
    else model.papyrus_code = new_code;

    return model;
}

/*
 *  @Name:  reload_code
 *  @Desc:  Reload the current PuzzleScript code
 *  @Param:
 *      src     Location of the game file
 *      index   Index (???)
 *  @Ret:   Default application model
 */
Model reload_code(str src, int index) {
    GameData game = load(src);
    Engine engine = compile(game);
 
    Model init() = <0, engine, src, limerick_dsl, "PuzzleScript/Interface/bin/output_image<index>.png", "none">;
    return init();
}

/*****************************************************************************/
// --- View Functions ---------------------------------------------------------

/*
 *  @Name:  view
 *  @Desc:  Loads the HTML of the application in the GUI
 *  @Param:
 *      model   Application model
 */
void view(Model model) {
    div(class("container"), () {
        div(class("left"), () {
            div(class("top-left"),() {
                div(class("header"), () {
                    h3("PuzzleScript Editor");
                    button(class("button"), onClick(reload()), "⟳");
                });
                div(class("code"), () {
                    ace("puzzlescript", event=onAceChange(puzzlescript_code_change), code = model.puzzlescript_code, height = "100%");
                });
            });
            div(class("bottom-left"),() {
                div(class("header"), () {
                    h3("Papyrvs Editor");
                    button(class("button"), onClick(generate()), "Generate");
                });

                div(class("code"), () {
                    ace("papyrus", event=onAceChange(papyrvs_code_change), code = model.papyrus_code, height = "100%");
                });
            });
        });
        div(class("right"), onKeyDown(direction), () {
            div(class("top-right"), onKeyDown(direction), () {
                div(class("top-right-left"), () {
                    img(class("puzzlescript-game"), src("<model.image>"), () {});
                });
                div(class("top-right-right"), () {
                    div(class("pad"), () {
                        button(class("button button-pad"), onClick(direction(38)), "▲");
                        div(class("middle-buttons"), (){
                            button(class("button button-pad"), onClick(direction(37)), "◄");
                            button(class("button button-pad"), onClick(restart()), "⟳");
                            button(class("button button-pad"), onClick(direction(39)), "►");
                        });
                        button(class("button button-pad"), onClick(direction(40)), "▼");
                    });
                });
            });
            div(class("bottom-right"),() {
                div(class("header"), () {
                    h3("daedale Console");
                });
                div(class("code terminal"), () {
                    p("Placeholder");
                });
            });
        });
    });
}

/******************************************************************************/
// --- Public Json Conversion Functions ----------------------------------------

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
                                json += "\"c\": \"<COLORS["transparent"]>\"";
                            }
                            else if (COLORS[obj.colors[toInt(pix.color_number)]]?) {
                                json += "\"c\": \"<COLORS[obj.colors[toInt(pix.color_number)]]>\"";
                            }
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

/******************************************************************************/
// --- Drawing Functions ------------------------------------------------------

/*
 * @Name:   draw
 * @Desc:   Function that draws a level
 * @Params: engine -> Engine
 *          index  -> Current Turn
 * @Ret:    void
 */
void draw(Engine engine, int index) {
    data_loc = |project://daedale/src/Interface/bin/data.dat|;

    tuple[str, str, str] json_data = pixel_to_json(engine, index);
    writeFile(data_loc, json_data[0]);
    tmp = execWithCode("python3", workingDir=|project://daedale/src/Interface/py|, args = ["ImageGenerator.py", resolveLocation(data_loc).path, json_data[1], json_data[2], "1"]);
}