module PuzzleScript::Messages

import IO;
import PuzzleScript::AST;
import String;
import List;
import Message;

set[Message] toMessages(list[Msg] msgs){
	set[Message] messages = {};
	
	for (Msg msg <- msgs){
		if (msg.t is error){
			messages = messages + error(toString(msg), msg.pos);
		} else if (msg.t is warn) {
			messages = messages + warning(toString(msg), msg.pos);
		} else {
			messages = messages + info(toString(msg), msg.pos);
		}
	}
	
	return messages;
}

data MsgType
	= error()
	| warn()
	| info()
	;

// , MsgType t, loc pos
data Msg
	= generic(str msg, MsgType t, loc pos)
	// errors 
	| invalid_index(str name, int index, MsgType t, loc pos)
	| invalid_name(str name, MsgType t, loc pos)
	| invalid_layer(str name, list[str] layer, MsgType t, loc pos)
	| invalid_color(str name, str color, MsgType t, loc pos)
	| invalid_legend(str name, MsgType t, loc pos)
	| invalid_sound_seed(str sound, MsgType t, loc pos)
	| invalid_sound_verb(str verb, MsgType t, loc pos)
	| invalid_sprite(str name, MsgType t, loc pos)
	| invalid_level_row(MsgType t, loc pos)
	| invalid_sound_length(MsgType t, loc pos)
	| invalid_condition_length(MsgType t, loc pos)
	| invalid_condition(MsgType t, loc pos)
	| invalid_condition_verb(str condition, MsgType t, loc pos)
	| invalid_object_type(str word, str obj, MsgType t, loc pos)
	| invalid_prelude_key(str key, MsgType t, loc pos)
	| invalid_prelude_value(str key, str v, str tp, MsgType t, loc pos)
	| invalid_rule_prefix(str prefix, MsgType t, loc pos)
	| invalid_rule_command(str command, MsgType t, loc pos)
	| invalid_sound(str sound, MsgType t, loc pos)
	| invalid_ellipsis_placement(MsgType t, loc pos)
	| invalid_ellipsis(MsgType t, loc pos)
	| invalid_rule_part_size(MsgType t, loc pos)
	| invalid_rule_content_size(MsgType t, loc pos)
	| invalid_rule_keyword_amount(MsgType t, loc pos)
	| invalid_rule_keyword_placement(bool p, MsgType t, loc pos)
	| invalid_rule_ellipsis_size(MsgType t, loc pos)
	| invalid_rule_movement_late(MsgType t, loc pos)
	| invalid_rule_random(MsgType t, loc pos)
	
	| mixed_legend(str name, list[str] values, str l_type, str o_type, MsgType t, loc pos)
	| mixed_legend(str name, list[str] values, MsgType t, loc pos)
	
	| existing_object(str name, MsgType t, loc pos)
	| existing_legend(str legend, list[str] current, list[str] new, MsgType t, loc pos)
	| existing_section(SECTION section, int dupe, MsgType t, loc pos)
	| existing_mask(str new_mask, str existing_mask, MsgType t, loc pos)
	| existing_sound_seed(str new_seed, str existing_seed, MsgType t, loc pos)
	| existing_sound_object(MsgType t, loc pos)
	| existing_prelude_key(str key, MsgType t, loc pos)
	
	| undefined_reference(str name, MsgType t, loc pos)
	| undefined_object(str name, MsgType t, loc pos)
	| undefined_sound_seed(MsgType t, loc pos)
	| undefined_sound_mask(MsgType t, loc pos)
	| undefined_sound_objects(MsgType t, loc pos)
	| undefined_sound(str sound, MsgType t, loc pos)
	
	| unlayered_objects(str objects, MsgType t, loc pos)
	| ambiguous_pixel(str legend, list[str] objs, MsgType t, loc pos)
	| reserved_keyword(str k, MsgType t, loc pos)
	| self_reference(str name, MsgType t, loc pos)
	| mask_not_directional(str mask, MsgType t, loc pos)
	| impossible_condition_duplicates(list[str] dup_objects, MsgType t, loc pos)
	| impossible_condition_unstackable(MsgType t, loc pos)
	| missing_prelude_value(str key, MsgType t, loc pos)
	
	//warnings
	| unused_colors(str name, str colors, MsgType t, loc pos)
	| no_levels(MsgType t, loc pos)
	| message_too_long(MsgType t, loc pos)
	| existing_sound(str sound, MsgType t, loc pos)
	| existing_condition(loc original, MsgType t, loc pos)
	| existing_rule(loc original, MsgType t, loc pos)
	| redundant_prelude_value(str key, MsgType t, loc pos)
	| multilayered_object(str obj, MsgType t, loc pos)
	| redundant_keyword(MsgType t, loc pos)
	| unused_sound_event(MsgType t, loc pos)
	| invalid_rule_direction(MsgType t, loc pos)	
	;

public str toString(Msg m: generic(str msg, MsgType t, loc pos))
	= "<msg> <pos>";	
	
public str toString(Msg m: invalid_index(str name, int index, MsgType t, loc pos)) 
	= "Color number <index> from color palette of <name> doesn\'t exist. <pos>";

public str toString(Msg m: existing_object(str name, MsgType t, loc pos)) 
	= "Object <name> already exists. <pos>";

public str toString(Msg m: invalid_sprite(str name, MsgType t, loc pos)) 
	= "A sprite line for <name> is not exactly 5 pixels. <pos>";
	
public str toString(Msg m: mixed_legend(str name, list[str] values, MsgType t, loc pos)) 
	= "Legend <name> has both \'and\' and \'or\' symbols. <pos>";
	
public str toString(Msg m: mixed_legend(str name, list[str] values, str l_type, str o_type, MsgType t, loc pos))
	= "Legend <name> is a <l_type> and cannot use <o_type>. <pos>";
	
public str toString(Msg m: invalid_color(str name, str color, MsgType t, loc pos)) 
	= "Color <color> for object <name> not found in palette. <pos>";
	
public str toString(Msg m: self_reference(str name, MsgType t, loc pos))
	= "Reference <name> is referencing itself";
	
public str toString(Msg m: undefined_reference(str name, MsgType t, loc pos)) 
	= "Reference <name> not defined. <pos>";
	
public str toString(Msg m: existing_legend(str legend, list[str] current, list[str] new, MsgType t, loc pos)) 
	= "Legend <legend> is already defined for <current> cannot overwrite with <new>. <pos>";
	
public str toString(Msg m: undefined_object(str name, MsgType t, loc pos)) 
	= "Object <name> is used but never defined. <pos>";
	
public str toString(Msg m: unused_colors(str name, str colors, MsgType t, loc pos)) 
	= "Colors <colors> not used in <name>. <pos>";
	
public str toString(Msg m: existing_section(SECTION section, int dupe, MsgType t, loc pos)) 
	= "Existing section <section> found. <pos>";

public str toString(Msg m: invalid_name(str name, MsgType t, loc pos))
	= "Invalid name <name>, please only use characters appropriate for that section and not reserved keywords. <pos>";
	
public str toString(Msg m: unlayered_objects(str objects, MsgType t, loc pos))
	= "Object(s) <objects> defined but not added to layer";
	
public str toString(Msg m: invalid_level_row(MsgType t, loc pos))
	= "All rows of level must be the same lenght. <pos>";

public str toString(Msg m: ambiguous_pixel(str legend, list[str] objs, MsgType t, loc pos))
	= "Cannot use property <legend> (defined with \'or\') in a level. <pos>";
	
public str toString(Msg m: no_levels(MsgType t, loc pos))
	= "No levels defined. <pos>";
	
public str toString(Msg m: message_too_long(MsgType t, loc pos))
	= "Message too long to fit on screen. <pos>";
	
public str toString(Msg m: invalid_sound_verb(str verb, MsgType t, loc pos))
	= "Unrecognized sound verb <verb> in sound definition";
	
public str toString(Msg m: invalid_sound_seed(str sound, MsgType t, loc pos))
	= "Invalid sound seed <sound>. <pos>";
	
public str toString(Msg m: invalid_sound_length(MsgType t, loc pos))
	= "Invalid amount of sound verbs. <pos>";
	
public str toString(Msg m: mask_not_directional(str mask, MsgType t, loc pos))
	= "Can\'t use directional keywords if mask is not \'move\' or \'cantmove\', mask is currently <mask>. <pos>";

public str toString(Msg m: existing_mask(str new_mask, str existing_mask, MsgType t, loc pos))
	= "Mask already defined as <existing_mask> can\'t also define it as <new_mask>. <pos>";
	
public str toString(Msg m: existing_sound_seed(str new_seed, str existing_seed, MsgType t, loc pos))
	= "Sound seed already defined as <existing_seed> can\'t also define it as <new_seed>. <pos>";

public str toString(Msg m: existing_sound_object(MsgType t, loc pos))
	= "Objects for this sound have already been defined. <pos>";
	
public str toString(Msg m: undefined_sound_seed(MsgType t, loc pos))
	= "No sound seed defined. <pos>";
	
public str toString(Msg m: undefined_sound_mask(MsgType t, loc pos))
	= "No sound mask defined. <pos>";
	
public str toString(Msg m: undefined_sound_objects(MsgType t, loc pos))
	= "No objects defined for sound. <pos>";
	
public str toString(Msg m: existing_sound(str sound, MsgType t, loc pos))
	= "Sound event like <sound> already registered. <pos>";
	
public str toString(Msg m: invalid_condition_length(MsgType t, loc pos))
	= "Invalid amount of condition verbs, conditions must be either 2 or 4 long. <pos>";
	
public str toString(Msg m: invalid_condition(MsgType t, loc pos))
	= "Must use additional objects with \'all\' keyword";
	
public str toString(Msg m: invalid_condition_verb(str verb, MsgType t, loc pos))
	= "Invalid win condition verb <verb>. <pos>";
	
public str toString(Msg m: invalid_object_type(str word, str obj, MsgType t, loc pos))
	= "Cannot use <word> here. <pos>";
	
public str toString(Msg m: impossible_condition_duplicates(list[str] dup_objects, MsgType t, loc pos))
	= "Objects <dup_objects> cannot be \'on\' themselves. <pos>";
	
public str toString(Msg m: impossible_condition_unstackable(MsgType t, loc pos))
	= "Objects in section need to be able to stack but appear on the same layer. <pos>";

public str toString(Msg m: invalid_prelude_key(str key, MsgType t, loc pos))
	= "Invalid prelude keyword <key>. <pos>";
	
public str toString(Msg m: existing_prelude_key(str key, MsgType t, loc pos))
	= "Prelude keyword <key> already defined. <pos>";
	
public str toString(Msg m: missing_prelude_value(str key, MsgType t, loc pos))
	= "Missing prelude value for key <key>. <pos>";
	
public str toString(Msg m: invalid_prelude_value(str key, str v, str tp, MsgType t, loc pos))
	= "Expected <tp> for <key> but found <v>. <pos>";
	
public str toString(Msg m: redundant_prelude_value(str key, MsgType t, loc pos))
	= "Values passed to <key> but it is unecessary. <pos>";

public str toString(Msg m: invalid_rule_prefix(str prefix, MsgType t, loc pos))
	= "Rule prefix <prefix> invalid. <pos>";

public str toString(Msg m: invalid_rule_command(str command, MsgType t, loc pos))
	= "Command <command> invalid. <pos>";
	
public str toString(Msg m: undefined_sound(str sound, MsgType t, loc pos))
	= "Sound <sound> is used but never defined";
	
public str toString(Msg m: invalid_sound(str sound, MsgType t, loc pos))
	= "Invalid sound <sound>. <pos>";
	
public str toString(Msg m: invalid_ellipsis_placement(MsgType t, loc pos))
	= "Rule cannot start or end with an ellipsis. <pos>";

public str toString(Msg m: invalid_ellipsis(MsgType t, loc pos))
	= "Cannot have any other verbs or objects with an ellipsis. <pos>";

public str toString(Msg m: invalid_rule_part_size(MsgType t, loc pos))
	= "Left and right side must have an equal amount of bracket matches. <pos>";

public str toString(Msg m: invalid_rule_content_size(MsgType t, loc pos))
	= "Left and right bracket matches must have equal amounts of sections. <pos>";

public str toString(Msg m: invalid_rule_ellipsis_size(MsgType t, loc pos))
	= "Left and right matches must have ellipsis in the same places. <pos>";

public str toString(Msg m: existing_condition(loc original, MsgType t, loc pos))
	= "Win condition with these requirements already exists at <original>. <pos>";
	
public str toString(Msg m: existing_rule(loc original, MsgType t, loc pos))
	= "Rule with these requirement already exists at <original>. <pos>";
	
public str toString(Msg m: invalid_rule_keyword_amount(MsgType t, loc pos))
	= "You can only have a maximum of one keyword per rule section. <pos>";
	
public str toString(Msg m: invalid_rule_keyword_placement(bool p, MsgType t, loc pos))
	= "Forces must be applied to an object, <p>. <pos>";
	
public str toString(Msg m: multilayered_object(str obj, MsgType t, loc pos))
	= "Object <obj> included in multiple collision layers. <pos>";
	
public str toString(Msg m: invalid_rule_movement_late(MsgType t, loc pos))
	= "Movevement cannot be used in late rules. <pos>";
	
public str toString(Msg m: invalid_rule_random(MsgType t, loc pos))
	= "Cannot use random keywords in the left side of a rule. <pos>";
	
public str toString(Msg m: redundant_keyword(MsgType t, loc pos))
	= "Using win or restart keyword on the right side of a rule makes other parts and commands pointless";

public str toString(Msg m: unused_sound_event(MsgType t, loc pos))
	= "Sound defined but never used. <pos>";
	
public str toString(Msg m: invalid_rule_direction(MsgType t, loc pos))
	= "Rule directions should be placed at a start of a rule. <pos>";


// a list of stupid solutions that game designers probably want to avoid making possible
data StupidSolutions
	// solving the game by only going in one direction or by pressing the action button
	= unidirectional(str dir, MsgType t, loc pos)
	
	// solving a level without using any rules, this means the win condition requires
	// the player object and optionally some other already fulfilled condition
	| unruled(MsgType t, loc pos)
	;

// a list of msgs that are detected through semi-dynamic analysis, we don't always
// have to run the game to figure them out but we do have to compile it
data DynamicMsgs
	// we have a level that matches our required win conditions before
	// the player even interacts with it
	= instant_victory(MsgType t, loc pos)
	
	// we have levels that cannot be solved because the rules do not spawn 
	// the necessary items and they are not available off the bat
	| unsolvable_rules_missing_items(MsgType t, loc pos)
	
	// levels should increase in difficulty, increasing difficulty is
	// defined as a mix of increased size, increased number of items
	// and using more rules than the previous ones
	| difficulty_not_increasing(MsgType t, loc pos)
	
	// a solution to a level has been found but some rules have gone unused
	// a rule is unused if it is never fully succesffuly matched, it is fine
	// if it doesn't change anything, as long as it can match, or is it?
	| unused_rule(MsgType t, loc pos)
	
	// a rule is too similar to another rule, not simply the string but
	// what it does and what it references
	| similar_rules(MsgType t, loc pos)
	;
	
public str toString(DynamicMsgs m: instant_victory(MsgType t, loc pos))
	= "Level can be won without playing interaction. <pos>";
	
	
//defaults
public default str toString(Msg m) = "Undefined message converter for <m>";	
	
public default str toString(DynamicMsgs m) = "Undefined message converter for <m>";

public default str toString(StupidSolutions m) = "Undefined message converter for <m>";
