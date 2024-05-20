/* 
 * (DEPRECATED: No documentation added)
 * @Module: Analyser    
 * @Desc:   Module to perform dynamic analysis 
 * @Auth:   Clement Julia -> code
 */

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

data RuleType (loc src = |unknown:///|)
    = transform_items(list[str] left, list[str] right) // transforms items (movement)
    | remove_items(list[str] left, list[str] right) // deletes items
    | add_items(list[str] left, list[str] right) //add items
    ;

//This checker does not check for code bug it checks for "gameplay" bugs, which means 
// unintended behavior in the game caused by valid code but unintended interactions
DynamicChecker new_dynamic_checker()
    = <[], [], []>
    ;
    
RuleType get_rule_type(Rule rule){
    list[str] refs_right = [];
    list[str] refs_left = [];
    for (RulePartLol rp <- rule.converted_left){
        for (RuleContent cont <- rp){
            if (!(cont is references)) continue;
            
            for (RuleReference ref <- cont.refs){
                if (ref.force == "no") continue;
                refs_left += ref.objects;
                    
            }
        }
    }
    
    for (RulePartLol rp <- rule.converted_right){
        for (RuleContent cont <- rp){
            if (!(cont is references)) continue;
            
            for (RuleReference ref <- cont.refs){
                if (ref.force == "no") continue;
                refs_right += ref.objects;
                    
            }
        }
    }
    
    if (size(refs_right) < size(refs_left)) return remove_items(refs_left, refs_right);
    if (size(refs_left) < size(refs_right)) return add_items(refs_left, refs_right);
    
    return transform_items(refs_left, refs_right);
}

DynamicChecker check_ruleability(DynamicChecker c, Condition cond, Level level, list[RuleType] rule_types, list[str] objs){
    if (objs == level.player) return c;
    // if the object is not already present we check if it can be spawned
    if (!any(str obj <- objs, obj in level.objectdata)) {
        if (!any(
        str obj <- objs, 
        any(
            RuleType rule <- rule_types, 
            !(obj in rule.left) && obj in rule.right
        )
    )) c.msgs += [missing_objects(objs, warn(), level.original.src)];
    }
    
    return c;
}

DynamicChecker anaylyse_impossible_victory(DynamicChecker c, Engine engine, Level level){
    if (level is message) return c;
    list[RuleType] rule_types = [get_rule_type(x) | Rule x <- engine.rules];
    
    for (Condition cond <- engine.conditions){
        switch (cond){
            case all_objects_on(list[str] objs, list[str] on, ConditionData _): {
                c = check_ruleability(c, cond, level, rule_types, objs);
                c = check_ruleability(c, cond, level, rule_types, on);
            }
        }
    }

    return c;
}

DynamicChecker analyse_unrulable_condition(DynamicChecker c, Engine engine, Condition cond){
    list[RuleType] rule_types = [get_rule_type(x) | Rule x <- engine.rules];
    
    switch (cond){
        case no_objects: {
            // if not all objects in the condition have a rule that allows them to
            // remove the object then we raise a warning
            // we assume that if there is a no_object condition by default that means all the
            // levels have that objects
            if (!all(
                str obj <- cond.objects, 
                any(
                    RuleType rule <- rule_types, 
                    obj in rule.left && !(obj in rule.right)
                )
            )) c.msgs += [unrulable_condition(warn(), cond.original.src)];
        }
        case no_objects_on: ; // check if objects can disappear or move
        case some_objects: {
            if (!any(
                str obj <- cond.objects, 
                any(
                    RuleType rule <- rule_types, 
                    !(obj in rule.left) && obj in rule.right
                )
            )) c.msgs += [unrulable_condition(warn(), cond.original.src)];
        }
        case some_objects_on: ; // check if objects can appear or move
        case all_objects_on: ; // check if objects can appear or move
    }
    
    return c;
}

//errors
//    instant_victory
//  condition_met
DynamicChecker analyse_instant_victory(DynamicChecker c, Engine engine, Level l){
    if (!(l is level)) return c;    
    if (is_victorious(engine, l)) {
        c.msgs += [instant_victory(warn(), l.original.src)];
    } else {
        for (Condition cond <- engine.conditions){
            if (is_met(cond, l)) c.msgs += [condition_met(cond.original.src, warn(), l.original.src)];
        }
    }
    
    return c;
}

DynamicChecker analyse_rules(DynamicChecker c, Rule r1, Rule r2){
    if (any(RulePartLol x <- r1.converted_left, x in r2.converted_left)){
         c.msgs += [similar_rules("left", warn(), r2.original.src, r1.original.src)];
         c.msgs += [similar_rules("left", warn(), r1.original.src, r2.original.src)];
    }
    
    if (any(RulePartLol x <- r1.converted_right, x in r2.converted_right)) {
        c.msgs += [similar_rules("right", warn(), r2.original.src, r1.original.src)];
        c.msgs += [similar_rules("right", warn(), r1.original.src, r2.original.src)];
    }
    
    return c;
}


DynamicChecker analyse_difficulty(DynamicChecker c, list[Level] levels){
    list[int] level_sizes = [];
    list[int] object_sizes = [];

    for (int i <- [0..size(levels)]){
        Level level = levels[i];
        if (level is message) continue;
        
        int level_size = level.size.height * level.size.width;
        int object_size = size([x | x <- level.objectdata, x notin level.background]);
        
        real size_check = 0.0;
        real object_check = 0.0;
        if (!isEmpty(level_sizes)){
            size_check = mean(level_sizes);
            object_check = mean(object_sizes);
        }
        
        //if ((size_check + object_check) <= 0 ){
        //    c.msgs += [difficulty_not_increasing(warn(), level.original.src)];
        //}
        
        //instead of trying to create a difficulty metrics that probably wouldn't work we just give the raw stats to the user
        c.msgs += [metrics(level_size, object_size, size_check, object_check, warn(), level.original.src)];
        
        
        level_sizes += [level_size];
        object_sizes += [object_size];
    }
    
    return c;
}

DynamicChecker analyse_impossible_conditions(DynamicChecker c, list[Condition] conditions){
    // impossible conditions
    //    SOME X and NO X
    //  SOME X ON Y and NO X ON Y
    //  ALL X ON Y and NO X ON Y
    // ALL X ON Y and SOME X ON Y
    
    for (int i <- [0..size(conditions)]){
        for (int j <- [0..size(conditions)]){
            if (i == j) continue;
            Condition c1 = conditions[i];
            Condition c2 = conditions[j];

            if (c1 is some_objects && c2 is no_objects){
                if (any(str obj <- c1.objects, obj in c2.objects)) c.msgs += [impossible_victory(<c1.original.src, c2.original.src>, error(), c1.original.src)];
            } else if (c2 is no_objects_on && (c1 is some_objects_on || c1 is all_objects_on)){
                if (any(str obj <- c1.objects, obj in c2.objects) && any(str obj <- c1.on, obj in c2.on)) c.msgs += [impossible_victory(<c1.original.src, c2.original.src>, error(), c1.original.src)];
            } else if (c1 is all_objects_on && c2 is some_objects_on) {
                if (any(str obj <- c1.objects, obj in c2.objects) && any(str obj <- c1.on, obj in c2.on)) c.msgs += [impossible_victory(<c1.original.src, c2.original.src>, error(), c1.original.src)];
            }
        }
    }
    
    
    return c;
}

DynamicChecker analyse_game(Engine engine){
    DynamicChecker c = new_dynamic_checker();

    for (Level level <- engine.levels){
        if (level is message) continue;
        
        c = analyse_instant_victory(c, engine, level);
        c = anaylyse_impossible_victory(c, engine, level);
    }
    
    for (int i_r1 <- [0..size(engine.rules)]){
        for (int i_r2 <- [i_r1+1..size(engine.rules)]){
            c = analyse_rules(c, engine.rules[i_r1], engine.rules[i_r2]);
        }
    }
    
    for (Condition cond <- engine.conditions){
        c = analyse_unrulable_condition(c, engine, cond);
    }
    
    c = analyse_impossible_conditions(c, engine.conditions);
    c = analyse_difficulty(c, engine.levels);
    
    
    return c;
}

DynamicChecker analyse_unidirectional_solution(DynamicChecker c, Engine engine, Level level){
    println("ASDFASDFASDFASDFASDFASDFASDFASDFASDFASDF");

    for (str dir <- ["down", "left", "right", "up"]){        
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
            list[Layer] previous_layers = deep_copy(level.layers);
            <engine, level> = do_turn(engine, level, dir);
            victory = is_victorious(engine, level);
            print_level(level);
            if (victory || previous_layers == level.layers) break;
        }
        
        level.layers = old_layers;
        
        if (victory) {
             c.solutions += [unidirectional(dir, warn(), level.original.src)];
             println(toString(unidirectional(dir, warn(), level.original.src)));
             return c;
        }
    }
    
    return c;
}

DynamicChecker analyse_stupid_solution(Engine engine){
    DynamicChecker c = new_dynamic_checker();
    
    for (Level level <- engine.levels){
        if (level is message) continue;
        
        c = analyse_unidirectional_solution(c, engine, level);
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
