module PuzzleScript::Messages

import IO;
import PuzzleScript::AST;
import String;

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
	| invalid_sprite(str name, str line, MsgType t, loc pos)
	| invalid_level_row(MsgType t, loc pos)
	| invalid_sound_length(MsgType t, loc pos)
	| invalid_condition_length(MsgType t, loc pos)
	| invalid_condition(MsgType t, loc pos)
	| invalid_condition_verb(str condition, MsgType t, loc pos)
	| invalid_object_type(str word, str obj, MsgType t, loc pos)
	| invalid_prelude_key(str key, MsgType t, loc pos)
	| invalid_prelude_value(str key, str v, str tp, MsgType t, loc pos)
	
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
	
	| unlayered_objects(str objects, MsgType t, loc pos)
	| ambiguous_pixel(str legend, list[str] objs, MsgType t, loc pos)
	| reserved_keyword(str k, MsgType t, loc pos)
	| self_reference(str name, MsgType t, loc pos)
	| mask_not_directional(str mask, MsgType t, loc pos)
	| impossible_condition_duplicates(list[str] dup_objects, MsgType t, loc pos)
	| impossible_condition_unstackable(list[str] lay_objects, MsgType t, loc pos)
	| missing_prelude_value(str key, MsgType t, loc pos)
	//warnings
	| unused_colors(str name, str colors, MsgType t, loc pos)
	| no_levels(MsgType t, loc pos)
	| message_too_long(MsgType t, loc pos)
	| existing_sound(str sound, MsgType t, loc pos)
	;
	
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
	= "Invalid name <name>, please only use characters appropriate for that section and not reserved keywords. <pos>";
	
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
	
public str println(Msg m: invalid_sound_verb(str verb, MsgType t, loc pos))
	= "Unrecognized sound verb <verb> in sound definition";
	
public str println(Msg m: invalid_sound_seed(str sound, MsgType t, loc pos))
	= "Invalid sound seed <sound>. <pos>";
	
public str println(Msg m: invalid_sound_length(MsgType t, loc pos))
	= "Invalid amount of sound verbs. <pos>";
	
public str println(Msg m: generic(str msg, MsgType t, loc pos))
	= "<msg> <pos>";
	
public str println(Msg m: mask_not_directional(str mask, MsgType t, loc pos))
	= "Can\'t use directional keywords if mask is not \'move\' or \'cantmove\', mask is currently <mask>. <pos>";

public str println(Msg m: existing_mask(str new_mask, str existing_mask, MsgType t, loc pos))
	= "Mask already defined as <existing_mask> can\'t also define it as <new_mask>. <pos>";
	
public str println(Msg m: existing_sound_seed(str new_seed, str existing_seed, MsgType t, loc pos))
	= "Sound seed already defined as <existing_seed> can\'t also define it as <new_seed>. <pos>";

public str println(Msg m: existing_sound_object(MsgType t, loc pos))
	= "Objects for this sound have already been defined. <pos>";
	
public str println(Msg m: undefined_sound_seed(MsgType t, loc pos))
	= "No sound seed defined. <pos>";
	
public str println(Msg m: undefined_sound_mask(MsgType t, loc pos))
	= "No sound mask defined. <pos>";
	
public str println(Msg m: undefined_sound_objects(MsgType t, loc pos))
	= "No objects defined for sound. <pos>";
	
public str println(Msg m: existing_sound(str sound, MsgType t, loc pos))
	= "Sound event like <sound> already registered. <pos>";
	
public str println(Msg m: invalid_condition_length(MsgType t, loc pos))
	= "Invalid amount of condition verbs. <pos>";
	
public str println(Msg m: invalid_condition(MsgType t, loc pos))
	= "Must use additional objects with \'all\' keyword";
	
public str println(Msg m: invalid_condition_verb(str verb, MsgType t, loc pos))
	= "Invalid win condition verb <verb>. <pos>";
	
public str println(Msg m: invalid_object_type(str word, str obj, MsgType t, loc pos))
	= "Cannot use <word> here. <pos>";
	
public str println(Msg m: impossible_condition_duplicates(list[str] dup_objects, MsgType t, loc pos))
	= "Objects <dup_objects> cannot be \'on\' themselves. <pos>";
	
public str println(Msg m: impossible_condition_unstackable(list[str] lay_objects, MsgType t, loc pos))
	= "Objects <lay_objects> are meant to stack but appear in the same layer. <pos>";

public str println(Msg m: invalid_prelude_key(str key, MsgType t, loc pos))
	= "Invalid prelude keyword <key>. <pos>";
	
public str println(Msg m: existing_prelude_key(str key, MsgType t, loc pos))
	= "Prelude keyword <key> already defined. <pos>";
	
public str println(Msg m: missing_prelude_value(str key, MsgType t, loc pos))
	= "Missing prelude value for key <key>. <pos>";
	
public str println(Msg m: invalid_prelude_value(str key, str v, str tp, MsgType t, loc pos))
	= "Expected <tp> for <key> but found <v>. <pos>";

public default str println(Msg m) = "Undefined message converter";