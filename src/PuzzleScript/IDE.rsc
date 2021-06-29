module PuzzleScript::IDE

import util::IDE;
import PuzzleScript::Syntax;

import ParseTree;
import IO;
import Message;
import vis::Figure;

public str PS_NAME = "PuzzleScript";  //language name
public str PS_EXT  = "PS" ;           //file extension

public start[PSGame] PS_parse(str src) = 
  parse(#start[PSGame], src);

public start[PSGame] PS_parse(str src, loc file) = 
  parse(#start[PSGame], src, file);
  
public start[PSGame] PS_parse(loc file) =
 parse(#start[PSGame], file);

public void PS_register(){
	Contribution PS_style =
    categories
    (
      (
        "Comment": {foregroundColor(color("dimgray")),bold()},
        "String" : {foregroundColor(color("mediumblue")),bold()},
        "ID" : {foregroundColor(color("red")),bold()}
      )
    );
    
    PS_contributions = {PS_style};
    
  	registerLanguage(PS_NAME, PS_EXT, PS_parse);
    registerContributions(PS_NAME, PS_contributions);
}
