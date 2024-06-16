/*
 * @Module: Load
 * @Desc:   Module that callows to load games in the tool
 * @Auth:   Dennis Vet    -> code
 *          Borja Velasco -> code, comments
 */
module PuzzleScript::Load

/******************************************************************************/
// --- General modules imports -------------------------------------------------
import ParseTree;
import List;
import String;
import IO;
import Type;

/******************************************************************************/
// --- Own modules import ------------------------------------------------------
import PuzzleScript::Syntax;
import PuzzleScript::AST;


/******************************************************************************/
// --- Public load functions ---------------------------------------------------

/*
 * @Name:   load
 * @Desc:   Function that reads a game file and loads its contents
 * @Param:  path -> Location of the file
 * @Ret:    GameData object
 */
GameData ps_load(loc path) {
    str src = readFile(path);
    return ps_load(src);    
}

/*
 * @Name:   load
 * @Desc:   Function that reads a game file contents and implodes it
 * @Param:  src -> String with the contents of the file
 * @Ret:    GameData object
 */
GameData ps_load(str src) {
    start[GameData] pt = ps_parse(src);
    GameData ast = ps_implode(pt);
    ast = process_game(ast);
    return ast;
}

/******************************************************************************/
// --- Public parsing functions ------------------------------------------------

/*
 * @Name:   ps_parse
 * @Desc:   Function that reads a game file and parses it
 * @Param:  
 *          path -> Location of the file
 * @Ret:    GameData object
 */
start[GameData] ps_parse(loc path){
    str src = readFile(path);
    start[GameData] pt = ps_parse(src);
    
    return pt;
}

/*
 * @Name:   ps_parse
 * @Desc:   Function that takes the contents of a game file and parses it
 * @Param:  str -> String containing the contents of the game file
 * @Ret:    GameData object
 */
start[GameData] ps_parse(str src){
    str src2 = src + "\n\n\n";            // Why do we need this (???)
    return parse(#start[GameData], src2);   // Parse takes 2 arguments: nonterminal in grammar and string to be parsed
}

/*
 * @Name:   ps_implode
 * @Desc:   Function that takes a parse tree and builds the ast for a PuzzleScript
 *          game
 * @Param:  tree -> Parse tree
 * @Ret:    GameData object
 */
GameData ps_implode(start[GameData] parse_tree) {
    GameData game = implode(#GameData, parse_tree);   // We build the AST

    // Code on how to get the comments out for validation!
    // list[tuple[loc,str]] comments =  [];
    // visit(game) {
    //     case a:rule_data(_,_,_,_): comments += [<a.src,a.comments[2][0]>];
    // }

    // println(comments);
    // println(game.sections[4].rules[3].src);
    // println(typeOf(game.sections[4].rules[3].comments));
    return game;
}


/******************************************************************************/
// --- Public process functions ------------------------------------------------

/*
 * @Name:   process_game
 * @Desc:   Function that receives an unprocessed PuzzleScript game and processes
 *          it to use it. This is the reason why in AST.rsc two different versions
 *          of GameData appear defined (the unprocessed and the processed)
 * @Param:  unprocessed_game -> GameData to be processed  
 * @Ret:    Processed GameData
 */
GameData process_game(GameData game) {
    list[PreludeData] unprocessed_prelude = [];
    list[ObjectData] unprocessed_objects = [];
    list[LegendData] unprocessed_legend = [];
    list[SoundData] unprocessed_sounds = [];
    list[LayerData] unprocessed_layers = [];
    list[RuleData] unprocessed_rules = [];
    list[ConditionData] unprocessed_conditions = [];
    list[LevelData] unprocessed_levels = [];
    
    // We transverse our AST and only leave non-empty nodes 
    // (=> replaces with the result of the right expression)
    GameData tmp_game = visit(game){
        case list[PreludeData] prelude => [p | p <- prelude, !(prelude_empty(_) := p)]
        case list[ObjectData] objects =>  [obj | obj <- objects, !(object_empty(_) := obj)]      
        case list[Section] sections => [section | section <- sections, !(s_empty(_, _, _, _) := section)]      
        case list[LegendData] legend => [l | l <- legend, !(legend_empty(_) := l)]
        case list[SoundData] sounds => [sound | sound <- sounds, !(sound_empty(_) := sound)]
        case list[LayerData] layers => [layer | layer <- layers, !(layer_empty(_) := layer)]
        case list[RuleData] rules => [rule | rule <- rules, !(rule_empty(_) := rule)]
        case list[ConditionData] conditions => [cond | cond <- conditions, !(condition_empty(_) := cond)]
        case list[LevelData] levels => [level | level <- levels, !(level_empty(_) := level)]
    };
        
    

    // Assign to correct section
    visit(tmp_game){
        case PreludeData p: unprocessed_prelude += [p];
        case Section s: section_objects(_,_,_,_): unprocessed_objects += s.objects;
        case Section s: section_legend(_,_,_,_): unprocessed_legend += s.legend;
        case Section s: section_sounds(_,_,_,_): unprocessed_sounds += s.sounds;
        case Section s: section_layers(_,_,_,_): unprocessed_layers += s.layers;
        case Section s: section_rules(_,_,_,_): unprocessed_rules += s.rules;
        case Section s: section_conditions(_,_,_,_): unprocessed_conditions += s.conditions;
        case Section s: section_levels(_,_,_,_): unprocessed_levels += s.levels;   
    }
        
    processed_prelude = [process_prelude_item(unprocessed_prelude_item) | PreludeData unprocessed_prelude_item <- unprocessed_prelude];
    processed_objects = [process_object(unprocessed_object) | ObjectData unprocessed_object <- unprocessed_objects];
    processed_legend = [process_legend(unprocessed_legend_item) | LegendData unprocessed_legend_item <- unprocessed_legend];        
    processed_sounds = [process_sound(unprocessed_sound) | SoundData unprocessed_sound <- unprocessed_sounds];
    processed_layers = [process_layer(unprocessed_layer) | LayerData unprocessed_layer <- unprocessed_layers];
    processed_rules = unprocessed_rules;
    // processed_rules  = [process_rule(unprocessed_rule) | RuleData unprocessed_rule <- unprocessed_rules];
    processed_conditions = [process_condition(unprocessed_condition) | ConditionData unprocessed_condition <- unprocessed_conditions];
    processed_levels = [process_level(unprocessed_level) | LevelData unprocessed_level <- unprocessed_levels];
        
    GameData processed_game = game_data(
        processed_prelude, 
        processed_objects, 
        processed_legend, 
        processed_sounds, 
        processed_layers, 
        processed_rules, 
        processed_conditions, 
        processed_levels
    );

    return processed_game;
}

/*
 * @Name:   process_prelude_item
 * @Desc:   Function to process a prelude item. We delete the separator at the 
 *          end of the object
 * @Param:  unprocessed_prelude_item -> Prelude item to be processed
 * @Ret:    Processed prelude item
 */
PreludeData process_prelude_item(PreludeData unprocessed_prelude_item) {
    PreludeData processed_prelude_item = prelude_data(
        unprocessed_prelude_item.keywrd,
        unprocessed_prelude_item.params
    );
    return processed_prelude_item;
}

/*
 * @Name:   process_object
 * @Desc:   Function that processes an object. It transforms the sprite from an
 *          Sprinte object to a list[list[Pixel]] which is easier for representation.
 *          Instead of creating another definition for Sprite to hold a processed
 *          sprite, we avoid this to improve in code reading. Creating a new 
 *          sprite definition would be like:
 *              sprite(list[list[Pixel]] pixels)
 *          So to access each pixel we would need to do:
 *              obj.sprite.pixels[i][j].color_number 
 *          Which is less clean than:
 *              obj.sprinte[i][j].color_number
 * @Param:  unprocessed_object -> Object to be processed
 * @Ret:    Processed ObjectData object
 */
ObjectData process_object(ObjectData unprocessed_object){
    list[list[Pixel]] processed_sprite = [];

    if (size(unprocessed_object.spr) > 0) {;
        processed_sprite += [
            [pixel(x) | x <- split("", unprocessed_object.spr[0].line0)],
            [pixel(x) | x <- split("", unprocessed_object.spr[0].line1)],
            [pixel(x) | x <- split("", unprocessed_object.spr[0].line2)],
            [pixel(x) | x <- split("", unprocessed_object.spr[0].line3)],
            [pixel(x) | x <- split("", unprocessed_object.spr[0].line4)]
        ];
    }    

    ObjectData processed_object = object_data(
        unprocessed_object.name,
        unprocessed_object.rep_char, 
        unprocessed_object.colors, 
        processed_sprite
    );

    return processed_object;
}

/*
 * @Name:   process_legend
 * @Desc:   Function to process legend elements. It converts them into 
 *          specific types that refer to when they use ANDs, ORs or both 
 *          (We consider the last errors, but do not stop the engine)
 * @Param:  unprocessed_legend Unprocessed legend element   
 * @Ret:    Processed LegendData element
 */
LegendData process_legend(LegendData unprocessed_legend) {
    list[str] items = [unprocessed_legend.first_item];
    list[str] alias_items = [];
    list[str] combined_items = [];
        
    for (LegendOperation other <- unprocessed_legend.other_items) {
        switch(other){
            case legend_or(item): alias_items += item;
            case legend_and(item): combined_items += item;
        }
    }

    LegendData processed_legend = legend_reference(unprocessed_legend.key, items + alias_items);;
    if (size(alias_items) > 0 && size(combined_items) > 0) {
        processed_legend = legend_error(unprocessed_legend.key, items + alias_items + combined_items);
    } 
    else if (size(combined_items) > 0) {
        processed_legend = legend_combined(unprocessed_legend.key, items + combined_items);
    } 

    return processed_legend;
}

/*
 * @Data:   process_sound
 * @Desc:   Function to process a sound. We just delete the separator at the end
 * @Param:  unprocessed_sound -> Sound to be processed
 * @Ret:    Processed sound
 */
SoundData process_sound(SoundData unprocessed_sound) {
    SoundData processed_sound = sound_data(
        unprocessed_sound.sound
    );
    return processed_sound;
}

/*
 * @Name:   process_layer
 * @Desc:   Function to process a layer element. We do so to delete "," from the 
 *          end of the layer items in case it was used to separate them
 * @Param:  unprocessed_layer -> Unprocessed layer   
 * @Ret:    Processed LayerData object
 */
LayerData process_layer(LayerData unprocessed_layer) {
    list[str] processed_items = [];
    for (str name <- unprocessed_layer.items){
        // flexible grammar parses the optional "," separator as a character so we remove it
        // in post processing if it exists
        if (name[-1] == ",") {
            processed_items += [name[0..-1]];
        } else {
            processed_items += [name];
        }
    }

    LayerData processed_layer = layer_data(
        processed_items
    );
    return processed_layer;
}

/*
 * @Data:   process_rule (rule_data)
 * @Desc:   Function to process a rule
 * @Param:  unprocessed_rule-> Rule to be processed
 * @Ret:    Processed rule
 */
RuleData process_rule(RuleData unprocessed_rule : rule_data(list[RulePart] left, list[RulePart] right, list[str] message, str _)) {
    RuleData processed_rule = rule_data(
        unprocessed_rule.left,
        unprocessed_rule.right,
        unprocessed_rule.message
    );
    return processed_rule;
}

/*
 * @Data:   process_rule (rule_loop)
 * @Desc:   Function to process a rule
 * @Param:  unprocessed_rule-> Rule to be processed
 * @Ret:    Processed rule
 */
RuleData process_rule(RuleData unprocessed_rule : rule_loop(list[RuleData] rules, str _)) {
    RuleData processed_rule = rule_loop(
        unprocessed_rule.rules
    );
    return processed_rule;
}

/*
 * @Data:   process_sound
 * @Desc:   Function to process a condition. We just delete the separator at the 
 *          end
 * @Param:  unprocessed_condition -> Condition to be processed
 * @Ret:    Processed condition
 */
ConditionData process_condition(ConditionData unprocessed_condition) {
    ConditionData processed_condition = condition_data(
        unprocessed_condition.items
    );
    return processed_condition;
}

/*
 * @Name:   process_level (level_data version)
 * @Desc:   Function to process a level that is really a message. We do not care
 *          about messages right now, so we do nothing. We only define this to 
 *          prevent the tool from breaking when processing levels
 * @Param:  unprocessed_level_message   Level message to be processed
 * @Ret:    Processed LevelData with the message
 */
LevelData process_level(LevelData unprocessed_level : level_data(list[tuple[str, str]] lines, str _)) {
    LevelData processed_level = level_data([x[0] | x <- lines]);
    return processed_level;
}

/*
 * @Name:   process_level (general version)
 * @Desc:   Function to process a level that is not a level (message or empty). 
 *          We only define this to prevent the tool from breaking when processing
 *          real levels
 * @Param:  unprocessed_level   Level to be processed
 * @Ret:    Processed LevelData object
 */
LevelData process_level(LevelData unprocessed_level) {
    return unprocessed_level;
}