module PuzzleScript::Checker

import PuzzleScript::AST;
import util::Math;
import List;
import String;
import IO;
import Type;
import PuzzleScript::Messages;

alias Checker = tuple[
	list[Msg] msgs,
	bool debug_flag,
	map[str, list[str]] references,
	list[str] objects,
	map[str, list[str]] combinations,
	list[str] layer_list,
	map[str, list[int]] sound_events,
	list[Condition] conditions,
	map[str, str] prelude,
	PSGAME game
];

alias Reference = tuple[
	list[str] objs, 
	Checker c
];

data Condition
	= some_objects(list[str] objects)
	| no_objects(list[str] objects)
	| all_objects_on(list[str] objects, list[str] on)
	| some_objects_on(list[str] objects, list[str] on)
	| no_objects_on(list[str] objects, list[str] on)
	;

map[str, str] COLORS = (
	"black"   		: "#000000",
	"white"			: "#FFFFFF",
	"grey"			: "#555555",
	"darkgrey"		: "#555500",
	"lightgrey"		: "#AAAAAA",
	"gray"			: "#555555",
	"darkgray"		: "#555500",
	"lightgray"		: "#AAAAAA",
	"red"			: "#FF0000",
	"darkred"		: "#AA0000",
	"lightred"		: "#FF5555",
	"brown"			: "#AA5500",
	"darkbrown"		: "#550000",
	"lightbrown"	: "#FFAA00",
	"orange"		: "#FF5500",
	"yellow" 		: "#FFFF55",
	"green"			: "#55AA00",
	"darkgreen"		: "#005500",
	"lightgreen"	: "#AAFF00",
	"blue"			: "#5555AA",
	"lightblue"		: "#AAFFFF",
	"darkblue"		: "#000055",
	"purple"		: "#550055",
	"pink"			: "#FFAAFF"
);

str default_mask = "@None@";

list[str] directional_sound_masks = ["move", "cantmove"];
list[str] sound_masks = ["create", "destroy", "action"] + directional_sound_masks;
list[str] directional_keywords = ["left", "right", "down", "up"];

list[str] sound_keywords = sound_masks + directional_keywords; 

list[str] conditions = ["all", "some", "no", "any"];
list[str] condition_keywords = conditions + ["on"];

list[str] rulepart_keywords = [
	"^","v","\>","\<", "...",
	"moving","stationary","parallel","perpendicular","action",
	"horizontal", "vertical"
];
list[str] rulepart_random = ["randomdir","random"];
list[str] rule_prefix = ["late", "random", "rigid"] + directional_keywords;
list[str] rule_commands = ["cancel", "checkpoint", "restart", "win"];

list[str] rule_keywords = rulepart_keywords + rule_prefix + rule_commands + rulepart_random;


list[str] section_headers = [
	"objects", "collisionlayers", "legend", "sounds", "rules",
	"winconditions", "levels"
];

list[str] sound_events = [
	"titlescreen", "startgame", "cancel", "endgame", "startlevel", "undo", "restart", 
	"endlevel", "showmessage", "closemessage", 
	"sfx0", "sfx1", "sfx2", "sfx3", "sfx4", "sfx5", "sfx6", "sfx7", "sfx8", "sfx9", "sfx10"
];

list[str] prelude_with_arguments_str_dim = ["flickscreen","zoomscreen"];

list[str] prelude_with_arguments_str_color = ["background_color","text_color"];

list[str] prelude_with_arguments_str = [
	"title","author","homepage", "color_palette","youtube"
] + prelude_with_arguments_str_color + prelude_with_arguments_str_dim;

list[str] prelude_with_arguments_int = [
	"key_repeat_interval", "realtime_interval","again_interval"
];

list[str] prelude_with_arguments = prelude_with_arguments_str + prelude_with_arguments_int;

list[str] prelude_without_arguments = [
	"run_rules_on_level_start","norepeat_action","require_player_movement","debug",
	"verbose_logging","throttle_movement","noundo","noaction","norestart","scanline"
];

list[str] prelude = prelude_with_arguments + prelude_without_arguments; 

list[str] keywords = 
	directional_keywords + 
	condition_keywords + 
	sound_keywords +
	prelude +
	sound_events +
	rule_keywords +
	section_headers +
	["message"]
;

		
Checker new_checker(bool debug_flag, PSGAME game){		
	return <[], debug_flag, (), [], (), [], (), [], (), game>;
}

//get a value from the prelude if it exists, else return the default
str get_prelude(list[PRELUDEDATA] values, str key, str default_str){
	v = [x | x <- values, toLowerCase(x.key) == toLowerCase(key)];
	if (size(v) > 0) return v[0].string;
	
	return default_str;
}

bool check_valid_name(str name){
	return /^<x:[a-z]+>$/i := name && !(toLowerCase(name) in keywords);
}

bool check_valid_legend(str name){
	if (size(name) > 1){
		return check_valid_name(name);
	} else {
		return /^<x:[a-z.!@#$%&*]+>$/i := name && !(toLowerCase(name) in keywords);
	}
}

list[Msg] check_existing_legend(str name, list[str] values, loc pos, Checker c){
	list[Msg] msgs = [];

	if (toLowerCase(name) in c.references) msgs += [existing_legend(name, c.references[toLowerCase(name)], values, error(), pos)];
	if (toLowerCase(name) in c.combinations) msgs += [existing_legend(name, c.combinations[toLowerCase(name)], values, error(), pos)];
	
	return msgs;
}

list[Msg] check_undefined_object(str name, loc pos, Checker c){
	list[Msg] msgs = [];
	
	if (!(toLowerCase(name) in c.objects)){
		if (size(check_existing_legend(name, [], pos, c)) == 0) msgs += [undefined_object(name, error(), pos)];
	}

	return msgs;
}

Reference resolve_reference(str raw_name, Checker c, loc pos, list[str] allowed=["objects", "properties", "combinations"]){
	Reference r;
	
	list[str] objs = [];	
	str name = toLowerCase(raw_name);
	
	if (name in c.references && c.references[name] == [name]) return <[name], c>;
	
	if (name in c.combinations) {
		if ("combinations" in allowed) {
			for (str n <- c.combinations[name]) {
				r = resolve_reference(n, c, pos);
				objs += r.objs;
				c = r.c;
			}
		} else {
			c.msgs += [invalid_object_type("combinations", name, error(), pos)];
		}
	} else if (name in c.references) {
		if ("properties" in allowed) {
			for (str n <- c.references[name]) {
				r = resolve_reference(n, c, pos);
				objs += r.objs;
				c = r.c;
			}
		} else {
			c.msgs += [invalid_object_type("properties", name, error(), pos)];
		}
	} else {
		c.msgs += [undefined_object(raw_name, error(), pos)];
	}
	
	return <dup(objs), c>;
}

Reference resolve_references(list[str] names, Checker c, loc pos, list[str] allowed=["objects", "properties", "combinations"]) {
	list[str] objs = [];
	Reference r;
	
	for (str name <- names) {
		r = resolve_reference(name, c, pos, allowed=allowed);
		objs += r.objs;
		c = r.c;
	}
	
	return <dup(objs), c>;
}

bool check_valid_sound(str sound){
	try
		int s = toInt(sound);
	catch IllegalArgument: return false;
	return s > 0;
}

bool check_valid_real(str v) {
	try
		real i = toReal(v);
	catch IllegalArgument: return false;
	
	return i > 0;
}

// errors
//	invalid_prelud_key
//	existing_prelude_key
//	missing_prelude_value
//	invalid_prelude_value
// warnings
Checker check_prelude(PRELUDEDATA pr, Checker c){
	str key = toLowerCase(pr.key);
	if (!(key in prelude)){
		c.msgs += [invalid_prelude_key(pr.key, error(), pr@location)];
		return c;
	}
	
	if (key in c.prelude){
		c.msgs += [existing_prelude_key(pr.key, error(), pr@location)];
	}
	
	if (key in prelude_without_arguments){
		if (pr.string != "") c.msgs += [redundant_prelude_value(pr.key, warn(), pr@location)];
		c.prelude[key] = "None";
	} else {
		if (pr.string == ""){
			c.msgs += [missing_prelude_value(pr.key, error(), pr@location)];
			return c;
		}
		if (key in prelude_with_arguments_int) {
			if (!(check_valid_real(pr.string))) c.msgs += [invalid_prelude_value(key, pr.string, "real", error(), pr@location)];
			c.prelude[key] = pr.string;
		} else {
			if (key in prelude_with_arguments_str_dim) {
				if (!(/[0-9]+x[0-9]+/i := pr.string)) c.msgs += [invalid_prelude_value(key, pr.string, "height code", error(), pr@location)];
				c.prelude[key] = pr.string;
			} else if (key in prelude_with_arguments_str_color) {
				// complicated to validate since it can be both an hex code or a color name
				// so for now we do nothing
				c.prelude[key] = pr.string;
			} else {
				c.prelude[key] = pr.string;
			}
		}
	}

	return c;
}

// errors
//	invalid_name
//	existing_object
//	existing_legend
//	invalid_color
//	invalid_sprite
//  invalid_index
// warnings
//	unused_colors
Checker check_object(OBJECTDATA obj, Checker c) {
	int max_index = 0;
	str id = toLowerCase(obj.id);	
	
	if (!check_valid_name(id)) c.msgs += [invalid_name(id, error(), obj@location)];

	// check for duplicate object names
	if (id in c.objects) {
		c.msgs += [existing_object(obj.id, error(), obj@location)];
	} else {
		c.objects += [id];
	}
	
	// add references
	c.references[id] = [id];
	if (size(obj.legend) > 0) {
		msgs = check_existing_legend(obj.legend[0], [obj.id], obj@location, c);
		if (size(msgs) > 0){
			c.msgs += msgs;
		} else {
			c.references[toLowerCase(obj.legend[0])] = [id];
		}
	}
	
	//check colors (only default mastersystem palette supported currently)
	for (str color <- obj.colors) {
		if (toLowerCase(color) in COLORS) continue;
		
		c.msgs += [invalid_color(obj.id, color, error(), obj@location)];
	}

	// check if it has a sprite
	if (size(obj.sprite) == 0) return c;
	for(str line <- obj.sprite[0]){
		list[str] char_list = split("", line);
		
		// check if the sprite is of valid length
		if (size(char_list) != 5) c.msgs += [invalid_sprite(obj.id, line, error(), obj@location)];
	
		// check if all pixels have the correct index
		for(str pixel <- char_list){
			if (pixel == ".") continue;
			
			int converted = toInt(pixel);
			if (converted + 1 > size(obj.colors)) {
				c.msgs += [invalid_index(obj.id, converted, error(), obj@location)];
			} else if (converted > max_index) max_index = converted;
		}
	}
	
	// check if we are making use of all the colors defined
	if (size(obj.colors) > max_index + 1) {
		c.msgs += [unused_colors(obj.id, intercalate(", ", obj.colors[max_index+1..-1]), warn(), obj@location)];
	}
	
	return c;
}

// errors
//	existing_legend
// 	undefined_object
//	mixed_legend ('and' and 'or')
//	mixed_legend (alias and cominations)
//  invalid_name
// warnings
//  self_reference
//  
Checker check_legend(LEGENDDATA l, Checker c) {
	if (!check_valid_legend(l.legend)) c.msgs += [invalid_name(l.legend, error(), l@location)];
	c.msgs += check_existing_legend(l.legend, l.values, l@location, c);
	
	Reference r = resolve_references(l.values, c, l@location);
	list[str] values = r[0];
	c = r[1];
	
	str legend = toLowerCase(l.legend);
	
	if (check_valid_name(l.legend)) c.objects += [legend];
	for (str v <- values){
		if (!(v in c.objects)) c.msgs += [undefined_object(v, error(), l@location)];
	}
	
	// if it's just one thing being defined with check it and return
	if (size(values) == 1) {
		msgs = check_undefined_object(l.values[0], l@location, c);
		if (size(msgs) > 0) {
			c.msgs += msgs;
		} else {
			// check if it's a self definition and warn as need be
			if (legend == values[0]){
				c.msgs += [self_reference(l.legend, warn(), l@location)];
			} else {
				c.references[legend] = values;
			}
		}
		
		return c;
	}
	
	// if not we do a more expensive check for invalid legend and mixed types
	switch(l) {
		case legend_alias(_, _): {
			// if our alias makes use of combinations that's a bonk
			list[str] mixed = [x | x <- values, x in c.combinations];
			if (size(mixed) > 0) {
				c.msgs += [mixed_legend(l.legend, mixed, "alias", "combination", error(), l@location)];
			} else {
				c.references[legend] = values;
			}
		}
		case legend_combined(_, _): {
			// if our combination makes use of aliases that's a bonk (just gotta make sure it's actually an alias)
			list[str] mixed = [x | x <- values, x in c.references && size(c.references[x]) > 1];
			if (size(mixed) > 0) {
				c.msgs += [mixed_legend(l.legend, mixed, "combination", "alias", error(), l@location)];
			} else {
				c.combinations[legend] = values;
			}
		}
		case legend_error(_, _): c.msgs += [mixed_legend(l.legend, l.values, error(), l@location)];	
	}

	return c;
}

// errors
//	invalid_sound
//	invalid_sound_length
//	existing_sound_object
//	existing_mask
//	existing_sound_seed
//  mask_not_directional
//	invalid_sound_verb
// 	undefined_sound_object
// 	undefined_sound_mask
// 	undefined_sound_seed
// warnings
//	existing_sound
Checker check_sound(SOUNDDATA s, Checker c){
	int seed;
	
	if (size(s.sound) == 2 && toLowerCase(s.sound[0]) in sound_events) {
		if (!check_valid_sound(s.sound[1])) {
			c.msgs += [invalid_sound_seed(s.sound[1], error(), s@location)];
			seed = -1;
		} else {
			seed = toInt(s.sound[1]);
		}
		
		if (toLowerCase(s.sound[0]) in c.sound_events) {
			c.msgs += [existing_sound(s.sound[0], warn(), s@location)];
			c.sound_events[toLowerCase(s.sound[0])] += [seed];
		} else {
			c.sound_events[toLowerCase(s.sound[0])] = [seed];
		}
		
		return c;
	} else if (size(s.sound) < 3) {
		c.msgs += [invalid_sound_length(error(), s@location)];
		return c;
	}
	
	list[str] objects = [];
	str mask = default_mask;
	seed = -1;
	list[str] directions = [];
	
	for (str verb <- s.sound) {
		str v = toLowerCase(verb);
		if (v in c.objects) {
			if (size(objects) == 0) {
				Reference r = resolve_reference(verb, c, s@location);
				c = r.c;
				objects = r.objs;
			} else {
				c.msgs += [existing_sound_object(error, s@location)];
			}
		} else if (v in sound_masks) {
			if (mask == default_mask) {
				mask = v;
			} else {
				c.msgs += [existing_mask(v, mask, error(), s@location)];
			}
			
		} else if (v in directional_keywords){
			if (!(mask in directional_sound_masks)) {
				c.msgs += [mask_not_directional(mask, error(), s@location)];
			} else {
				directions += [v];
			}
		} else if (check_valid_sound(v)) {
			if (seed != -1){
				c.msgs += [existing_sound_seed(toString(seed), v, error(), s@location)];
			} else {
				seed = toInt(v);
			}
		} else {
			c.msgs += [invalid_sound_verb(verb, error(), s@location)];
		}
	}
	
	if (size(objects) < 1) c.msgs += [undefined_sound_objects(error(), s@location)];
	if (mask == default_mask) c.msgs += [undefined_sound_mask(error(), s@location)];
	if (seed < 0) c.msgs += [undefined_sound_seed(error(), s@location)];
	
	//object_mask_direction
	for (str obj <- objects){
		list[str] events = [];
		if (mask in directional_sound_masks && size(directions) > 0){
			for (str dir <- directions){
				events += ["<obj>_<mask>_<dir>"];
			}
		} else {
			events += ["<obj>_<mask>"];
		}
		
		for (str e <- events){
			if (e in c.sound_events) {
				c.msgs += [existing_sound(e, warn(), s@location)];
				c.sound_events[e] += [seed];
			} else {
				c.sound_events[e] = [seed];
			}
		}
	}
	
	return c;
}

// errors
//	undefined_object
Checker check_layer(LAYERDATA l, Checker c){
	Reference r = resolve_references(l.layer, c, l@location);
	c = r.c;
	c.layer_list += r.objs;
	
	return c;
}

Checker check_ruleparts(list[RULEPART] part, Checker c) {
	for (RULEPART part <- part) {
		switch(part) {
			case RULEPART::part(list[RULECONTENT] contents): {
				for (RULECONTENT cont <- contents) {
					for (str v <- cont.content) {
						if (!(toLowerCase(v) in rulepart_keywords)) {
							Reference r = resolve_reference(v, c, part@location);
							c = r.c;
						}
					}
					
					if ("..." in cont.content && cont.content != ["..."]) c.msgs += [invalid_ellipsis(error(), part@location)];
				}
				
				if (contents[0].content == ["..."] && contents[-1].content == ["..."]) c.msgs += [invalid_ellipsis_placement(error(), part@location)];
			}
			case RULEPART::command(str command): {
				if (!(toLowerCase(command) in rule_commands)) c.msgs += [invalid_rule_command(command, error(), part@location)];
			}
			case RULEPART::sound(str sound): {
				if (/'sfx'[0-9]|'10'/ := sound && toLowerCase(sound) in c.sound_events) {
					sound;
				} else if (/'sfx'[0-9]|'10'/ := sound) {
					//correct format but undefined
					c.msgs += [undefined_sound(sound, error, part@location)];
				} else {
					//wrong format
					c.msgs += [invalid_sound(sound, error, part@location)];
				}
			}
		}
	}
	
	return c;
}

// errors
//	invalid_rule_prefix
//	invalid_rule_command
//	undefined_sound
//	undefined_object
//	invalid_sound
Checker check_rule(RULEDATA r, Checker c){

	// check left side
	if (size(r.prefix) > 0){
		if (!(toLowerCase(r.prefix[0]) in rule_prefix)) c.msgs += [invalid_rule_prefix(r.prefix[0], error(), r@location)];
	}
	
	int msgs = size(c.msgs);
	c = check_ruleparts(r.right, c);
	c = check_ruleparts(r.left, c);
	
	// if some of the rule is invalid it gets complicated to do more checks, so we return it 
	// for now until they fixed the rest
	if (size(c.msgs) > msgs) return c;
	
	//check if there are equal amounts of parts on both sides
	if (size(r.right) != size([x | RULEPART x <- r.left, typeOf(x) == typeOf(part([]))])) c.msgs += [invalid_rule_part_size(error(), r@location)];
	
	//check if each part, and its equivalent have the same number of sections
	for (int i <- [0..size(r.left)]){
		if (size(r.left[i].contents) != size(r.right[i].contents)) {
			c.msgs += [invalid_rule_content_size(error(), r@location)];
			continue;
		}
		
		//check if the equivalent of any part with an ellipsis also has one
		for (int j <- [0..size(r.left[i].contents)]){
			list[str] left = r.left[i].contents[j].content;
			list[str] right = r.right[i].contents[j].content;
			
			if (left == ["..."] && right != ["..."]) invalid_rule_ellipsis_size(error(), r@location);
			if (right == ["..."] && left != ["..."]) invalid_rule_ellipsis_size(error(), r@location);
			
		}
	}
	
	return c;
}

// errors
//	invalid_condition_length
//	undefined_object
//	invalid_condition
//	invalid_condition_verb
// 	impossible_condition_unstackable
//	impossible_condition_duplicates
// warnings
Checker check_condition(CONDITIONDATA w, Checker c){
	if (!(size(w.condition) in [2, 4])){
		c.msgs += [invalid_condition_length(error(), w@location)];
		return c;
	}
	
	bool has_on = size(w.condition) == 4;
	Reference r = resolve_reference(w.condition[1], c, w@location);
	list[str] objs = r.objs;
	c = r.c; 
	
	list[str] on = [];
	if (has_on) {
		Reference r = resolve_reference(w.condition[3], c, w@location);
		on = r.objs;
		c = r.c; 
	}
	
	for (str obj <- objs + on) {
		if (toLowerCase(obj) in c.combinations) c.msgs += [invalid_object_type("combinations", obj, error(), w@location)];
	}
	
	
	list[str] dupes = [x | str x <- objs, x in on];
	if (size(dupes) > 0){
		c.msgs += [impossible_condition_duplicates(dupes, error(), w@location)];
	}
	
	for (LAYERDATA l <- c.game.layers){
		list[str] mixed = [x | str x <- l.layer, toLowerCase(x) in objs && toLowerCase(x) in on];
		if (size(mixed) > 0){
			c.msgs += [impossible_condition_unstackable(mixed, error(), w@location)];
		}
	}
	
	switch(toLowerCase(w.condition[0])) {
		case /all/: {
			if (has_on) {
				c.conditions += [all_objects_on(objs, on)];
			} else {
				c.msgs += [invalid_condition(error(), w@location)];
			}
		}
		case /some|any/: {
			if (has_on) {
				c.conditions += [some_objects_on(objs, on)];
			} else {
				c.conditions += [some_objects(objs)];
			}
		}
		case /no/: {
			if (has_on) {
				c.conditions += [no_objects_on(objs, on)];
			} else {
				c.conditions += [no_objects(objs)];
			}
		}
		
		default: c.msgs += invalid_condition_verb(w.condition[0], error(), w@location);
	}
	
	return c;
}

//errors
//	invalid_level_row
//	invalid_name
//	ambiguous pixel
//	unefined_object
//warnings
//	message_too_long
Checker check_level(LEVELDATA l, Checker c){
	switch(l) {
		case message(str msg): if (size(msg) > 12) c.msgs += [message_too_long(warn(), l@location)];
		case level_data(_): {
			int length = size(l.level[0]);
			bool invalid = false;
			
			for (str line <- l.level){
				if (size(line) != length) invalid = true;
				
				list[str] char_list = split("", line);
				for (str legend <- char_list) {
					Reference r = resolve_reference(legend, c, l@location);
					c = r.c;
					
					if (toLowerCase(legend) in c.references && size(r.objs) > 1) {
						c.msgs += [ambiguous_pixel(legend, r.objs, error(), l@location)];
					}
					
				}
			}
			if (invalid) c.msgs += [invalid_level_row(error(), l@location)];
		}
	}

	return c;
}

// errors
//	existing_section
//	unlayered_objects
// warning
//	no_levels
Checker check_game(PSGAME g, bool debug=false) {
	Checker c = new_checker(debug, g);
	
	map[SECTION, int] dupes = distribution(g.sections);
	for (SECTION s <- dupes) {
		if (dupes[s] > 1) c.msgs += [existing_section(s, dupes[s], error(), s@location)];
	}
	
	for (PRELUDEDATA pr <- g.prelude){
		c = check_prelude(pr, c);
	}
	
	for (OBJECTDATA obj <- g.objects){
		c = check_object(obj, c);
	}
	
	for (LEGENDDATA l <- g.legend){
		c = check_legend(l, c);
	}
	
	for (SOUNDDATA s <- g.sounds) {
		c = check_sound(s, c);
	}
	
	for (LAYERDATA l <- g.layers) {
		c = check_layer(l, c);
	}
	
	list[str] unlayered = [x.id | OBJECTDATA x <- g.objects, !(toLowerCase(x.id) in c.layer_list)];
	if (size(unlayered) > 0) {
		c.msgs += [unlayered_objects(intercalate(", ", unlayered), error(), g@location)];
	}
	
	for (RULEDATA r <- g.rules) {
		c = check_rule(r, c);
	}
	
	for (CONDITIONDATA w <- g.conditions) {
		c = check_condition(w, c);
	}
	
	for (LEVELDATA l <- g.levels) {
		c = check_level(l, c);
	}
	
	if (size(g.levels) == 0) c.msgs += no_levels(warn(), g@location);
	
	return c;
}

void print_msgs(Checker checker){
	list[Msg] error_list = [x | Msg x <- checker.msgs, x.t == error()];
	list[Msg] warn_list  = [x | Msg x <- checker.msgs, x.t == warn()];
	list[Msg] info_list  = [x | Msg x <- checker.msgs, x.t == info()];
	
	if (size(error_list) > 0) {
		println("ERRORS");
		for (Msg msg <- error_list) {
			print(msg);
			println();
		}
	}
	
	if (size(warn_list) > 0) {
		println("WARNINGS");
		for (Msg msg <- warn_list) {
			print(msg);
			println();
		}
	}
	
	if (size(info_list) > 0) {
		println("INFO");
		for (Msg msg <- info_list) {
			print(msg);
			println();
		}
	}
}
