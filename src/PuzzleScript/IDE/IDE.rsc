module PuzzleScript::IDE::IDE


import salix::App;
import salix::HTML;
import salix::Node;
import salix::Core;
import salix::lib::CodeMirror;
import salix::lib::XTerm;
import salix::lib::Mode;
import salix::lib::REPL;
import salix::lib::Charts;
import salix::lib::UML;
import salix::lib::Dagre;
import util::Maybe;
import ParseTree;
import String;
import List;
import IO; 

import PuzzleScript::Syntax;

SalixApp[IDEModel] ideApp(str id = "PSide") = makeApp(id, init, view, update, parser = parseMsg, debug = true);

App[IDEModel] ideWebApp() 
  = webApp(
      ideApp(),
      |project://AutomatedPuzzleScript/src/PuzzleScript/IDE/index.html|,
      |project://AutomatedPuzzleScript/src|
    ); 

alias IDEModel = tuple[
  str src, 
  Maybe[start[PSGame]] lastParse,
  list[str] output,
  str currentCommand,
  Mode mode, // put it here, so not regenerated at every click..
  REPLModel repl
];
  
Maybe[start[PSGame]] maybeParse(str src) {
  try {
    return just(parse(#start[PSGame], src));
  }
  catch ParseError(loc _): {
    return nothing();
  }
}

loc fileLoc = |project://AutomatedPuzzleScript/src/PuzzleScript/IDE/Game1.PS|;
str puzzle() = readFile(fileLoc);

data Msg
  = stmChange(int fromLine, int fromCol, int toLine, int toCol, str text, str removed)
  | replMsg(Msg msg)
  | noOp()
  ;   
  
Maybe[str] stmHighlight(str x) {
  println(x);
  
  return nothing();
}

tuple[Msg, str] myEval(str command) {
  return <noOp(), "nothingness">;
}

str updateSrc(str src, int fromLine, int fromCol, int _, int _, str text, str removed) {
  list[str] lines = mySplit("\n", src);
  int from = ( 0 | it + size(l) + 1 | str l <- lines[..fromLine] ) + fromCol;
  int to = from + size(removed);
  str newSrc = src[..from] + text + src[to..];
  return newSrc;  
}

list[str] mySplit(str sep, str s) {
  if (/^<before:.*?><sep>/m := s) {
    return [before] + mySplit(sep, s[size(before) + size(sep)..]);
  }
  return [s];
}


IDEModel init() {
	replModel = mapCmds(replMsg, REPLModel() { return initRepl("myXterm", "$ "); });
	Mode stmMode = grammar2mode("game", #PSGame);
	IDEModel model = <"", nothing(), [], "", stmMode, replModel>;

	model.src = puzzle();
	model.lastParse = maybeParse(model.src);
	
	return model;
}

IDEModel update(Msg msg, IDEModel model) {	
	switch (msg) {
		case stmChange(int fromLine, int fromCol, int toLine, int toCol, str text, str removed): {
			model.src = updateSrc(model.src, fromLine, fromCol, toLine, toCol, text, removed);
			if (just(start[PSGame] game) := maybeParse(model.src)) {
        		model.lastParse = just(game);
        		writeFile(fileLoc, model.src);
        	}
		}
	
		//case replMsg(Msg sub): 
  //    		model.repl = mapCmds(replMsg, sub, model.repl, replUpdate(myEval, myComplete, stmHighlight));
	}
	
	return model;
}

IDEModel update(Msg msg, IDEModel model) {
 // 	switch (msg) {
	//	
	//}
	
	return model;
}

void view(IDEModel model) {
	div(() {
		h2("PuzzleScript IDE");
		codeMirrorWithMode("myCodeMirror", model.mode, onChange(stmChange), height(800), 
            mode("statemachine"), indentWithTabs(false), lineNumbers(true), \value(model.src));
	});
}
