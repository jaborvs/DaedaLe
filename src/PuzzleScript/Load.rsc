module PuzzleScript::Load

import PuzzleScript::Syntax;
import PuzzleScript::AST;
import ParseTree;
import IO;

PSGAME load(loc path) {
	return implode(parse(path));
}

PSGame parse(loc path){
	return annotate(parse(#PSGame, path));
}

PSGAME load(str src) {
	return implode(parse(src));
}

PSGame parse(str src){
	return annotate(parse(#PSGame, src));
}

PSGAME implode(PSGame tree) {
	return post(implode(#PSGAME, tree));
}

PSGame annotate(PSGame tree) {
	// annotate tree
	
	return tree;
}

PSGAME check(PSGAME game) {
	// check contents, return error message etc...
	
	return game;

}

LEGENDDATA process_legend(LEGENDDATA l) {
	legend = l.legend;
	values = [l.first];
	aliases = [];
	combined = [];
	
	for (LEGENDOPERATION other <- l.others) {
		switch(other){
			case legend_or(id): aliases += id;
			case legend_and(id): combined += id;
		}
	}
	
	LEGENDDATA new_l = legend_alias(legend, values + aliases);
	if (size(aliases) > 0 && size(combined) > 0) {
		new_l = legend_error(legend, values + aliases + combined);
	} else if (size(combined) > 0) {
		new_l = legend_combined(legend, values + combined);
	}
	
	return new_l[@location = l@location];
}

OBJECTDATA process_object(OBJECTDATA obj){
	list[list[str]] sprite_line = [];
	
	if (size(obj.spr) > 0) {;
		sprite_line += [[
			obj.spr[0].line0,
			obj.spr[0].line1,
			obj.spr[0].line2,
			obj.spr[0].line3,
			obj.spr[0].line4
		]];
	}
	
	OBJECTDATA new_obj = object_data(obj.id, obj.legend, obj.colors, sprite_line);
	return new_obj[@location = obj@location];
}

LAYERDATA process_layer(LAYERDATA l) {
	LAYERDATA new_l = layer_data(l.layer);
	return new_l[@location = l@location];
}

PSGAME post(PSGAME game) {
	// do post processing here
	list[OBJECTDATA] objects = [];
	list[LEGENDDATA] legends = [];
	list[tuple[SOUNDDATA sound, str lines]] sounds = [];
	list[LAYERDATA] layers = [];
	list[RULEDATA] rules = [];
	list[CONDITIONDATA] conditions = [];
	list[LEVELDATA] levels = [];
	
	// assign to correct section
	for (SECTION section <- game.sections) {
		switch(section) {
			case SECTION::objects(objs): objects = objs.objects;
			case SECTION::legend(lgd): legends = lgd.legend;
			case SECTION::sounds(snd): sounds = snd.sounds;
			case SECTION::layers(lyrs): layers = lyrs.layers;
			case SECTION::rules(rls): rules = rls.rules;
			case SECTION::conditions(cnd): conditions = cnd.conditions;
			case SECTION::levels(lvl): levels = lvl.levels;
		
		}
	}
	
	//fix sprite
	processed_objects = [];
	for (OBJECTDATA obj <- objects){
		switch(obj){
			case object_data(_, _, _, _, _, _): 
				processed_objects += process_object(obj);
		}
	}
	
	// validate legends and process
	processed_legends = [process_legend(l) | LEGENDDATA l <- legends];
	
	//untuple sounds
	processed_sounds = [s.sound | tuple[SOUNDDATA sound, str lines] s <- sounds];
	
	//unnest layers
	processed_layers = [process_layer(l) | LAYERDATA l <- layers];
	
	return PSGAME::game(
		game.prelude, 
		processed_objects, 
		processed_legends, 
		processed_sounds, 
		processed_layers, 
		rules, 
		conditions, 
		levels, 
		game.sections
	);
}