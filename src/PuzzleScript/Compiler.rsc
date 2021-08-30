module PuzzleScript::Compiler

import String;
import List;
import Type;
import Set;
import PuzzleScript::Checker;
import PuzzleScript::AST;
import PuzzleScript::Utils;

alias Line = list[Object];

data Layer
	= layer(list[Line] lines, list[str] layer, list[str] objects)
	;

data Level
	= level(
		list[Layer] layers, 
		list[list[Layer]] states,
		int checkpoint,
		LEVELDATA original
	)
	| message(str msg, LEVELDATA original)
	;
	
data Object
	= player(str name, str legend)
	| moving_player(str name, str legend, str direction)
	| object(str name, str legend)
	| moving_object(str name, str legend, str direction)
	| transparent(str name, str legend)
	;
	
data Command
	= message(str string)
	| sound(str event)
	| cancel()
	| checkpoint()
	| restart()
	| win()
	| again()
	;

	
alias Rule = tuple[
	bool late,
	set[Command] commands,
	set[str] directions,
	list[RulePart] left,
	list[RulePart] right,
	RULEDATA original
];

Rule new_rule(RULEDATA r)
	= <
		false, 
		{}, 
		{}, 
		[], 
		[], 
		r
	>;

alias Engine = tuple[
	list[Level] levels,
	Level current_level,
	map[str, list[int]] sounds,
	list[Condition] conditions,
	list[Rule] rules,
	int index,
	bool win_keyword,
	bool abort,
	bool again,
	list[str] sound_queue,
	list[str] msg_queue
];

Engine new_engine()		
	= <
		[], 
		level([], [], 0, level_data([])), 
		(), 
		[], 
		[], 
		0, 
		false, 
		false, 
		false, 
		[], 
		[]
	>;

set[str] generate_directions(list[str] modifiers){
	set[str] directions = {};
	for (str mo <- modifiers){
		if (mo == "vertical") directions += {"up", "down"};
		if (mo == "horizontal") directions += {"left", "right"};
		if (mo in ["left", "right", "down", "up"]) directions += {mo};
	}
	
	if (isEmpty(directions)) return {"left", "right", "up", "down"};
	return directions;
}

Rule convert_rule(RULEDATA r, Checker c){
	Rule rule = new_rule(r);

	list[str] keywords = [toLowerCase(x.prefix) | RULEPART x <- r.left, x is prefix];
	rule.late = "late" in keywords;
	rule.directions = generate_directions(keywords);
	
	for (RULEPART p <- r.left){
		rule = convert_rulepart(p, rule, c, true);
	}
	
	for (RULEPART p <- r.right){
		rule = convert_rulepart(p, rule, c, false);
	}


	if (!isEmpty(r.message)) rule.commands += {Command::message(r.message[0])};
	
	return rule;
}

alias RuleReference = tuple[
	list[str] objects,
	str force
];

alias RuleContent = list[RuleReference];
alias RulePart = list[RuleContent];

Rule convert_rulepart( RULEPART p: part(list[RULECONTENT] _), Rule rule, Checker c, bool pattern) {
	list[RuleContent] contents = [];
	for (RULECONTENT cont <- p.contents){
		RuleContent refs = [];

		for (int i <- [0..size(cont.content)]){
			if (toLowerCase(cont.content[i]) in rulepart_keywords) continue;
			list[str] objs = resolve_reference(cont.content[i], c, p@location).objs;
			str modifier = "none";
			if (i != 0 && toLowerCase(cont.content[i-1]) in rulepart_keywords) modifier = toLowerCase(cont.content[i-1]);
			
			refs += [<objs, modifier>];
		}
		
		contents += [refs];
	}
	
	if (pattern){ 
		rule.left += [contents];
	} else {
		rule.right += [contents];
	}

	return rule;
}

Rule convert_rulepart( RULEPART p: prefix(str _), Rule rule, Checker c, bool pattern) {
	return rule;
}

Rule convert_rulepart( RULEPART p: command(str cmd), Rule rule, Checker c, bool pattern) {
	switch(cmd){
		case /cancel/: rule.commands += {Command::cancel()};
		case /checkpoint/: rule.commands += {Command::checkpoint()};
		case /restart/: rule.commands += {Command::restart()};
		case /win/: rule.commands += {Command::win()};
		case /again/: rule.commands += {Command::again()};
	}
	
	return rule;
}

Rule convert_rulepart( RULEPART p: sound(str snd), Rule rule, Checker c, bool pattern) {
	rule.commands += {Command::sound(snd)};

	return rule;
}

Object new_transparent() = transparent("trans", ".");

Level convert_level(LEVELDATA l: level_data(list[str] level), Checker c){
	list[Layer] layers = [];
	for (LAYERDATA lyr <- c.game.layers){
		list[str] objs = resolve_references(lyr.layer, c, lyr@location).objs;
		list[Line] layer = [];
		list[str] objects = [];
		for (str charline <- l.level){
			Line line = [];
			list[str] chars = split("", charline);
			for (str ch <- chars){
				list[str] obs = resolve_reference(ch, c, lyr@location).objs;
				pix = [x | str x <- obs, x in objs];
				if (isEmpty(pix)){
					line += [new_transparent()];
				} else {
					line += [object(pix[0], ch)];
					objects += [pix[0]];
				}
			}
			
			layer += [line];
		}
		
		layers += [Layer::layer(layer, objs, objects)];
	}
	
	return Level::level(layers, [], 0, l);
}

Level convert_level(LEVELDATA l: message(str msg), Checker c){
	return Level::message(msg, l);
}

Engine compile(Checker c){
	Engine engine = new_engine();
	
	for (LEVELDATA l <- c.game.levels){
		engine.levels += [convert_level(l, c)];
	}
	
	engine.sounds = (x : c.sound_events[x].seeds | x <- c.sound_events);
	engine.conditions = c.conditions;
	engine.current_level = engine.levels[0];
	
	for (RULEDATA r <- c.game.rules){
		engine.rules += [convert_rule(r, c)];
	}
	
	return engine;
}

