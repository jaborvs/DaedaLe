module PuzzleScript::Report

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

    loc DemoDir = |project://automatedpuzzlescript/src/PuzzleScript/Test/Tutorials|;
    loc CountableDir = |project://automatedpuzzlescript/src/PuzzleScript/Results/Countables|;
    loc RuleDir = |project://automatedpuzzlescript/src/PuzzleScript/Results/Rules|;

	PSGame game;
	Checker checker;
	Engine engine;
	Level level;

    generate_reports(CountableDir, RuleDir, DemoDir);

}

void generate_reports(loc CountableDir, loc RuleDir, loc DemoDir) {

    for(loc file <- DemoDir.ls){
        if(file.extension == "txt"){
        
            // Creates ast
            ParseResult p = parseFile(file);
        
            // If parseresult is success (has the tree and ast):
            if(src_success(loc file, start[PSGame] tree, PSGame game) := p) {
            
                checker = check_game(game);
                engine = compile(checker);
                generate_report_per_level(engine, RuleDir, CountableDir);

            }
        }
    }

}

// This function is used to generate reports and create charts for each game
// Content generate_report_per_level(Engine engine, loc directory) {
void generate_report_per_level(Engine engine, loc rule_directory, loc count_directory) {

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
    
    count_directory.path = count_directory.path + "/<title>.csv";
    str filePath = count_directory.authority + count_directory.path;
    if (!isFile(count_directory)) touch(count_directory);

    rule_directory.path = rule_directory.path + "/<title>.csv";
    filePath = rule_directory.authority + rule_directory.path;
    if (!isFile(rule_directory)) touch(rule_directory);

    writeFile(count_directory, "level,size,moveable_objects\n");
    writeFile(rule_directory, "level,rules\n");

    int levelIndex = 1;

    for (Level level <- levels) {

        if (level.original is level_empty) continue;
        if (engine.level_data[level.original].size[1] == 1) {
            println(engine.level_data[level.original].size);
            continue;
        }

        int applied_rules = size(ld[level.original].applied_rules) + size(ld[level.original].applied_late_rules);
        list[list[Rule]] rules = ld[level.original].applied_rules + ld[level.original].applied_late_rules;

        real level_size = ld[level.original].size[0] * ld[level.original].size[1] / 100.0;

        appendToFile(count_directory, "<levelIndex>,<level_size>,<size(ld[level.original].moveable_objects)>\n");
        for (list[Rule] rule <- rules) {

            if (any(RuleData rd <- engine.game.rules, rd.src == rule[0].original.src)) {
                appendToFile(rule_directory, "<levelIndex>, <engine.indexed_rules[rd][0]>\n");
            }

        }
        // appendToFile(rule_directory, "<levelIndex>,<rules>\n");
        levelIndex += 1;

    }
    appendToFile(count_directory, "\n");
    appendToFile(rule_directory, "\n");

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