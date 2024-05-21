module PuzzleScript::DynamicReport

// import util::IDEServices;
// import vis::Charts;
// import vis::Presentation;
// import vis::Layout;
// import util::Web;

import PuzzleScript::Load;
import PuzzleScript::Engine;
import PuzzleScript::Compiler;
import PuzzleScript::Checker;
import PuzzleScript::AST;
import PuzzleScript::DynamicAnalyser;
import IO;
import util::Eval;
import Type;
import util::Math;
import List;
import String;

import util::Benchmark;

void main() {

    loc DemoDir = |project://DaedaLe/src/PuzzleScript/Test/Tutorials|;
    loc DynamicDir = |project://DaedaLe/src/PuzzleScript/Results/Dynamic|;

    PSGame game;
    Checker checker;
    Engine engine;
    Level level;

    generate_reports(DemoDir, DynamicDir);

}

Engine get_statistics(Engine engine, Checker checker) {

    str title = "";

    for(PreludeData p <- engine.game.prelude){
        if(p.key == "title") {
        title = replaceAll(p.string, ",", " ");
        break;
        }
    }

    println("Looking for winning moves for <title> for level:");
    for (int i <- [0..size(engine.converted_levels)]) {
        if (engine.converted_levels[i] == engine.current_level) print(i + 1);
    }

    list[str] possible_moves = ["up", "down", "right", "left"];

    for (int i <- [0..3]) {
        engine.current_level = engine.converted_levels[i];
        Engine starting_state = engine;

        print_level(starting_state, checker);
    
        list[str] winning_moves = bfs(starting_state, possible_moves, checker, "win");
        engine.level_data[engine.current_level.original].shortest_path = winning_moves;

        for (str move <- winning_moves) {
            engine = execute_move(engine, checker, move);
            // print_level(engine, checker);
        }    
    
    }

    return engine;

}


void generate_reports(loc DemoDir, loc DynamicDir) {

    for(loc file <- DemoDir.ls){
        if(file.extension == "txt"){
        
            // Creates ast
            ParseResult p = parseFile(file);
        
            // If parseresult is success (has the tree and ast):
            if(src_success(loc file, start[PSGame] tree, PSGame game) := p) {
            
                checker = check_game(game);
                engine = compile(checker);

                Engine result = get_statistics(engine, checker);
                generate_report_per_level(result, DynamicDir);

            }
        }
    }

}




// This function is used to generate reports and create charts for each game
// Content generate_report_per_level(Engine engine, loc directory) {
void generate_report_per_level(Engine engine, loc count_directory) {

    str levelOutput = "";

    list[Level] levels = engine.converted_levels;
    map[LevelData, LevelChecker] ld = engine.level_data;

    str title = "";
    str author = "";

    for(PreludeData p <- engine.game.prelude){
        if(p.key == "title") {
        title = replaceAll(p.string, ",", " ");
        break;
        }
    }
    
    for(PreludeData p <- engine.game.prelude){
        if(p.key == "author") {
        author = replaceAll(p.string, ",", " ");
        break;
        }
    }

    title = replaceAll(title, " ", "_");
    
    count_directory.path = count_directory.path + "/<title>_win.csv";
    str filePath = count_directory.authority + count_directory.path;
    if (!isFile(count_directory)) touch(count_directory);

    writeFile(count_directory, "level,applied_rule\n");

    int levelIndex = 1;

    for (Level level <- levels) {

        if (level.original is level_empty) continue;
        if (engine.level_data[level.original].size[1] == 1) continue;

        list[RuleData] rules = ld[level.original].actual_applied_rules;

        println(size(rules));
        println("Finished level <levelIndex>");

        for (RuleData rule <- rules) {
            if (any(RuleData indexed_rule <- engine.indexed_rules<0>, indexed_rule.src == rule.src)) {
                println("Adding rule to file");
                appendToFile(count_directory, "<levelIndex>, <engine.indexed_rules[indexed_rule][0]>\n");
            } else {
                println("Rule not in indexed rules!");
            }
        }
        levelIndex += 1;
    }
    appendToFile(count_directory, "\n");

}

