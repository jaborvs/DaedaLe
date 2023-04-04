module PuzzleScript::Load

import PuzzleScript::Syntax;
import PuzzleScript::AST;
import PuzzleScript::Utils;
import ParseTree;
import List;
import String;
import IO;

PuzzleScript::AST::PSGame load(loc path) {
  str src = readFile(path);
  return load(src);    
}

PuzzleScript::AST::PSGame load(str src) {
  start[PSGame] t = ps_parse(src);
  PuzzleScript::AST::PSGame g = ps_implode(t);
  return g;
}

start[PSGame] ps_parse(loc path){
  str src = readFile(path);
  start[PSGame] t = ps_parse(src);
  //return annotate(parse(#start[PSGame], path));
  return t;
}

/*
start[PSGame] ps_parse_amb(loc path){
  start[PSGame] t = parse(#start[PSGame], path, allowAmbiguity=true);
  //return annotate(parse(#start[PSGame], path));
  return t;
}*/


// parse takes 2 arguments: nonterminal in grammar and string to be parsed
start[PSGame] ps_parse(str src){
  str src2 = src + "\n\n\n";
  return parse(#start[PSGame], src2);
  //return annotate(parse(#start[PSGame], src));
}

start[PSGame] ps_parse(str psString, loc psFile) { 
  str src = readFile(psFile);
  str src2 = src + "\n\n\n";
  return parse(#start[PSGame], src2, psFile);
  //return annotate(parse(#start[PSGame], psString, psFile));
}

PuzzleScript::AST::PSGame ps_implode(start[PSGame] tree) {
  PuzzleScript::AST::PSGame game = implode(#PuzzleScript::AST::PSGame, tree);
  return post(game);
}

start[PSGame] annotate(start[PSGame] t) {
  list[str] colors = [];
  list[str] sound_verbs = sound_keywords + sound_events;

  return visit(t){
    case (Colors)`<Color+ c>`: colors = [toLowerCase(x) | str x <- split(" ", unparse(c))];
    case c: appl(prod(def, symbols, {\tag("category"("Color"))}), args) => appl(prod(def, symbols, {\tag("category"(toLowerCase(unparse(c))))}), args)
    case c: appl(prod(def, symbols, {\tag("category"("SpritePixel"))}), args) => appl(prod(def, symbols, {\tag("category"(to_color(unparse(c), colors)))}), args)
    case c: appl(prod(def, symbols, {\tag("category"("LevelPixel"))}), args) => appl(prod(def, symbols, {\tag("category"(to_trans(unparse(c))))}), args)
    case c: appl(prod(def, symbols, {\tag("category"("SoundID"))}), args): {
      if (toLowerCase(unparse(c)) in sound_verbs){
        insert appl(prod(def, symbols, {\tag("category"("Keyword"))}), args);
      } else if (check_valid_sound(unparse(c))) {
        insert appl(prod(def, symbols, {\tag("category"("SoundSeed"))}), args);
      } else {
        insert appl(prod(def, symbols, {\tag("category"("ObjectName"))}), args);
      }
    }
		
    case c: appl(prod(def, symbols, {\tag("category"("ConditonID"))}), args): {
      if (toLowerCase(unparse(c)) in condition_keywords){
        insert appl(prod(def, symbols, {\tag("category"("Keyword"))}), args);
      } else {
        insert appl(prod(def, symbols, {\tag("category"("ObjectName"))}), args);
      }
    }
		
    case c: appl(prod(def, symbols, {\tag("category"("IDorDirectional"))}), args): {
      if (toLowerCase(unparse(c)) in rulepart_keywords){
        insert appl(prod(def, symbols, {\tag("category"("Keyword"))}), args);
      } else {
        insert appl(prod(def, symbols, {\tag("category"("ObjectName"))}), args);
      }
    }
  }
}

str to_trans(str pixel){
  if (pixel == ".") return "transparent";
  return "LevelPixel";
}

str to_color(str index, list[str] colors){
  if (index == ".") return "transparent";

  try
    int s = toInt(index);
  catch IllegalArgument: return "unknown";
	
  if (s < size(colors)) return colors[s];
	
  return "unknown";
}

LegendData process_legend(LegendData l) {
  str legend = l.legend;
  list[str] values = [l.first];
  list[str] aliases = [];
  list[str] combined = [];
	
  for (LegendOperation other <- l.others) {
    switch(other){
      case legend_or(id): aliases += id;
      case legend_and(id): combined += id;
    }
  }
	
  LegendData new_l = legend_alias(legend, values + aliases);
  if (size(aliases) > 0 && size(combined) > 0) {
    new_l = legend_error(legend, values + aliases + combined);
  } else if (size(combined) > 0) {
    new_l = legend_combined(legend, values + combined);
  }
  new_l.src = l.src;
  new_l @ label = l.legend;
  return new_l;
}

ObjectData process_object(ObjectData obj, int index){
  list[list[Pixel]] sprite_line = [];

  if (size(obj.spr) > 0) {;
    sprite_line += [
      [pixel(x) | x <- split("", obj.spr[0].line0)],
      [pixel(x) | x <- split("", obj.spr[0].line1)],
      [pixel(x) | x <- split("", obj.spr[0].line2)],
      [pixel(x) | x <- split("", obj.spr[0].line3)],
      [pixel(x) | x <- split("", obj.spr[0].line4)]
    ];
		
    for (int i <- [0..size(sprite_line)]){
      for (int j <- [0..size(sprite_line[i])]){
        try
          sprite_line[i][j] @ color = toLowerCase(obj.colors[toInt(sprite_line[i][j].pixel)]);
        catch: sprite_line[i][j] @ color = "unknown";
      }
    }
  }
	
  ObjectData new_obj = object_data(obj.name, obj.legend, obj.colors, sprite_line, index);

  print("Obj = ");
  println(obj);
  new_obj.src = new_obj.src;
  new_obj @ label = obj.name;
  return new_obj;
}

LayerData process_layer(LayerData l) {
  list[str] new_layer = [];
  for (str obj <- l.layer){
    // flexible grammar parses the optional "," separator as a character so we remove it
    // in post processing if it exists
    if (obj[-1] == ",") {
      new_layer += [obj[0..-1]];
    } else {
      new_layer += [obj];
    }
  }

  LayerData new_l = layer_data(new_layer);
  new_l.src = l.src;
  new_l @ label = intercalate(", ", new_layer);
  return new_l;
}

LevelData process_level(LevelData l : message(_)) {
  l @ label = "Message";
  return l;
}

LevelData process_level(LevelData l : level_data_raw(list[tuple[str, str]] lines, str _)) {
  LevelData new_l = level_data([x[0] | x <- lines]);
  new_l.src = l.src;
  new_l @ label = "Level";
  return new_l;
}

default LevelData process_level(LevelData l) {
  return l;
}


PSGame post(PSGame game) {
  // do post processing here
  list[ObjectData] objects = [];
  list[LegendData] legend = [];
  list[SoundData] sounds = [];
  list[LayerData] layers = [];
  list[RuleData] rules = [];
  list[ConditionData] conditions = [];
  list[LevelData] levels = [];
  list[PreludeData] prelude = [];
   
  PSGame game2 = visit(game){
    
    case list[PreludeData] prelude =>
      [p | p <- prelude, !(prelude_empty(_) := p)]
    case list[ObjectData] objects => 
      [obj | obj <- objects, !(object_empty(_) := obj)]      
    case list[Section] sections => 
      [section | section <- sections, !(s_empty(_, _, _, _) := section)]      
    case list[LegendData] legend =>
      [l | l <- legend, !(legend_empty(_) := l)]
    case list[SoundData] sounds =>
      [sound | sound <- sounds, !(sound_empty(_) := sound)]
    case list[LayerData] layers =>
      [layer | layer <- layers, !(layer_empty(_) := layer)]
    case list[RuleData] rules =>
      [rule | rule <- rules, !(rule_empty(_) := rule)]
    case list[ConditionData] conditions =>
      [cond | cond <- conditions, !(condition_empty(_) := cond)]
    case list[LevelData] levels =>
      [level | level <- levels, !(level_empty() := level)]
  };
  	
  // assign to correct section
  visit(game2){
    case Section s: s_objects(_,_,_,_): objects += s.objects;
    case Section s: s_legend(_,_,_,_): legend += s.legend;
    case Section s: s_sounds(_,_,_,_): sounds += s.sounds;
    case Section s: s_layers(_,_,_,_): layers += s.layers;
    case Section s: s_rules(_,_,_,_): rules += s.rules;
    case Section s: s_conditions(_,_,_,_): conditions += s.conditions;
    case Section s: s_levels(_,_,_,_): levels += s.levels;   
  	case PreludeData p: prelude += [p];
  }
	
  //fix sprite
  processed_objects = [];
  int index = 0;
  for (ObjectData obj <- objects){
    if (obj is object_data){
      processed_objects += process_object(obj, index);
        index += 1;
    }
  }
	
  // validate legends and process
  processed_legend = [process_legend(l) | LegendData l <- legend];
		
  //unnest layers
  processed_layers = [process_layer(l) | LayerData l <- layers];
	
  //unest levels
  processed_levels = [process_level(l) | LevelData l <- levels];
	
  if (!isEmpty(game.pr)) pr = game.pr[0].datas;
	
  PSGame new_game = PSGame::game(
    prelude, 
    processed_objects, 
    processed_legend, 
    sounds, 
    processed_layers, 
    rules, 
    conditions, 
    processed_levels, 
    game.sections
  );

  new_game.src = game.src;
	
  return new_game;
}