module PuzzleScript::Checker

// For visualizing
import util::IDEServices;
import vis::Charts;

import PuzzleScript::AST;
import util::Math;
import IO;
import List;
import String;
import Type;
import PuzzleScript::Messages;
import PuzzleScript::Utils;

alias Checker = tuple[
	list[Msg] msgs,
	bool debug_flag,
	map[str, list[str]] references,
	list[str] objects,
	map[str, list[str]] combinations,
	list[str] layer_list,
	map[str, tuple[list[int] seeds, loc pos]] sound_events,
	list[str] used_sounds,
	list[Condition] conditions,
	map[str, str] prelude,
	list[str] used_objects,
	list[str] used_references,
    list[str] all_moveable_objects,
    map[str, list[str]] all_properties,
    map[LevelData, LevelChecker] level_data,
	PSGame game
];

alias LevelChecker = tuple[
    list[str] moveable_objects,
    tuple[int width, int height] size,
    list[RuleData] applied_rules,
    list[LevelData] messages
];

alias Reference = tuple[
	list[str] objs, 
	Checker c,
	list[str] references
];

data Condition (loc src = |unknown:///|)
	= some_objects(list[str] objects, ConditionData original)
	| no_objects(list[str] objects, ConditionData original)
	| all_objects_on(list[str] objects, list[str] on, ConditionData original)
	| some_objects_on(list[str] objects, list[str] on, ConditionData original)
	| no_objects_on(list[str] objects, list[str] on, ConditionData original)
	;

// anno loc Condition.src;

map[str, str] COLORS = (
	"black"   		: "#000000",
	"white"			: "#FFFFFF",
	"grey"			: "#555555",
	"darkgrey"		: "#555500",
	"transparent"   : "#555500",
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
		
Checker new_checker(bool debug_flag, PSGame game){		
	return <[], debug_flag, (), [], (), [], (), [], [], (), [], [], [], (), (), game>;
}

LevelChecker new_level_checker() {
    return <[], <0,0>, [], []>;
}

//get a value from the prelude if it exists, else return the default
str get_prelude(list[PreludeData] values, str key, str default_str){
	v = [x | x <- values, toLowerCase(x.key) == toLowerCase(key)];
	if (!isEmpty(v)) return v[0].string;
	
	return default_str;
}

bool check_valid_name(str name){
	return /^<x:[a-z0-9_]+>$/i := name && !(toLowerCase(name) in keywords);
}

bool check_valid_legend(str name){
	if (size(name) > 1){
		return check_valid_name(name);
	} else {
		return /^<x:[a-uw-z0-9.!@#$%&*,\-+]+>$/i := name && !(toLowerCase(name) in keywords);
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
		if (isEmpty(check_existing_legend(name, [], pos, c))) msgs += [undefined_object(name, error(), pos)];
	}

	return msgs;
}


Reference resolve_reference(str raw_name, Checker c, loc pos, list[str] allowed=["objects", "properties", "combinations"]){
	Reference r;
	
	list[str] objs = [];
	list[str] references = [];	
	str name = toLowerCase(raw_name);
	
    // If there is already a reference to the name
	if (name in c.references && c.references[name] == [name]) return <[name], c, references>;
	
	references += [toLowerCase(name)];

    // println("name = <name>");

	if (name in c.combinations) {

		if ("combinations" in allowed) {
			for (str n <- c.combinations[name]) {

				r = resolve_reference(n, c, pos);
				objs += r.objs;
				c = r.c;
				references += r.references;
			}
		} else {
			c.msgs += [invalid_object_type("combinations", name, error(), pos)];
		}
	} else if (name in c.references) {
		if ("properties" in allowed) {

			for (str n <- c.references[name]) {
				r = resolve_reference(n, c, pos);
				objs += r.objs;
				references += r.references;
				c = r.c;
			}
		} else {
			c.msgs += [invalid_object_type("properties", name, error(), pos)];
		}
	} else {
		c.msgs += [undefined_object(raw_name, error(), pos)];
	}
	
	return <dup(objs), c, references>;
}

map[str, list[str]] resolve_properties(Checker c) {

    map[str, list[str]] properties_dict = ();

    for (str name <- c.references<0>) {
        
        list[str] references = [];
        if (size(c.references[name]) > 1) {
            for (str reference <- c.references[name]) references += get_map_input(c, reference);
            properties_dict += (name: references);
        } else {
            properties_dict += (name: c.references[name]);
        }
    }

    return properties_dict;

}

list[str] get_map_input(Checker c, str name) {

    list[str] propertylist = [];

    if (c.references[name]?) {
        for(str name <- c.references[name]) propertylist += get_map_input(c, name);
    } else {
        propertylist += [name];
    }

    return propertylist;

}

Reference resolve_references(list[str] names, Checker c, loc pos, list[str] allowed=["objects", "properties", "combinations"]) {
	list[str] objs = [];
	list[str] references = [];
	Reference r;

	for (str name <- names) {
		r = resolve_reference(name, c, pos, allowed=allowed);
		objs += r.objs;
		c = r.c;
		references += r.references;
	}
	
	return <dup(objs), c, references>;
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
Checker check_prelude(PreludeData pr, Checker c){
	str key = toLowerCase(pr.key);
	if (!(key in prelude_keywords)){
		c.msgs += [invalid_prelude_key(pr.key, error(), pr.src)];
		return c;
	}
	
	if (key in c.prelude){
		c.msgs += [existing_prelude_key(pr.key, error(), pr.src)];
	}
	
	if (key in prelude_without_arguments){
		if (pr.string != "") c.msgs += [redundant_prelude_value(pr.key, warn(), pr.src)];
		c.prelude[key] = "None";
	} else {
		if (pr.string == ""){
			c.msgs += [missing_prelude_value(pr.key, error(), pr.src)];
			return c;
		}
		if (key in prelude_with_arguments_int) {
			if (!(check_valid_real(pr.string))) c.msgs += [invalid_prelude_value(key, pr.string, "real", error(), pr.src)];
			c.prelude[key] = pr.string;
		} else {
			if (key in prelude_with_arguments_str_dim) {
				if (!(/[0-9]+x[0-9]+/i := pr.string)) c.msgs += [invalid_prelude_value(key, pr.string, "height code", error(), pr.src)];
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
Checker check_object(ObjectData obj, Checker c) {
	int max_index = 0;
	str id = toLowerCase(obj.name);	
	
	if (!check_valid_name(id)) c.msgs += [invalid_name(id, error(), obj.src)];

	// check for duplicate object names
	if (id in c.objects) {
		c.msgs += [existing_object(obj.name, error(), obj.src)];
	} else {
		c.objects += [id];
	}
	
	// add references
	if (!isEmpty(obj.legend)) {

		msgs = check_existing_legend(obj.legend[0], [obj.name], obj.src, c);
		if (!isEmpty(msgs)){
			c.msgs += msgs;
		} else {
			c.used_objects += [id];
		}
	}
	
	//check colors (only default mastersystem palette supported currently)
	for (str color <- obj.colors) {
		if (toLowerCase(color) in COLORS) continue;
		if (/^#(?:[0-9a-fA-F]{3}){1,2}$/ := color) continue;
		
		c.msgs += [invalid_color(obj.name, color, error(), obj.src)];
	}

	// check if it has a sprite
	if (isEmpty(obj.sprite)) return c;
	bool valid_length = true;
	if (size(obj.sprite) != 5) valid_length = false;
	for(list[Pixel] line <- obj.sprite){		
		// check if the sprite is of valid length
		if (size(line) != 5) valid_length = false;
	
		// check if all pixels have the correct index
		for(Pixel pix <- line){
			str pixel = pix.pixel;
			if (pixel == ".") continue;
			
			int converted = toInt(pixel);
			if (converted + 1 > size(obj.colors)) {
				c.msgs += [invalid_index(obj.name, converted, error(), obj.src)];
			} else if (converted > max_index) max_index = converted;
		}
	}
	
	
	if (!valid_length) c.msgs += [invalid_sprite(obj.name, error(), obj.src)];
	
	// check if we are making use of all the colors defined
	if (size(obj.colors) > max_index + 1) {
		c.msgs += [unused_colors(obj.name, intercalate(", ", obj.colors[max_index+1..size(obj.colors)]), warn(), obj.src)];
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
Checker check_legend(LegendData l, Checker c) {
	if (!check_valid_legend(l.legend)) c.msgs += [invalid_name(l.legend, error(), l.src)];
	c.msgs += check_existing_legend(l.legend, l.values, l.src, c);


    if (l is legend_alias) {
        for (str object <- l.values) {
            if (toLowerCase(l.legend) in c.references) c.references[toLowerCase(l.legend)] += [toLowerCase(object)];
            else c.references += (toLowerCase(l.legend): [toLowerCase(object)]);
        }
    }

    if (l is legend_combined) {
        for (str object <- l.values) {
            if (toLowerCase(l.legend) in c.combinations) c.combinations[toLowerCase(l.legend)] += [toLowerCase(object)];
            else c.combinations += (toLowerCase(l.legend): [toLowerCase(object)]);
        }
    }

	str legend = toLowerCase(l.legend);

    // Check if object in legend is defined in objects section
	if (check_valid_name(l.legend)) c.objects += [legend];
	// for (str v <- values){
	// 	if (!(v in c.objects)) {
	// 		c.msgs += [undefined_object(v, error(), l.src)];
	// 	} else {
	// 		c.used_objects += [v];
	// 	}
	// }
	
	// // if it's just one thing being defined with check it and return
	// if (size(values) == 1) {
	// 	msgs = check_undefined_object(l.values[0], l.src, c);
	// 	if (!isEmpty(msgs)) {
	// 		c.msgs += msgs;
	// 	} else {
	// 		// check if it's a self definition and warn as need be
	// 		if (legend == values[0]){
	// 			c.msgs += [self_reference(l.legend, warn(), l.src)];
	// 		} else {
	// 			c.references[legend] = values;
	// 		}
	// 	}
		
	// 	return c;
	// }
	
	// // if not we do a more expensive check for invalid legend and mixed types
	// switch(l) {
	// 	case legend_alias(_, _): {
	// 		// if our alias makes use of combinations that's a bonk
	// 		list[str] mixed = [x | x <- values, x in c.combinations];
	// 		if (!isEmpty(mixed)) {
	// 			c.msgs += [mixed_legend(l.legend, mixed, "alias", "combination", error(), l.src)];
	// 		} else {
	// 			c.references[legend] = values;
	// 		}
	// 	}
	// 	case legend_combined(_, _): {
	// 		// if our combination makes use of aliases that's a bonk (just gotta make sure it's actually an alias)
	// 		list[str] mixed = [x | x <- values, x in c.references && size(c.references[x]) > 1];
	// 		if (!isEmpty(mixed)) {
	// 			c.msgs += [mixed_legend(l.legend, mixed, "combination", "alias", error(), l.src)];
	// 		} else {
	// 			c.combinations[legend] = values;
	// 		}
	// 	}
	// 	case legend_error(_, _): c.msgs += [mixed_legend(l.legend, l.values, error(), l.src)];	
	// }

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
Checker check_sound(SoundData s, Checker c){
	int seed;
	
	if (size(s.sound) == 2 && toLowerCase(s.sound[0]) in sound_events) {
		if (!check_valid_sound(s.sound[1])) {
			c.msgs += [invalid_sound_seed(s.sound[1], error(), s.src)];
			seed = -1;
		} else {
			seed = toInt(s.sound[1]);
		}
		
		if (toLowerCase(s.sound[0]) in c.sound_events) {
			c.msgs += [existing_sound(s.sound[0], warn(), s.src)];
			c.sound_events[toLowerCase(s.sound[0])].seeds += [seed];
		} else {
			c.sound_events[toLowerCase(s.sound[0])] = <[seed], s.src>;
		}
		
		return c;
	} else if (size(s.sound) < 3) {
		c.msgs += [invalid_sound_length(error(), s.src)];
		return c;
	}
	
	list[str] objects = [];
	str mask = default_mask;
	seed = -1;
	list[str] directions = [];
	
	for (str verb <- s.sound) {
		str v = toLowerCase(verb);
		if (v in c.objects) {
			if (isEmpty(objects)) {
				Reference r = resolve_reference(verb, c, s.src);
				c = r.c;
				objects = r.objs;
			} else {
				c.msgs += [existing_sound_object(error, s.src)];
			}
		} else if (v in sound_masks) {
			if (mask == default_mask) {
				mask = v;
			} else {
				c.msgs += [existing_mask(v, mask, error(), s.src)];
			}
			
		} else if (v in absolute_directions_single){
			if (!(mask in directional_sound_masks)) {
				c.msgs += [mask_not_directional(mask, error(), s.src)];
			} else {
				directions += [v];
			}
		} else if (check_valid_sound(v)) {
			if (seed != -1){
				c.msgs += [existing_sound_seed(toString(seed), v, error(), s.src)];
			} else {
				seed = toInt(v);
			}
		} else {
			c.msgs += [invalid_sound_verb(verb, error(), s.src)];
		}
	}
	
	if (isEmpty(objects)) c.msgs += [undefined_sound_objects(error(), s.src)];
	if (mask == default_mask) c.msgs += [undefined_sound_mask(error(), s.src)];
	if (seed < 0) c.msgs += [undefined_sound_seed(error(), s.src)];
	
	//object_mask_direction
	for (str obj <- objects){
		list[str] events = [];
		if (mask in directional_sound_masks && !isEmpty(directions)){
			for (str dir <- directions){
				events += ["<obj>_<mask>_<dir>"];
			}
		} else {
			events += ["<obj>_<mask>"];
		}
		
		for (str e <- events){
			if (e in c.sound_events) {
				c.msgs += [existing_sound(e, warn(), s.src)];
				c.sound_events[e].seeds += [seed];
			} else {
				c.sound_events[e] = <[seed], s.src>;
			}
		}
	}
	
	return c;
}

// errors
//	undefined_object
// warnings
//	multilayered_object
Checker check_layer(LayerData l, Checker c){
	Reference r = resolve_references(l.layer, c, l.src);
	c = r.c;
	for (str obj <- r.objs){
		if (obj in c.layer_list) c.msgs += [multilayered_object(obj, warn(), l.src)];
	}
	
	c.layer_list += r.objs;
	
	return c;
}

Checker check_rulepart(RulePart p: part(list[RuleContent] contents), Checker c, bool late, bool pattern){
	for (RuleContent cont <- contents) {
		if ("..." in cont.content) {
			if (cont.content != ["..."]) c.msgs += [invalid_ellipsis(error(), cont.src)];
			continue;
		}

		list[str] objs = [toLowerCase(x) | x <- cont.content, !(toLowerCase(x) in rulepart_keywords)];
		list[str] verbs = [toLowerCase(x) | x <- cont.content, toLowerCase(x) in rulepart_keywords];

		if(any(str x <- verbs, x notin ["no"]) && late) c.msgs += [invalid_rule_movement_late(error(), cont.src)];
		
        int index = 0;
        for (str verb <- verbs) {

            if (verb in moveable_keywords && !(objs[index] in c.all_moveable_objects)) {

                // list[str] moveable_object = objs[index];
                // for (str object <- moveable_objects) {
                //     if (object in c.references<0>) {
                //         for (str child_object <- c.references[object]) c.all_moveable_objects += toLowerCase(child_object);
                //     }


                // }
                // println("References = <resolve_reference(objs[index], c, cont.src).references>");
                c.all_moveable_objects += resolve_reference(objs[index], c, cont.src).references;
            }
            
            index += 1;

        }

		if (pattern){
			if(any(str rand <- rulepart_random, rand in verbs)) c.msgs += [invalid_rule_random(error(), cont.src)];
		}
		
		list[list[str]] references = [];
		for (str obj <- objs) {
			Reference r = resolve_reference(obj, c, cont.src);
			c = r.c;
			c.used_references += r.references;
			c.used_objects += r.objs;
			references += [r.objs];
		}
		
		if (size(objs) > 1){
			for (int i <- [0..size(references)-1]){
				for (int j <- [i+1..size(references)]){
					c = check_stackable(references[i], references[j], c, cont.src);
				}
			}
		}
		
		// if we have a mismatch between verbs and objs we skip
		// else we check to make sure that only one force is applied to any one object
		if (size(verbs) > size(objs)) {
			c.msgs += [invalid_rule_keyword_amount(error(), cont.src)];
		} else {
			for (int i <- [0..size(cont.content)]){
				if (toLowerCase(cont.content[i]) in verbs && i == size(cont.content) - 1) {
					//leftover force on the end
					c.msgs += [invalid_rule_keyword_placement(false, error(), cont.src)];
				} else if (toLowerCase(cont.content[i]) in verbs && !(toLowerCase(cont.content[i+1]) in objs)){
					//force not followed by object
					c.msgs += [invalid_rule_keyword_placement(true, error(), cont.src)];
				}
			}
		}					
	}
	
	if (!isEmpty(contents)) {
		if ("..." in contents[0].content || "..." in contents[-1].content) c.msgs += [invalid_ellipsis_placement(error(), p.src)];
	}
	
	return c;
}

Checker check_rulepart(RulePart p: command(str command), Checker c, bool late, bool pattern){
	if (!(toLowerCase(command) in rule_commands)) 
		c.msgs += [invalid_rule_command(command, error(), p.src)];
	
	return c;
}

Checker check_rulepart(RulePart p: sound(str snd), Checker c, bool late, bool pattern){
	if (/sfx([0-9]|'10')/i := snd && toLowerCase(snd) in c.sound_events) {
		c.used_sounds += [toLowerCase(snd)];
	} else if (/sfx([0-9]|10)/i := snd) {
		//correct format but undefined
		c.msgs += [undefined_sound(snd, error(), p.src)];
	} else {
		//wrong format
		c.msgs += [invalid_sound(snd, error(), p.src)];
	}

	return c;
}

Checker check_rulepart(RulePart p: prefix(str prefix), Checker c, bool late, bool pattern){
	if (!(toLowerCase(p.prefix) in rule_prefix)) c.msgs += [invalid_rule_prefix(p.prefix, error(), p.src)];
	
	return c;
}

// errors
//	invalid_rule_prefix
//	invalid_rule_command
//	undefined_sound
//	undefined_object
//	invalid_sound
//	invalid_ellipsis_placement
//	invalid_ellipsis
//	invalid_rule_part_size
//	invalid_rule_content_size
//	invalid_rule_ellipsis_size


Checker check_rule(RuleData r: rule_loop(_,_), Checker c){
  for(RuleData childRule <- r.rules){
    check_rule(childRule, c);
  }
  return c;
}

Checker check_rule(RuleData r: rule_data(_, _, _, _), Checker c){

	bool late = any(RulePart p <- r.left, p is prefix && toLowerCase(p.prefix) == "late");
	
	bool redundant = any(RulePart p <- r.right, p is prefix && toLowerCase(p.prefix) in ["win", "restart"]);
	if (redundant && size(r.right) > 1) c.msgs += [redundant_keyword(warn(), r.src)];

	int msgs = size([x | x <- c.msgs, x.t is error]);
	if ([*_, part(_), prefix(_), *_] := r.left) c.msgs += [invalid_rule_direction(warn(), r.src)];
	
	for (RulePart p <- r.left){
		c = check_rulepart(p, c, late, true);
	}
	
	for (RulePart p <- r.right){
		c = check_rulepart(p, c, late, false);
	}
	
	// if some of the rule is invalid it gets complicated to do more checks, so we return it 
	// for now until they fixed the rest
	if (size([x | x <- c.msgs, x.t is error]) > msgs) return c;
	
	list[RulePart] part_right = [x | RulePart x <- r.right, x is part];
	if (isEmpty(part_right)) return c;
	
	list[RulePart] part_left = [x | RulePart x <- r.left, x is part];
	if (isEmpty(part_left)) return c;
	
	//check if there are equal amounts of parts on both sides
	if (size(part_left) != size(part_right)) {
		c.msgs += [invalid_rule_part_size(error(), r.src)];
		return c;
	}
	
	//check if each part, and its equivalent have the same number of sections
	for (int i <- [0..size(part_left)]){
		if (size(part_left[i].contents) != size(part_right[i].contents)) {
			c.msgs += [invalid_rule_content_size(error(), r.src)];
			continue;
		}
		
		//check if the equivalent of any part with an ellipsis also has one
		for (int j <- [0..size(part_left[i].contents)]){
			list[str] left = part_left[i].contents[j].content;
			list[str] right = part_right[i].contents[j].content;
			
			if (left == ["..."] && right != ["..."]) invalid_rule_ellipsis_size(error(), r.src);
			if (right == ["..."] && left != ["..."]) invalid_rule_ellipsis_size(error(), r.src);
			
		}
	}
	
	return c;
}

Checker check_stackable(list[str] objs1, list[str] objs2, Checker c, loc pos){
	for (LayerData l <- c.game.layers){
		list[str] lw = [toLowerCase(x) | x <- l.layer];		
		if (!isEmpty(objs1 & lw) && !isEmpty(objs2 & lw)){
			c.msgs += [impossible_condition_unstackable(error(), pos)];
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
Checker check_condition(ConditionData w, Checker c){
	if (!(size(w.condition) in [2, 4])){
		c.msgs += [invalid_condition_length(error(), w.src)];
		return c;
	}
	
	bool has_on = size(w.condition) == 4;
	Reference r = resolve_reference(w.condition[1], c, w.src);
	list[str] objs = r.objs;
	c = r.c; 
	c.used_references += r.references;
	
	// only one object can defined but it can be an aggregate so we can end up with
	// multiple objects once we're done resolving references
	list[str] on = [];
	if (has_on) {
		Reference r2 = resolve_reference(w.condition[3], c, w.src);
		on = r2.objs;
		c = r2.c;
		c.used_references += r2.references; 
	}
	
	for (str obj <- objs + on) {
		if (toLowerCase(obj) in c.combinations) c.msgs += [invalid_object_type("combinations", obj, error(), w.src)];
	}
	
	
	list[str] dupes = [x | str x <- objs, x in on];
	if (!isEmpty(dupes)){
		c.msgs += [impossible_condition_duplicates(dupes, error(), w.src)];
	}
	
	c = check_stackable(objs, on, c, w.src);
	
	Condition cond;
	bool valid = true;
	switch(toLowerCase(w.condition[0])) {
		case /all/: {
			if (has_on) {
				cond = all_objects_on(objs, on, w);
			} else {
				valid = false;
				c.msgs += [invalid_condition(error(), w.src)];
			}
		}
		case /some|any/: {
			if (has_on) {
				cond = some_objects_on(objs, on, w);
			} else {
				cond = some_objects(objs, w);
			}
		}
		case /no/: {
			if (has_on) {
				cond = no_objects_on(objs, on, w);
			} else {
				cond = no_objects(objs, w);
			}
		}
		
		default: {
			valid = false;
			c.msgs += invalid_condition_verb(w.condition[0], error(), w.src);
		}
	}
	
	if (valid){
		if (cond in c.conditions) {
			loc original = c.conditions[indexOf(c.conditions, cond)].src;
			c.msgs += [existing_condition(original, warn(), w.src)];
		}
        cond.src = w.src;
		c.conditions += [cond];
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
Checker check_level(LevelData l, Checker c){
	switch(l) {
		case message(str msg): if (size(split(" ", msg)) > 12) c.msgs += [message_too_long(warn(), l.src)];
		case level_data(_): {
			int length = size(l.level[0]);
			bool invalid = false;
			
			for (str line <- l.level){
				if (size(line) != length) invalid = true;
				
				list[str] char_list = split("", line);
				for (str legend <- char_list) {
					Reference r = resolve_reference(legend, c, l.src);
					c = r.c;
					c.used_references += r.references;
					
					if (toLowerCase(legend) in c.references && size(r.objs) > 1) {
						c.msgs += [ambiguous_pixel(legend, r.objs, error(), l.src)];
					}
					
				}
			}
			if (invalid) c.msgs += [invalid_level_row(error(), l.src)];
		}
	}

	return c;
}

// errors
//	existing_section
//	unlayered_objects
// warning
//	no_levels

map[LevelData, LevelChecker] check_game_per_level(Checker allData, bool debug=false) {

    map[LevelData, LevelChecker] allLevelData = ();
    PSGame g = allData.game;

    LevelChecker lc = new_level_checker();

    for (LevelData ld <- g.levels) {

        if (ld is level_empty) continue;

        if (ld is message) {
            lc.messages += [ld];
            continue;
        }
        lc.size = <size(ld.level[0]), size(ld.level)>;

        lc = moveable_objects_in_level(ld, lc, allData);

        lc = applied_rules(ld, lc, allData);
        
        allLevelData += (ld: lc);

        lc = new_level_checker();

    }
    return allLevelData;

}

LevelChecker moveable_objects_in_level(LevelData ld, LevelChecker lc, Checker c) {

    for (str line <- ld.level) {

        list[str] char_list = split("", line);
        for (str char <- char_list) {

            char = toLowerCase(char);
            if (char in c.combinations) lc.moveable_objects += 
                [x | x <- c.combinations[char], x in c.all_moveable_objects];
            if (char in c.references) lc.moveable_objects += 
                [x | x <- c.references[char], x in c.all_moveable_objects];
        }
    }

    return lc;

}

LevelChecker applied_rules(LevelData ld, LevelChecker lc, Checker c) {

    list[RuleData] rules = c.game.rules;

    list[RuleData] rules_used = [];
    list[str] chars_used = [];
    list[str] char_references = [];

    for (str line <- ld.level) {

        list[str] char_list = split("", line);
        for (str char <- char_list) {

            char = toLowerCase(char);
            if (!(char in chars_used)) {
                if (char in c.references) char_references += get_all_references(char, c.references);
                else char_references += get_all_references(char, c.combinations);

            }
        }
    }

    for (RuleData rd <- rules) if (rd is rule_data && rules_referencing_char(char_references, rd)) rules_used += rd;
    lc.applied_rules = rules_used;

    return lc;

}

str get_char(str name, map[str, list[str]] references) {

    for (str char <- references<0>) {
        if (size(char) == 1 && references[char] == [name]) {   
            return toLowerCase(char);
        }
    }
    return "";
}

list[str] get_all_references(str char, map[str, list[str]] references, bool debug = false) {

    if (!(char in references<0>)) return [];

    list[str] reference_list = [];
    list[str] new_references = references[char];
    reference_list += new_references;

    for (str reference <- new_references) {

        reference_list += get_references(reference, references);

    }

    return reference_list;


}

list[str] get_references(str reference, map[str, list[str]] references) {

    list[str] all_references = [];

    for (str key <- references) {

        if (size(key) == 1) continue;

        if (reference in references[key]) {
            all_references += key;
            all_references += get_references(key, references);
        }
    }

    return all_references;
}

bool rules_referencing_char(list[str] char_references, RuleData r: rule_data(left, right, _, _)) {

    list[RuleData] used = [];
    list[str] ruleContent = [];

    for (RulePart rule <- left) {
        if (rule is part) {

            for (RuleContent content <- rule.contents) {
                for (str content <- content.content) {

                    if (!(content in rulepart_keywords)) ruleContent += toLowerCase(content);
                    // if (toLowerCase(content) in char_references && !(r in used)) {
                    //     // println("<toLowerCase(content)> is in references, adding <r> to used");
                    //     used += r;
                    // }
                }
            }
            if (ruleContent != [] && ruleContent < char_references && !(r in used)) {
                return true;
            }
        }
    }

    return false;

}


Checker check_game(PSGame g, bool debug=false) {

	Checker c = new_checker(debug, g);

	map[Section, int] dupes = distribution(g.sections);
	for (Section s <- dupes) {
		if (dupes[s] > 1) c.msgs += [existing_section(s, dupes[s], warn(), s.src)];
	}
	
	for (PreludeData pr <- g.prelude){
		c = check_prelude(pr, c);
	}
	
	for (ObjectData obj <- g.objects){
		c = check_object(obj, c);
	}
	
	for (LegendData l <- g.legend){
		c = check_legend(l, c);
	}

	for (SoundData s <- g.sounds) {
		c = check_sound(s, c);
	}

	for (LayerData l <- g.layers) {
		c = check_layer(l, c);
	}

	for (RuleData r <- g.rules) {
		c = check_rule(r, c);
	}
	
	for (str event <- c.sound_events) {
		if (startsWith(event, "sfx") && event notin c.used_sounds) c.msgs += [unused_sound_event(warn(), c.sound_events[event].pos)];
	}
	
	for (ConditionData w <- g.conditions) {
		c = check_condition(w, c);
	}
	
	for (LevelData l <- g.levels) {
		c = check_level(l, c);
	}
	
	for (ObjectData x <- g.objects){
		if (!(toLowerCase(x.name) in c.layer_list)) c.msgs += [unlayered_objects(x.name, error(), x.src)];
		if (!(toLowerCase(x.name) in c.used_objects)) c.msgs += [unused_object(x.name, warn(), x.src)];
	}
	
	for (LegendData x <- g.legend){
		if (!(toLowerCase(x.legend) in c.used_references)) c.msgs += [unused_legend(x.legend, warn(), x.src)];
	}

    c.all_properties = resolve_properties(c);
	
	if (isEmpty(g.levels)) c.msgs += [no_levels(warn(), g.src)];
	
	return c;
}

void print_msgs(Checker checker){
	list[Msg] error_list = [x | Msg x <- checker.msgs, x.t == error()];
	list[Msg] warn_list  = [x | Msg x <- checker.msgs, x.t == warn()];
	list[Msg] info_list  = [x | Msg x <- checker.msgs, x.t == info()];
	
	if (!isEmpty(error_list)) {
		println("ERRORS");
		for (Msg msg <- error_list) {
			println(toString(msg));
		}
	}
	
	if (!isEmpty(warn_list)) {
		println("WARNINGS");
		for (Msg msg <- warn_list) {
			println(toString(msg));
		}
	}
	
	if (!isEmpty(info_list)) {
		println("INFO");
		for (Msg msg <- info_list) {
			println(toString(msg));
		}
	}
}
