module PuzzleScript::Report

import IO;
import String;
import ParseTree;
import PuzzleScript::AST;
import PuzzleScript::Load;
import PuzzleScript::Syntax;
import PuzzleScript::Checker;

loc DemoDir = |project://AutomatedPuzzleScript/src/PuzzleScript/Test/demo|;
loc ReportFile = |project://AutomatedPuzzleScript/src/PuzzleScript/report.csv|;

alias GameData =
  tuple[loc file, ParseResult parse, CheckResult check, Volume volume, Summary summary];
  
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
data Volume 
  = volume(int sloc, int comment_lines, int blank_lines);

public str doIt() = generateReport(DemoDir, ReportFile);

/*
data RiskProfile = profile(str name, list[tuple[str name, set[GameData](int min, int max) f]] categories);

RiskProfile volumeProfile("volume", [<"++",x>, <"+",x>, <"0",x>, <"-",x>, <"--",x>]);

RiskProfile ruleProfile("rule complexity", [<"++",x>, <"+",x>, <"0",x>, <"-",x>, <"--",x>]);

RiskProfile winProfile("win condition", [<"none",x>, <"one",x>, <"multi",x>]);

public list[int] rules = [3,4,23,46,19,1,2,7,6,54,93,4,11,5,94,28,10,8,3,22,2,17,10,22,21,19,1,50,19,31,30,17,2,11,3,7,7,1,2,44,2,4,5,8,4,14,2,1,44,1,59,2,2,28,50,5,0,45,19,1,42,1,60,5,1,31,28,2,36,153,15,19,106,9,79,34,1,1,10,70,7,38,187,18,2,10,44,5,31,51,41,80,11,1];

public list[int] sloc = [81,107,305,409,218,91,90,126,360,426,522,81,159,116,385,331,124,392,167,368,87,273,216,483,737,218,75,541,151,247,536,109,130,283,149,183,99,44,80,235,84,76,90,204,266,278,83,82,393,86,381,79,50,285,394,153,28,382,211,67,586,86,443,91,85,141,309,167,391,1430,309,341,450,74,538,602,91,158,164,324,69,387,467,124,58,164,434,91,131,519,230,690,81,60];

list[tuple[int low, int high, list[int n] numbers]] genProfile(int groups, list[int] values){
  list[int] sorted = sort(values);
  int groupsize = size(values) / groups + 1;  
  int min = 0;
  int count = 0;
  int ocur;
  list[tuple[int low, int high, list[int n] numbers]] categories = [];  
  list[int] numbers = [];
  for(cur <- sorted){
    ocur = cur;
    count = count + 1;
    numbers = numbers + [cur];
    if(count >= groupsize){
      categories = categories + [<min, cur, numbers>];
      numbers = [];
      min = cur;
      count = 0;
    }
  }
  if(size(categories) < groups){
    categories = categories + [<min, ocur, numbers>];
  }
  return categories;
}
*/


public str generateReport(loc dir, loc outFile){
  str report = 
    "title, author, objects, layers, collisions, rules, winconditions, levels, zoom, "+
    "sloc, comment lines, blank lines," +    
    "parse result,"+
    "check result, errors, warnings, file\n";
  set[GameData] results = analyzeAll(dir);
  for(GameData g <- results) {
    report = report + 
      "<csvLine(g.summary)>,<csvLine(g.volume)>,<csvLine(g.parse)>,<csvLine(g.check)>,<g.file>\n";
  }
  
  writeFile(outFile, report); 
  
  return report;
}

private str csvLine(Volume v) =
  "<v.sloc>, <v.comment_lines>, <v.blank_lines>";

private str csvLine(ParseResult p: src_parse_error(loc file)) =
  "error";

private str csvLine(ParseResult p: src_ambiguous(loc file, str rule, str input)) =
  "ambiguous";
  
private str csvLine(ParseResult p: src_implode_error(loc file, start[PSGame] tree)) = 
  "implode error";

private str csvLine(ParseResult p: src_success(loc file, start[PSGame] tree, PSGame game)) =
  "success";  

private str csvLine(CheckResult c: chk_error()) =
  "error, , ";
  
private str csvLine(CheckResult c: chk_success(Checker checker, int errors, int warnings, int infos)) = 
  "success, <errors>, <warnings>"; //, <infos>

private str csvLine(Summary s: summary_error()) =
  "error, , , , , , , , ";

private str csvLine(Summary s: summary(str title, str author, int objects, int layers, int collisions, int rules, int conditions, int levels, bool zoom)) =
  "<title>, <author>, <objects>, <layers>, <collisions>, <rules>, <conditions>, <levels>, <zoom>";

public set[GameData] analyzeAll(loc dir){  
  set[ParseResult] parseResults = {};
  set[GameData] results = {};

  for(loc file <- dir.ls){
    if(file.extension == "txt"){
      ParseResult p = parseFile(file);
      CheckResult c = chk_error();
      Summary s = summary_error();
      
      if(src_success(loc file, start[PSGame] tree, PSGame game) := p) {
        c = checkGame(game);
        s = summarize(game);
      }
      
      Volume v = countLines(file);
      
      results = results + {<file, p, c, v, s>};
	}
  }
  
  return results;
}

public Summary summarize(PSGame game){  
  str title = "";
  str author = "";
  int objects = 0;
  int rules = 0;
  int conditions = 0;
  int levels = 0;
  int messages = 0;
  int layers = 0;
  int collisions = 0;
  bool zoom = false;

  for(PreludeData p <- game.prelude){
    if(p.key == "title") {
      title = replaceAll(p.string, ",", " ");
      break;
    }
  }
  
  for(PreludeData p <- game.prelude){
    if(p.key == "author") {
      author = replaceAll(p.string, ",", " ");
      break;
    }
  }
  
  for(PreludeData p <- game.prelude){
    if(p.key == "zoomscreen" || p.key == "flickscreen"){
      zoom = true;
    }
  }
  
  visit(game.objects){
	case object_data(str name, list[str] legend, list[str] colors, list[list[Pixel]] sprite, int id): {
	  objects = objects + 1;
	}
  }
  
  visit(game.layers){
    case layer_data(list[str] layer): {
      layers = layers + 1;
      int len = size(layer);
      if(len > 1){
        collisions = (len * (len - 1))/2;
      }
    }
  }
  
  visit(game.rules){
    case rule_data(list[RulePart] left, list[RulePart] right, list[str] message, _): {
      rules = rules + 1;
    }
  }
  
  visit(game.conditions){
    case condition_data(list[str] condition, _): {
      conditions = conditions + 1;   
    }
  }
  
  visit(game.levels){
    case level_data_raw(level_data_raw(_)): {
      throw "error";
    }
	case level_data(list[str] level): {
	  levels = levels + 1;
	}
	case message(str message): {
	  messages = messages + 1;
	}
  }

  return summary(title, author, objects, layers, collisions, rules, conditions, levels, zoom);
}

public Volume countLines(loc file){
  str program = readFile(file);  
  program = replaceAll(program, "\r", "");
  int sloc = 0;
  int comment_lines = 0;
  int blank_lines = size(findAll(program, "\n\n"));  
  program = replaceAll(program, "\n\n", "\n");

  list[str] lines = split("\n", program);
 
  int line = 0;
  while(line < size(lines)) {
    str todo = "";
    for(int x <- [line .. size(lines)]) {
      todo = todo + lines[x] + "\n";
    }
    
    if(/^<pre:[^\(\n]*><comment:[\(]([^\)])*[\)][\n]>/ := todo) {
      if(pre != ""){
        sloc = sloc + 1;
      }    
      int size = size(findAll(comment, "\n"));
      comment_lines = comment_lines + size;
      line = line + size;
    }
    else {
      line = line + 1;
      sloc = sloc + 1;
    }
  }
 
  return volume(sloc, comment_lines, blank_lines); 
}

private CheckResult checkGame(PSGame game){
  CheckResult c = chk_error();   
  Checker checker = check_game(game);    
  int errors = 0;
  int warnings = 0;
  int infos = 0;
  try {
    visit(checker) {
      case error(): errors = errors + 1;
      case warn(): warnings = warnings + 1;
      case info(): infos = infos + 1;
    }
    c = chk_success(checker, errors, warnings, infos);
  }
  catch e: {
    c = chk_error();
  }
  return c;
}

public ParseResult parseFile(loc file) {
  str src = readFile(file);
  loc preFile = file;  
  preFile.extension = "PS";
  writeFile(preFile, src);

  ParseResult result = src_parse_error(preFile);
  try {
    start[PSGame] tree = ps_parse(preFile); 
    PSGame ast = ps_implode(tree);
    try {
      result = src_success(preFile, tree, ast);      
    }
    catch x: {
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

/*
public str spaces(int length){
  r = "";
  for(int i <- [1..length]){
    r = r + " ";
  }
  return r;
}
*/

/*
public str remove_comments(str p1) =
  visit(p1){
    case /<pre:[\(\n]*><comment:[\(]([^\)])*[\)]>/:
      insert pre + spaces(size(comment));
  };
*/

/*
private str remove_spaces(str p1){
  str p2 = "";    
  for(str line <- split("\n", p1)){
    p2 = p2 + trim(line) + "\n";
  }
  return p2;
}*/