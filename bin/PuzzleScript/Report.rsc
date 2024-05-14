module PuzzleScript::Report

// import PuzzleScript::Interface::GUI;
// import PuzzleScript::Load;
// import PuzzleScript::Engine;
// import PuzzleScript::Compiler;
// import PuzzleScript::Checker;
// import PuzzleScript::AST;
// import IO;
// import util::Eval;
// import Type;
// import util::Math;
// import List;
// import String;

// import util::Benchmark;


// // data ParseResult
// //   = src_parse_error(loc file)
// //   | src_ambiguous(loc file, str rule, str input)
// //   | src_implode_error(loc file, start[PSGame] tree)
// //   | src_success(loc file, start[PSGame] tree, PSGame game);

// // data CheckResult
// //   = chk_error() 
// //   | chk_success(Checker checker, int errors, int warnings, int infos);
  
// // data Summary
// //   = summary_error()
// //   | summary(str title, str author, int objects, 
// //             int layers, int collisions, int rules, int conditions, int levels, bool zoom);


// void save_results(list[list[Model]] models, str category) {


//     println("1");
//     loc verb_dir = |project://automatedpuzzlescript/DaedaLe/src/PuzzleScript/Results/Verbs|;
//     generate_reports(models, verb_dir, category);

// }

// void generate_reports(list[list[Model]] models, loc verb_dir, str category) {

//     println("2");
//     str levelOutput = "";

//     if (size(models) == 0) return;

//     list[Level] levels = models[0][0].engine.converted_levels;

//     map[LevelData, LevelChecker] ld = models[0][0].win.engine.level_data;

//     str title = "";
//     str author = "";

//     for(PreludeData p <- models[0][0].engine.game.prelude){
//         if(p.key == "title") {
//         title = replaceAll(p.string, ",", " ");
//         break;
//         }
//     }
//     println("3");
    
//     for(PreludeData p <- models[0][0].engine.game.prelude){
//         if(p.key == "author") {
//         author = replaceAll(p.string, ",", " ");
//         break;
//         }
//     }

//     println("4");

//     title = replaceAll(title, " ", "_");

//     println(verb_dir.path + "/<title + "_" + category>.csv");
    
//     verb_dir.path = verb_dir.path + "/<title + "_" + category>.csv";
//     str filePath = verb_dir.authority + verb_dir.path;
//     if (!isFile(verb_dir)) {
//         touch(verb_dir);
//         writeFile(verb_dir, "level,actions,length,verbs,time,comply,not_comply\n");
//     }

//     int levelIndex = get_level_index(models[0][0].engine, models[0][0].engine.current_level);

//     println("Generating report for <title>");

//     for (list[Model] model <- models) {

//         if (category == "win") {
//             appendToFile(verb_dir, "<levelIndex>,<intercalate(" ", model[0].win.winning_moves)>,<size(model[0].win.winning_moves)>,<intercalate(" ", model[0].learning_goals[2])>, <model[0].win.time>,<intercalate(" ", model[0].learning_goals[0])>,<intercalate(" ", model[0].learning_goals[1])>\n");
//         }
//         else if (category == "fails") {

//             for (Model model <- model) {
//                 for (tuple[Engine, list[str]] dead_end <- model.de[0]) {
//                     appendToFile(verb_dir, "<levelIndex>,<intercalate(" ", dead_end[1])>,<size(dead_end[1])>,<intercalate(" ", model.learning_goals[2])>, <model.de[1]>,<intercalate(" ", model.learning_goals[0])>,<intercalate(" ", model.learning_goals[1])>\n");     
//                 }
//             }
//         }

//         levelIndex += 1;

//     }
// }