module PuzzleScript::Analyser

import PuzzleScript::Messages;
import PuzzleScript::Compiler;
import PuzzleScript::AST;
import PuzzleScript::Engine;
import PuzzleScript::Checker;

import IO;
import List;
import analysis::statistics::Descriptive;
	
alias DynamicChecker = tuple[
	list[StupidSolutions] solutions,
	list[DynamicMsg] msgs,
	list[int] difficulty
];

data RuleType 
	= transform_items(list[list[str]] objects) // transforms items (movement)
	| remove_items(list[list[str]] objects) // deletes items
	| add_items(list[list[str]] objects) //add items
	;

//This checker does not check for code bug it checks for "gameplay" bugs, which means 
// unintended behavior in the game caused by valid code but unintended interactions
DynamicChecker new_dynamic_checker()
	= <[], [], []>
	;
	
RuleType get_rule_type(Rule rule){
	list[list[str]] refs_right = [];
	list[list[str]] refs_left = [];
	for (RulePart rp <- rule.converted_left){
		for (RuleContent cont <- rp){
			if (!(cont is references)) continue;
			
			for (RuleReference ref <- cont.refs){
				if (ref.force == "no") continue;
				refs_left += [ref.objects];
					
			}
		}
	}
	
	for (RulePart rp <- rule.converted_right){
		for (RuleContent cont <- rp){
			if (!(cont is references)) continue;
			
			for (RuleReference ref <- cont.refs){
				if (ref.force == "no") continue;
				refs_right += [ref.objects];
					
			}
		}
	}
	
	if (size(refs_right) < size(refs_left)) return remove_items(refs_right & refs_left);
	if (size(refs_left) < size(refs_right)) return add_items(refs_right & refs_left);
	
	return transform_items(refs_right & refs_left);
}

list[RuleType] get_victory_requirements(Level level, Condition _ : no_objects(list[str] objects, _)){
	return [remove_items([objects])];
}

list[RuleType] get_victory_requirements(Level level, Condition _ : some_objects(list[str] objects, _)){
	return [add_items([objects])];
}

list[RuleType] get_victory_requirements(Level level, Condition _ : no_objects_on(list[str] objects, list[str] on, CONDITIONDATA original)){
	return [transform_items([objects, on]), remove_items([objects, on])];
}

list[RuleType] get_victory_requirements(Level level, Condition _ : all_objects_on(list[str] objects, list[str] on, CONDITIONDATA original)){
	return [transform_items([objects, on]), add_items([objects, on])];
}

list[RuleType] get_victory_requirements(Level level, Condition _ : some_objects_on(list[str] objects, list[str] on, CONDITIONDATA original)){
	return [transform_items([objects, on]), add_items([objects, on])];
}

DynamicChecker anaylyse_impossible_victory(DynamicChecker c, Engine engine, Level level){
	list[RuleType] rule_types = [get_rule_type(x) | Rule x <- engine.rules];
	list[list[RuleType]] needed_rules = [];
	
	for (Condition cond <- engine.conditions){
		needed_rules += [get_victory_requirements(level, cond)];
	}
	
	for (int i <- [0..size(needed_rules)]){
			list[RuleType] nd = needed_rules[i];
			if (!any(RuleType rt <- nd, rt notin rule_types)) c.msgs += [unsolvable_rules_missing_items(warn(), engine.conditions[i].original@location, level.original@location)];
		
	}

	return c;
}

//errors
//	instant_victory
DynamicChecker analyse_instant_victory(DynamicChecker c, Engine engine, Level l){
	if (!(l is level)) return c;	
	if (is_victorious(engine, l)) c.msgs += [instant_victory(warn(), l.original@location)];
	
	return c;
}

DynamicChecker analyse_rules(DynamicChecker c, Rule r1, Rule r2){
	if (any(RulePart x <- r1.converted_left, x in r2.converted_left)) c.msgs += [similar_rules(warn(), r1.original@location)];
	if (any(RulePart x <- r1.converted_right, x in r2.converted_right)) c.msgs += [similar_rules(warn(), r1.original@location)];
	
	return c;
}


DynamicChecker analyse_difficulty(DynamicChecker c, list[Level] levels){
	list[int] level_sizes = [];
	list[int] object_sizes = [];

	for (int i <- [0..size(levels)]){
		Level level = levels[i];
		int level_size = level.size.height * level.size.width;
		int object_size = size(level.objectdata);
		
		real size_check = 0.0;
		real object_check = 0.0;
		if (!isEmpty(level_sizes)){
			size_check = level_size - mean(level_sizes);
			object_check = object_size - mean(object_sizes);
		}
		
		if ((size_check + object_check) > 0 ){
			c.msgs += [difficulty_not_increasing(warn(), level.original@location)];
		}
		
		
		level_sizes += [level_size];
		object_sizes += [object_size];
	}
	
	return c;
}

DynamicChecker analyse_impossible_conditions(DynamicChecker c, list[Condition] conditions){
	// impossible conditions
	//	SOME X and NO X
	//  SOME X ON Y and NO X ON Y
	//  ALL X ON Y and NO X ON Y
	// ALL X ON Y and SOME X ON Y
	
	for (Condition c1 <- conditions){
		for (Condition c2 <- conditions){
			if (c1 is some_objects && c2 is no_objects){
				if (any(str obj <- c1.objects, obj in c2.objects)) c.msgs += [impossible_victory(<c1.original@location, c2.original@location>, warn(), c1.original@location)];
			} else if (c2 is no_objects_on && (c1 is some_objects_on || c1 is all_objects_on)){
				if (any(str obj <- c1.objects, obj in c2.objects) && any(str obj <- c1.on, obj in c2.on)) c.msgs += [impossible_victory(<c1.original@location, c2.original@location>, warn(), c1.original@location)];
			} else if (c1 is all_objects_on && c2 is some_objects_on) {
				if (any(str obj <- c1.objects, obj in c2.objects) && any(str obj <- c1.on, obj in c2.on)) c.msgs += [impossible_victory(<c1.original@location, c2.original@location>, warn(), c1.original@location)];
			}
		}
	}
	
	
	return c;
}

DynamicChecker analyse_game(Engine engine){
	DynamicChecker c = new_dynamic_checker();

	for (Level level <- engine.levels){
		c = analyse_instant_victory(c, engine, level);
		c = anaylyse_impossible_victory(c, engine, level);
	}
	
	for (int i_r1 <- [0..size(engine.rules)]){
		for (int i_r2 <- [i_r1+1..size(engine.rules)]){
			c = analyse_rules(c, engine.rules[i_r1], engine.rules[i_r2]);
		}
	}
	c = analyse_impossible_conditions(c, engine.conditions);
	c = analyse_difficulty(c, engine.levels);
	
	
	return c;
}

DynamicChecker analyse_unidirectional_solution(DynamicChecker c, Engine engine, str dir){
	for (Level level <- engine.levels){
		list[Layer] old_layers = deep_copy(level.layers);
		int loops = 0;
		int MAX_LOOPS = 0;
		
		if(dir in ["left", "right"]) {
			MAX_LOOPS = level.size.width * 2;
		} else {
			MAX_LOOPS = level.size.height * 2;
		}
		
		bool victory = false;
		for (int _ <- [0..MAX_LOOPS]){
			<engine, level> = do_turn(engine, level, dir);
			victory = is_victorious(engine, level);
			if (victory) break;
		}
		
		if (victory) c.solutions += [unidirectional(dir, warn(), level.original@location)];
		
		level.layers = old_layers;
	}
	
	return c;
}

DynamicChecker analyse_stupid_solution(Engine engine){
	DynamicChecker c = new_dynamic_checker();
	
	for (str dir <- ["left", "right", "up", "down"]){
		c = analyse_unidirectional_solution(c, engine, dir);
	}
	
	return c;
	
}

void print_msgs(DynamicChecker checker){
	list[DynamicMsg] error_list = [x | DynamicMsg x <- checker.msgs, x.t == error()];
	list[DynamicMsg] warn_list  = [x | DynamicMsg x <- checker.msgs, x.t == warn()];
	list[DynamicMsg] info_list  = [x | DynamicMsg x <- checker.msgs, x.t == info()];
	
	if (!isEmpty(error_list)) {
		println("ERRORS");
		for (DynamicMsg msg <- error_list) {
			println(toString(msg));
		}
	}
	
	if (!isEmpty(warn_list)) {
		println("WARNINGS");
		for (DynamicMsg msg <- warn_list) {
			println(toString(msg));
		}
	}
	
	if (!isEmpty(info_list)) {
		println("INFO");
		for (DynamicMsg msg <- info_list) {
			println(toString(msg));
		}
	}
	
	if (!isEmpty(checker.solutions)){
		println("SOLUTIONS");
		for (StupidSolutions msg <- checker.solutions){
			println(toString(msg));
		}
	}
}
