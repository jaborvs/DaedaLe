module PuzzleScript::DynamicReport

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
import PuzzleScript::Report;
import IO;
import util::Eval;
import Type;
import util::Math;
import List;
import String;

import util::Benchmark;

void main() {

    loc DemoDir = |project://AutomatedPuzzleScript/src/PuzzleScript/Test/Tutorials|;
    loc DynamicDir = |project://AutomatedPuzzleScript/src/PuzzleScript/Results/Dynamic|;

	PSGame game;
	Checker checker;
	Engine engine;
	Level level;

    generate_reports(CountableDir, DynamicDir);

}

void generate_reports(loc CountableDir, loc DynamicDir) {


    list[Content] charts = [];

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

    map[RuleData, tuple[int, str]] indexed_rules = index_rules(engine.game.rules);

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
                appendToFile(rule_directory, "<levelIndex>, <indexed_rules[rd][0]>\n");
            }

        }
        // appendToFile(rule_directory, "<levelIndex>,<rules>\n");
        levelIndex += 1;

    }
    appendToFile(count_directory, "\n");
    appendToFile(rule_directory, "\n");

}

