module PuzzleScript::IDE::IDE

import PuzzleScript::Load;
import PuzzleScript::AST;
import PuzzleScript::Checker;
import PuzzleScript::Messages;
import util::IDE;
import vis::Figure;
import ParseTree;

private str PS_NAME = "PuzzeScript";
private str PS_EXT = "PS";

public Tree ps_check(Tree tree){
	PSGAME g = ps_implode(tree);
	Checker c = check_game(g);
	
	return tree[@messages = toMessages(c.msgs)];
}

public node ps_outline(Tree x){
	PSGAME g = ps_implode(x);
	
	return g;
}

public void registerPS(){
   
  c =
  {
    categories
    (
      (
        "Comment": {foregroundColor(color("dimgray"))},
		"Key": {foregroundColor(color("purple"))},

        "unknown" : {foregroundColor(color("firebrick"))},
        "black": {foregroundColor(color("black"))},     
		"white": {foregroundColor(color("white"))},     
		"grey": {foregroundColor(color("grey"))},      
		"darkgrey": {foregroundColor(color("darkgrey"))},  
		"lightgrey": {foregroundColor(color("lightgrey"))}, 
		"gray": {foregroundColor(color("grey"))},      
		"darkgray": {foregroundColor(color("darkgrey"))},  
		"lightgray": {foregroundColor(color("lightgrey"))}, 
		"red": {foregroundColor(color("red"))},       
		"darkred": {foregroundColor(color("darkred"))},   
		"lightred": {foregroundColor(color("mediumvioletred"))},  
		"brown": {foregroundColor(color("brown"))},     
		"darkbrown": {foregroundColor(color("saddlebrown"))}, 
		"lightbrown": {foregroundColor(color("rosybrown"))},
		"orange": {foregroundColor(color("orange"))},    
		"yellow": {foregroundColor(color("yellow"))},    
		"green": {foregroundColor(color("green"))},     
		"darkgreen": {foregroundColor(color("darkgreen"))}, 
		"lightgreen": {foregroundColor(color("lightgreen"))},
		"blue": {foregroundColor(color("blue"))},      
		"lightblue": {foregroundColor(color("lightblue"))}, 
		"darkblue": {foregroundColor(color("darkblue"))},  
		"purple": {foregroundColor(color("purple"))},    
		"pink": {foregroundColor(color("pink"))}
        
      )
    )
  };
    
  registerLanguage(PS_NAME, PS_EXT, ps_parse);
  registerAnnotator(PS_NAME, ps_check);
  registerOutliner(PS_NAME, ps_outline);
  registerContributions(PS_NAME, c);
}