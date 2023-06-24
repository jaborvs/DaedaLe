module PuzzleScript::Report

import util::IDEServices;
import vis::Charts;
import vis::Presentation;
import vis::Layout;
import util::Web;

import PuzzleScript::Load;
import PuzzleScript::Engine;
import PuzzleScript::Compiler;
import PuzzleScript::Checker;
import PuzzleScript::AST;
import IO;
import util::Eval;
import Type;
import util::Math;
import List;
import String;

import util::Benchmark;


data ParseResult
  = src_parse_error(loc file)
  | src_ambiguous(loc file, str rule, str input)
  | src_implode_error(loc file, start[PSGame] tree)
  | src_success(loc file, start[PSGame] tree, PSGame game);

data CheckResult
  = chk_error() 
  | chk_success(Checker checker, int errors, int warnings, int infos);
  
data Summary
  = summary_error()
  | summary(str title, str author, int objects, 
            int layers, int collisions, int rules, int conditions, int levels, bool zoom);

void main() {

    loc DemoDir = |project://AutomatedPuzzleScript/src/PuzzleScript/Test/Tutorials|;
    loc ReportDir = |project://AutomatedPuzzleScript/src/PuzzleScript/Results|;

	PSGame game;
	Checker checker;
	Engine engine;
	Level level;

    generate_reports(ReportDir, DemoDir);

}

void generate_reports(loc ReportDir, loc DemoDir) {

    list[Content] charts = [];

    for(loc file <- DemoDir.ls){
        if(file.extension == "txt"){
        
            // Creates ast
            ParseResult p = parseFile(file);
            // CheckResult c = chk_error();
            // Summary s = summary_error();
        
            // If parseresult is success (has the tree and ast):
            if(src_success(loc file, start[PSGame] tree, PSGame game) := p) {
            
                checker = check_game(game);
                engine = compile(checker);
                generate_report_per_level(engine, ReportDir);

                // charts += [generate_report_per_level(checker, ReportDir)];

            }
        }
    }

    // showInteractiveContent(charts[2]);


}

// This function is used to generate reports and create charts for each game
// Content generate_report_per_level(Engine engine, loc directory) {
void generate_report_per_level(Engine engine, loc directory) {

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
    directory.path = directory.path + "/<title>.csv";

    str filePath = directory.authority + directory.path;

    // Create file if it does not exist yet
    if (!isFile(directory)) touch(directory);

    writeFile(directory, "level, size, moveable_objects, rules, messages\n");

    int levelIndex = 1;

    for (Level level <- levels) {

        // if (ld is level_empty) continue;
        // // Means message is incorrectly parsed as level
        // if (ld[level].size.height == 1) continue;

        int applied_rules = size(ld[level.original].applied_rules) + size(ld[level.original].applied_late_rules);

        appendToFile(directory, "<levelIndex>,<ld[level.original].size>,<size(ld[level.original].moveable_objects)>,<applied_rules>,<size(ld[level.original].messages)>\n");
        levelIndex += 1;

    }
    appendToFile(directory, "\n");

    // Only get level_data for visualizing purposes
    // list[LevelData] level_data_ld = [x | x <- levels, x is level_data];

    // return lineChart(["size", "moving objects", "applied rules", "messages"],
    //         [<"<x>",(ld[level_data_ld[x]].size.width)> | x <- [0..size(level_data_ld)]], 
    //         [<"<x>",(size(ld[level_data_ld[x]].moveable_objects))> | x <- [0..size(level_data_ld)]], 
    //         [<"<x>",(size(ld[level_data_ld[x]].applied_rules))> | x <- [0..size(level_data_ld)]],
    //         [<"<x>",(size(ld[level_data_ld[x]].messages))> | x <- [0..size(level_data_ld)]]);

}


public ParseResult parseFile(loc file) {
    str src = readFile(file);
    loc preFile = file;  
    preFile.extension = "PS";
    writeFile(preFile, src);

    ParseResult result = src_parse_error(preFile);
    try {

        // Create tree and AST
        start[PSGame] tree = ps_parse(preFile);

        PSGame ast = ps_implode(tree);
        try {
            result = src_success(preFile, tree, ast);      
        } catch x: {
            result = src_implode_error(preFile, tree);
        }
    }
    catch Ambiguity(loc l, str rule, str s): {
        result = src_ambiguous(l, rule, s);
    } 
    catch ParseError(loc l): {
        result = src_parse_error(l);
    }

    return result;
}