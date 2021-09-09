module PuzzleScript::Utils

import String;

public str RIGHT = "right";
public str LEFT = "left";
public str UP = "up";
public str DOWN = "down";

public list[str] directional_sound_masks = ["move", "cantmove"];
public list[str] sound_masks = ["create", "destroy", "action"] + directional_sound_masks;
public list[str] absolute_directions_single = ["left", "right", "down", "up"];
public list[str] sound_keywords = sound_masks + absolute_directions_single; 

public list[str] conditions = ["all", "some", "no", "any"];
public list[str] condition_keywords = conditions + ["on"];

public list[str] rulepart_random = ["randomdir","random"];
public list[str] relative_directions_single = ["^","v","\>","\<"];
public list[str] relative_directions_duo = ["parallel", "perpendicular"];
public list[str] relative_directions = relative_directions_single + relative_directions_duo;
public list[str] absolute_directions = ["horizontal", "vertical"] + absolute_directions_single;
public list[str] rulepart_keywords_other = [
	"...", "moving","stationary","parallel","perpendicular", "action", "no"
];
public list[str] rulepart_keywords = 
	rulepart_random + 
	absolute_directions + 
	relative_directions +
	rulepart_keywords_other;

public list[str] rule_prefix = ["late", "random", "rigid"] + absolute_directions;
public list[str] rule_commands = ["cancel", "checkpoint", "restart", "win"];
public list[str] rule_keywords = rulepart_keywords + rule_prefix + rule_commands;


public list[str] section_headers = [
	"objects", "collisionlayers", "legend", "sounds", "rules",
	"winconditions", "levels"
];

public list[str] sound_events = [
	"titlescreen", "startgame", "cancel", "endgame", "startlevel", "undo", "restart", 
	"endlevel", "showmessage", "closemessage", 
	"sfx0", "sfx1", "sfx2", "sfx3", "sfx4", "sfx5", "sfx6", "sfx7", "sfx8", "sfx9", "sfx10"
];

public list[str] prelude_with_arguments_str_dim = ["flickscreen","zoomscreen"];

public list[str] prelude_with_arguments_str_color = ["background_color","text_color"];

public list[str] prelude_with_arguments_str = [
	"title","author","homepage", "color_palette","youtube"
] + prelude_with_arguments_str_color + prelude_with_arguments_str_dim;

public list[str] prelude_with_arguments_int = [
	"key_repeat_interval", "realtime_interval","again_interval"
];

public list[str] prelude_with_arguments = prelude_with_arguments_str + prelude_with_arguments_int;

public list[str] prelude_without_arguments = [
	"run_rules_on_level_start","norepeat_action","require_player_movement","debug",
	"verbose_logging","throttle_movement","noundo","noaction","norestart","scanline"
];

public list[str] prelude_keywords = prelude_with_arguments + prelude_without_arguments; 

public list[str] keywords = 
	condition_keywords + 
	sound_keywords +
	prelude_keywords +
	sound_events +
	rule_keywords +
	section_headers +
	["message"]
;


public bool check_valid_sound(str sound){
	try
		int s = toInt(sound);
	catch IllegalArgument: return false;
	return s > 0;
}
