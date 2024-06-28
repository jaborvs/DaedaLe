/*
 * @Module: GUI
 * @Desc:   Module that contains de GUI code for the generation tool.
 * @Auth:   Dennis Vet    -> code
 *          Borja Velasco -> code, comments
 */
module Interface::GUI

/******************************************************************************/
// --- General modules imports -------------------------------------------------
import salix::HTML;
import salix::Core;
import salix::App;
import salix::Index;
import salix::ace::Editor;
import salix::Node;

import String;
import List;
import Type;
import Set;
import IO;

/******************************************************************************/
// --- Own modules imports -----------------------------------------------------
import Utils;

import Interface::Draw;

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
    int index,                                      // Turn of the game
    Engine engine,                                  // Engine
    str puzzlescript_code,                          // PuzzleScript code
    GenerationEngine generation_engine,             // Generation engine
    str papyrus_code,                               // DSL code
    str image,                                      // Image displayed
    list[tuple[str command, str output]] console,  // Terminal content
    str input                                       // Input
];

/*
 *  @Name:  Msg
 *  @Desc:  Message function
 */
data Msg 
    = restart()
    | movement(int direction)
    | clear()
    | run()
    | change_code_puzzlescript(map[str,value] delta)
    | generate()
    | papyrvs_code_change(map[str,value] delta)
    ;

/*
 *  @Name:  Json(???)
 *  @Desc:  JSON data structure
 */
data JsonData
    = alldata(
        CurrentLine \start,                                     // Start position 
        str action,                                             // Action 
        list[str] lines,                                        // Lines
        CurrentLine end,                                        // End position
        int id                                                  // Identifier
        )
    | json_empty()
    ;

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
    // game_loc = |project://daedale/src/PuzzleScript/demo/mazecrawler.ps|;
    // game_loc = |project://daedale/src/PuzzleScript/demo/nekopuzzle.ps|;

    pprs_loc = |project://daedale/src/Generation/demo/limerick.pprs|;
    // pprs_loc = |project://daedale/src/Generation/demo/mazecrawler.pprs|;
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
        [],
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
Model update(Msg cmd, Model model){
    if (!(model.engine.current_level is game_level)) return model;

    switch(cmd){
        case movement(int direction): model = update_movement(model, direction); 
        case restart(): model = update_restart(model);
        case clear(): model = update_clear(model);
        case change_code_puzzlescript(map[str,value] delta): model = update_change_code(model, delta, "puzzlescript");
        case papyrvs_code_change(map[str,value] delta): model = update_change_code(model, delta, "papyrus");
        case run(): model = update_run(model); 
        case generate(): model = update_generate(model); 
        default: return model;
    }
        
    if (movement(int direction) := cmd) {
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

    return model;
}

/*
 * @Name:   update_movement
 * @Desc:   Function that updates the model after a movement has been performed
 * @Param:  model     -> GUI model to update
 *          direction -> Direction of the movement
 * @Ret:    Updated model
 */
Model update_movement(Model model, int direction) {       
    switch(direction) {
        case 37: model.input = "left";
        case 38: model.input = "up";
        case 39: model.input = "right";
        case 40: model.input = "down";
    }

    return model; 
}

/*
 * @Name:   update_restart
 * @Desc:   Function that updates the model after a restart has been pressed
 * @Param:  model     -> GUI model to update
 * @Ret:    Updated model
 */
Model update_restart(Model model) {
    model.engine.current_level = model.engine.levels[model.engine.index];
    model.image = "Interface/bin/output_image0.png";

    return update_console(model, "restart level", "Succesful level <model.engine.index> restart");
}

/*
 * @Name:   update_clear
 * @Desc:   Function that clears the console
 * @Param:  model     -> GUI model to update
 * @Ret:    Updated model
 */
Model update_clear(Model model) {
    model.console = [];
    return update_console(model, "clear", "Successful clear");
}

/*
 * @Name:   update_change_code
 * @Desc:   Function that updates the model after a change in code
 * @Param:  model -> GUI model to update
 *          delta -> Code changes performed
 *          lang  -> Language of the changes
 * @Ret:    Updated model
 */
Model update_change_code(Model model, map[str,value] delta, str lang) {
    JsonData json_change = json_empty();
    str code = "";
    list[str] code_lines = [];
    str code_new_line = "";

    json_change =  parseJSON(#JsonData, asJSON(delta["payload"]));

    code = (lang == "puzzlescript") ? model.puzzlescript_code : model.papyrus_code;
    code_lines = split("\n", code);
    code_new_line = "";

    int row = json_change.\start.row;
    int begin = json_change.\start.column;
    int end = json_change.end.column;

    switch(json_change.action) {
        case "remove": {
            code_new_line = code_lines[row][0..begin] + code_lines[row][end..];
        }
        case "insert": {
            code_new_line = code_lines[row][0..begin] + intercalate("", json_change.lines) + code_lines[row][begin..];
        }
    }
    code_lines[json_change.\start.row] = code_new_line;
    code = intercalate("\n", code_lines);
    
    if (lang == "puzzlescript") model.puzzlescript_code = code;
    else                        model.papyrus_code = code;

    return return update_console(model, "change code", "Succesful <string_capitalize(lang)> code change");
}

/*
 * @Name:   update_run
 * @Desc:   Function that updates the model after the run button was pressed
 * @Param:  model     -> GUI model to update

 * @Ret:    Updated model
 */
Model update_run(Model model) {
    model.index += 1;

    draw(model.engine, model.index);
 
    model = <
        0, 
        ps_compile(ps_load(model.puzzlescript_code)), 
        model.puzzlescript_code, 
        papyrus_compile(papyrus_load(model.papyrus_code)),
        model.papyrus_code, 
        "Interface/bin/output_image<model.index>.png", 
        model.console,
        ""
    >;

    return update_console(model, "run", "Successful compilation, running game");
}

/*
 * @Name:   update_generate
 * @Desc:   Function that updates the model after a movement has been performed
 * @Param:  model     -> GUI model to update
 * @Ret:    Updated model
 */
Model update_generate(Model model) {
    generate(model.generation_engine);
    return update_console(model, "generate levels", "Succesful genearation, levels generated in |project://daedale/src/Interface/bin/levels.out|");
}

/*
 * @Name:   update_console
 * @Desc:   Function that updates the model console
 * @Param:  model   -> GUI model to update
 *          command -> Executed command
 *          output  -> Output of the command
 * @Ret:    Updated model
 */
Model update_console(Model model, str command, str output) {
    model.console += [<command, output>];
    return model;
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
            div(class("top-left"),() {view_editor_puzzlescript(model);});
            div(class("bottom-left"),() {view_editor_papyrus(model);});
        });
        div(class("right"), onKeyDown(movement), () {
            div(class("top-right"), onKeyDown(movement), () {view_level(model);});
            div(class("bottom-right"),() {view_console(model);});
        });
    });
}

/*
 * @Name:  view
 * @Desc:  Loads the HTML of the puzzlescript editor
 * @Param: model -> Application model
 * @Ret:   void
 */
void view_editor_puzzlescript(Model model) {
    div(class("header"), () {
        h3("PuzzleScript Editor");
        button(class("button"), onClick(run()), "Run");
    });
    div(class("code"), () {
        ace("puzzlescript", event=onAceChange(change_code_puzzlescript), code = model.puzzlescript_code, height = "100%");
    });
}


/*
 * @Name:  view
 * @Desc:  Loads the HTML of the papyrus editor
 * @Param: model -> Application model
 * @Ret:   void
 */
void view_editor_papyrus(Model model) {
    div(class("header"), () {
        h3("Papyrvs Editor");
        button(class("button"), onClick(generate()), "Generate");
    });

    div(class("code"), () {
        ace("papyrus", event=onAceChange(papyrvs_code_change), code = model.papyrus_code, height = "100%");
    });
}


/*
 * @Name:  view
 * @Desc:  Loads the HTML of the level representation
 * @Param: model -> Application model
 * @Ret:   void
 */
void view_level(Model model) {
    div(class("top-right-left"), () {
        img(class("puzzlescript-game"), src("<model.image>"), () {});
    });
    div(class("top-right-right"), () {
        div(class("pad"), () {
            button(class("button button-pad"), onClick(movement(38)), "▲");
            div(class("middle-buttons"), (){
                button(class("button button-pad"), onClick(movement(37)), "◄");
                button(class("button button-pad"), onClick(restart()), "⟳");
                button(class("button button-pad"), onClick(movement(39)), "►");
            });
            button(class("button button-pad"), onClick(movement(40)), "▼");
        });
    });
}


/*
 * @Name:  view
 * @Desc:  Loads the HTML of the daedale console
 * @Param: model -> Application model
 * @Ret:   void
 */
void view_console(Model model) {
    div(class("header"), () {
        h3("DaeDaLe Console");
        button(class("button"), onClick(clear()), "Clear");
    });
    div(class("code console"), () {
        for(tuple[str command, str output] executed <- model.console) {
            p("daedale:~$ <executed.command>");
            p("<executed.output>");
        }
    });
}