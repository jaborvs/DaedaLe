module PuzzleScript::IDE::IDE

import PuzzleScript::Load;
import PuzzleScript::AST;
import PuzzleScript::Checker;
import PuzzleScript::Messages;
import util::IDE;
import vis::Figure;
import ParseTree;
import String;

anno str node@label;
anno loc node@\loc;

private str PS_NAME = "PuzzeScript";
private str PS_EXT = "PS";

public Tree ps_check(Tree tree){
	PSGAME g = ps_implode(tree);
	Checker c = check_game(g);
	
	return tree[@messages = toMessages(c.msgs)];
}

loc localize(str section, loc default_loc, list[SECTION] sections){
	for (SECTION sect <- sections){
		switch(sect) {
			case SECTION::objects(_): if (section == "objects") return sect@location;
			case SECTION::legend(_): if (section == "legend") return sect@location;
			case SECTION::sounds(_): if (section == "sounds") return sect@location;
			case SECTION::layers(_): if (section == "layers") return sect@location;
			case SECTION::rules(_): if (section == "rules") return sect@location;
			case SECTION::conditions(_): if (section == "conditions") return sect@location;
			case SECTION::levels(_): levels = if (section == "levels") return sect@location;
			case SECTION::empty(_, name, _, _): if (section == toLowerCase(name)) return sect@location;
			default: return default_loc;
		}
	}
	
	return default_loc;
}

public node ps_outline(Tree x){
	PSGAME g = implode(#PSGAME, x);
	
	loc pr_loc;
	if (isEmpty(g.pr)) {
		pr_loc = g@location;
	} else {
		pr_loc = g.pr[0]@location;
	}
	
	g = post(g);
	
	n = "Game";
	list[node] levels = [l@label()[@\loc = l@location] | LEVELDATA l <- g.levels];
	list[node] prelude = [pr.key()[@\loc = pr@location] | PRELUDEDATA pr <- g.prelude]; 
	list[node] objects = [obj.id()[@\loc = obj@location] | OBJECTDATA obj <- g.objects];
	list[node] legends = [l.legend()[@\loc = l@location] | LEGENDDATA l <- g.legend];
	list[node] sounds = ["Sound"()[@\loc = s@location] | SOUNDDATA s <- g.sounds];
	list[node] layers = [intercalate(", ", l.layer)()[@\loc = l@location] | LAYERDATA l <- g.layers];
	list[node] rules = ["Rule"()[@\loc = r@location] | RULEDATA r <- g.rules];	
	list[node] conditions = [c.condition[0]()[@\loc = c@location] | CONDITIONDATA c <- g.conditions];
		
	return n(
		"Prelude"(prelude)[@label="Prelude (<size(prelude)>)"][@\loc = pr_loc],
		"Object"(objects)[@label="Objects (<size(objects)>)"][@\loc = localize("objects", g@location, g.sections)],
		"Legends"(legends)[@label="Legends (<size(legends)>)"][@\loc = localize("legend", g@location, g.sections)],
		"Sounds"(sounds)[@label="Sounds (<size(sounds)>)"][@\loc = localize("sounds", g@location, g.sections)],
		"Layers"(layers)[@label="Layers (<size(layers)>)"][@\loc = localize("layers", g@location, g.sections)],
		"Rules"(rules)[@label="Rules (<size(rules)>)"][@\loc = localize("rules", g@location, g.sections)],
		"Conditions"(conditions)[@label="Conditions (<size(conditions)>)"][@\loc = localize("conditions", g@location, g.sections)],
		"Levels"(levels)[@label="Levels (<size(levels)>)"][@\loc = localize("levels", g@location, g.sections)]
	);
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