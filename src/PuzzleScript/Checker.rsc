module PuzzleScript::Checker

import PuzzleScript::AST;
import util::Math;
import List;
import String;
import IO;
import Type;

alias Reference = tuple[
	list[str] objs, 
	Checker c
];

alias Checker = tuple[
	list[Msg] msgs,
	bool debug_flag,
	map[str, list[str]] references,
	list[str] objects,
	map[str, list[str]] combinations,
	list[str] layer_list,
	PSGAME game
];

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

data MsgType
	= error()
	| warn()
	| info()
	;

// , MsgType t, loc pos
data Msg
	// errors
	= invalid_index(str name, int index, MsgType t, loc pos)
	| invalid_name(str name, MsgType t, loc pos)
	| invalid_layer(str name, list[str] layer, MsgType t, loc pos)
	| invalid_color(str name, str color, MsgType t, loc pos)
	| invalid_legend(str name, MsgType t, loc pos)
	| mixed_legend(str name, list[str] values, str l_type, str o_type, MsgType t, loc pos)
	| mixed_legend(str name, list[str] values, MsgType t, loc pos)
	| self_reference(str name, MsgType t, loc pos)
	| existing_object(str name, MsgType t, loc pos)
	| invalid_sprite(str name, str line, MsgType t, loc pos)
	| undefined_reference(str name, MsgType t, loc pos)
	| existing_legend(str legend, list[str] current, list[str] new, MsgType t, loc pos)
	| undefined_object(str name, MsgType t, loc pos)
	| unlayered_objects(str objects, MsgType t, loc pos)
	| existing_section(SECTION section, int dupe, MsgType t, loc pos)
	| invalid_level_row(MsgType t, loc pos)
	| ambiguous_pixel(str legend, list[str] objs, MsgType t, loc pos)
	//warnings
	| unused_colors(str name, str colors, MsgType t, loc pos)
	| no_levels(MsgType t, loc pos)
	| message_too_long(MsgType t, loc pos)
	;
		
Checker new_checker(bool debug_flag, PSGAME game){		
	return <[], debug_flag, (), [], (), [], game>;
}

//get a value from the prelude if it exists, else return the default
str get_prelude(list[PRELUDEDATA] values, str key, str default_str){
	v = [x | x <- values, toLowerCase(x.key) == toLowerCase(key)];
	if (size(v) > 0) return v[0].string;
	
	return default_str;
}

bool check_invalid_name(str name){
	return /^<x:[a-z]+>$/i := name;
}

bool check_invalid_legend(str name){
	if (size(name) > 1){
		return check_invalid_name(name);
	} else {
		return /^<x:[a-z.!@#$%&*]+>$/i := name;
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

Reference resolve_reference(str raw_name, Checker c, loc pos){
	Reference r;
	
	list[str] objs = [];	
	str name = toLowerCase(raw_name);
	
	if (name in c.references && c.references[name] == [name]) return <[name], c>;
	
	if (name in c.combinations) {
		for (str n <- c.combinations[name]) {
			r = resolve_reference(n, c, pos);
			objs += r.objs;
			c = r.c;
		}
	} else if (name in c.references) {
		for (str n <- c.references[name]) {
			r = resolve_reference(n, c, pos);
			objs += r.objs;
			c = r.c;
		}
	} else {
		c.msgs += [undefined_object(raw_name, error(), pos)];
	}
	
	return <dup(objs), c>;
}

Reference resolve_references(list[str] names, Checker c, loc pos) {
	list[str] objs = [];
	Reference r;
	
	for (str name <- names) {
		r = resolve_reference(name, c, pos);
		objs += r.objs;
		c = r.c;
	}
	
	return <dup(objs), c>;
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
	
	if (!check_invalid_name(id)) c.msgs += [invalid_name(id, error(), obj@location)];

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
	if (!check_invalid_legend(l.legend)) c.msgs += [invalid_name(l.legend, error(), l@location)];
	c.msgs += check_existing_legend(l.legend, l.values, l@location, c);
	
	Reference r = resolve_references(l.values, c, l@location);
	list[str] values = r[0];
	c = r[1];
	
	str legend = toLowerCase(l.legend);
	
	if (check_invalid_name(l.legend)) c.objects += [legend];
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
				c.msgs += [mixed_legend(l.legend, mixed, "alias", "combination", error(), l@location)];
			} else {
				c.combinations[legend] = values;
			}
		}
		case legend_error(_, _): c.msgs += [mixed_legend(l.legend, l.values, error(), l@location)];	
	}

	return c;
}

Checker check_sound(SOUNDDATA s, Checker c){
	
	
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



Checker check_rule(RULEDATA r, Checker c){
	
	return c;
}

Checker check_condition(CONDITIONDATA w, Checker c){
	
	return c;
}

//errors
//	invalid_level_row
//	invalid_legend
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
Checker check_game(PSGAME g, bool debug=false) {
	Checker c = new_checker(debug, g);
	
	map[SECTION, int] dupes = distribution(g.sections);
	for (SECTION s <- dupes) {
		if (dupes[s] > 1) c.msgs += [existing_section(s, dupes[s], error(), s@location)];
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

//public str println(Msg m: ) = ;
public str println(Msg m: invalid_index(str name, int index, MsgType t, loc pos)) 
	= "Color number <index> from color palette of <name> doesn\'t exist. <pos>";

public str println(Msg m: existing_object(str name, MsgType t, loc pos)) 
	= "Object <name> already exists. <pos>";

public str println(Msg m: invalid_sprite(str name, str line, MsgType t, loc pos)) 
	= "Sprite for <name> is not the correct length <size(line)>/5. <pos>";
	
public str println(Msg m: mixed_legend(str name, list[str] values, MsgType t, loc pos)) 
	= "Legend <name> has both \'and\' and \'or\' symbols. <pos>";
	
public str println(Msg m: mixed_legend(str name, list[str] values, str l_type, str o_type, MsgType t, loc pos))
	= "Legend <name> is a <l_type> and cannot use <o_type>. <pos>";
	
public str println(Msg m: invalid_color(str name, str color, MsgType t, loc pos)) 
	= "Color <color> for object <name> not found in palette. <pos>";
	
public str println(Msg m: self_reference(str name, MsgType t, loc pos))
	= "Reference <name> is referencing itself";
	
public str println(Msg m: undefined_reference(str name, MsgType t, loc pos)) 
	= "Reference <name> not defined. <pos>";
	
public str println(Msg m: existing_legend(str legend, list[str] current, list[str] new, MsgType t, loc pos)) 
	= "Legend <legend> is already defined for <current> cannot overwrite with <new>. <pos>";
	
public str println(Msg m: undefined_object(str name, MsgType t, loc pos)) 
	= "Object <name> is used but never defined. <pos>";
	
public str println(Msg m: unused_colors(str name, str colors, MsgType t, loc pos)) 
	= "Colors <colors> not used in <name>. <pos>";
	
public str println(Msg m: existing_section(SECTION section, int dupe, MsgType t, loc pos)) 
	= "Existing section <section> found. <pos>";

public str println(Msg m: invalid_name(str name, MsgType t, loc pos))
	= "Invalid name <name>, please only use a-z characters. <pos>";
	
public str println(Msg m: unlayered_objects(str objects, MsgType t, loc pos))
	= "Object(s) defined but not added to layer";
	
public str println(Msg m: invalid_level_row(MsgType t, loc pos))
	= "All rows of level must be the same lenght. <pos>";

public str println(Msg m: ambiguous_pixel(str legend, list[str] objs, MsgType t, loc pos))
	= "Cannot use property <legend> (defined with \'or\') in a level. <pos>";
	
public str println(Msg m: no_levels(MsgType t, loc pos))
	= "No levels defined. <pos>";
	
public str println(Msg m: message_too_long(MsgType t, loc pos))
	= "Message too long to fit on screen. <pos>";

public default str println(Msg m) = "Undefined message converter";


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
