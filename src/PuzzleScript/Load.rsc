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

/******************************************************************************/
// --- Own modules import ------------------------------------------------------
import PuzzleScript::Syntax;
import PuzzleScript::AST;
import PuzzleScript::Utils;


/******************************************************************************/
// --- Public load functions ---------------------------------------------------

/*
 * @Name:   load
 * @Desc:   Function that reads a game file and loads its contents
 * @Param:  
 *          path -> Location of the file
 * @Ret:    PSGame object
 */
PuzzleScript::AST::PSGame load(loc path) {
    str src = readFile(path);
    return load(src);    
}

/*
 * @Name:   load
 * @Desc:   Function that reads a game file contents and implodes it
 * @Param:  
 *          src -> String with the contents of the file
 * @Ret:    PSGame object
 */
PuzzleScript::AST::PSGame load(str src) {
    start[PSGame] pt = ps_parse(src);
    PuzzleScript::AST::PSGame ast = ps_implode(pt);
    return ast;
}

/******************************************************************************/
// --- Public parsing functions ------------------------------------------------

/*
 * @Name:   ps_parse
 * @Desc:   Function that reads a game file and parses it
 * @Param:  
 *          path -> Location of the file
 * @Ret:    PSGame object
 */
start[PSGame] ps_parse(loc path){
    str src = readFile(path);
    start[PSGame] pt = ps_parse(src);
    return pt;
}

/*
 * @Name:   ps_parse
 * @Desc:   Function that takes the contents of a game file and parses it
 * @Param:  
 *          str -> String containing the contents of the game file
 * @Ret:    PSGame object
 */
start[PSGame] ps_parse(str src){
    str src2 = src + "\n\n\n";            // Why do we need this (???)
    return parse(#start[PSGame], src2);   // Parse takes 2 arguments: nonterminal in grammar and string to be parsed
}

/*
 * @Name:   ps_implode
 * @Desc:   Function that takes a parse tree and builds the ast for a PuzzleScript
 *          game
 * @Param:  
 *          tree -> Parse tree
 * @Ret:    PSGame object
 */
PuzzleScript::AST::PSGame ps_implode(start[PSGame] parse_tree) {
    PuzzleScript::AST::PSGame game = implode(#PuzzleScript::AST::PSGame, parse_tree);   // We build the AST
    iprintln(game);
    return process_game(game);
}


/******************************************************************************/
// --- Public process functions ------------------------------------------------

/*
 * @Name:   process_game
 * @Desc:   Function that receives an unprocessed PuzzleScript game and processes
 *          it to use it. This is the reason why in AST.rsc two different versions
 *          of PSGame appear defined (the unprocessed and the processed)
 * @Param:  
 *          unprocessed_game -> PSGame to be processed   
 * @Ret:    Processed PSGame
 */
PSGame process_game(PSGame game) {
    // do post processing here
    list[ObjectData] objects = [];
    list[LegendData] legend = [];
    list[SoundData] sounds = [];
    list[LayerData] layers = [];
    list[RuleData] rules = [];
    list[ConditionData] conditions = [];
    list[LevelData] levels = [];
    list[PreludeData] prelude = [];
    
    // We transverse our AST and only leave non-empty nodes 
    // (=> replaces with the result of the right expression)
    PSGame tmp_game = visit(game){
        case list[PreludeData] prelude => [p | p <- prelude, !(prelude_empty(_) := p)]
        case list[ObjectData] objects =>  [obj | obj <- objects, !(object_empty(_) := obj)]      
        case list[Section] sections => [section | section <- sections, !(s_empty(_, _, _, _) := section)]      
        case list[LegendData] legend => [l | l <- legend, !(legend_empty(_) := l)]
        case list[SoundData] sounds => [sound | sound <- sounds, !(sound_empty(_) := sound)]
        case list[LayerData] layers => [layer | layer <- layers, !(layer_empty(_) := layer)]
        case list[RuleData] rules => [rule | rule <- rules, !(rule_empty(_) := rule)]
        case list[ConditionData] conditions => [cond | cond <- conditions, !(condition_empty(_) := cond)]
        case list[LevelData] levels => [level | level <- levels, !(level_empty() := level)]
    };
        
    // Assign to correct section
    visit(tmp_game){
        case Section s: s_objects(_,_,_,_): objects += s.objects;
        case Section s: s_legend(_,_,_,_): legend += s.legend;
        case Section s: s_sounds(_,_,_,_): sounds += s.sounds;
        case Section s: s_layers(_,_,_,_): layers += s.layers;
        case Section s: s_rules(_,_,_,_): rules += s.rules;
        case Section s: s_conditions(_,_,_,_): conditions += s.conditions;
        case Section s: s_levels(_,_,_,_): levels += s.levels;   
        case PreludeData p: prelude += [p];
    }
        
    // Fix sprites
    processed_objects = [];
    for (ObjectData obj <- objects){
        if (obj is object_data){
            processed_objects += process_object(obj);
        }
    }
        
    // Validate legends and process
    processed_legend = [process_legend(l) | LegendData l <- legend];
            
    // Unnest layers
    processed_layers = [process_layer(l) | LayerData l <- layers];
        
    // Unnest levels
    processed_levels = [process_level(l) | LevelData l <- levels];
        
    PSGame processed_game = PSGame::game(
        prelude, 
        processed_objects, 
        processed_legend, 
        sounds, 
        processed_layers, 
        rules, 
        conditions, 
        processed_levels
    );

    return processed_game;
}

/*
 * @Name:   
 * @Desc:   
 * @Param:     
 * @Ret:    
 */
LegendData process_legend(LegendData l) {
    str legend = l.legend;
    list[str] values = [l.first];
    list[str] aliases = [];
    list[str] combined = [];
        
    for (LegendOperation other <- l.others) {
        switch(other){
            case legend_or(id): aliases += id;
            case legend_and(id): combined += id;
        }
    }

    LegendData new_l = legend_reference(legend, values + aliases);
    if (size(aliases) > 0 && size(combined) > 0) {
        new_l = legend_error(legend, values + aliases + combined);
    } else if (size(combined) > 0) {
        new_l = legend_combined(legend, values + combined);
    }

    return new_l;
}

/*
 * @Name:   
 * @Desc:   
 * @Param:     
 * @Ret:    
 */
ObjectData process_object(ObjectData obj){
    list[list[Pixel]] processed_sprite = [];

    if (size(obj.spr) > 0) {;
        processed_sprite += [
            [pixel(x) | x <- split("", obj.spr[0].line0)],
            [pixel(x) | x <- split("", obj.spr[0].line1)],
            [pixel(x) | x <- split("", obj.spr[0].line2)],
            [pixel(x) | x <- split("", obj.spr[0].line3)],
            [pixel(x) | x <- split("", obj.spr[0].line4)]
        ];
    }    

    ObjectData new_obj = object_data(obj.name, obj.colors, processed_sprite);

    return new_obj;
}

/*
 * @Name:   
 * @Desc:   
 * @Param:     
 * @Ret:    
 */
LayerData process_layer(LayerData l) {
    list[str] new_layer = [];
    for (str obj <- l.layer){
        // flexible grammar parses the optional "," separator as a character so we remove it
        // in post processing if it exists
        if (obj[-1] == ",") {
            new_layer += [obj[0..-1]];
        } else {
            new_layer += [obj];
        }
    }

    LayerData new_l = layer_data(new_layer);
    return new_l;
}

/*
 * @Name:   
 * @Desc:   
 * @Param:     
 * @Ret:    
 */
LevelData process_level(LevelData l : message(_)) {
    return l;
}

/*
 * @Name:   
 * @Desc:   
 * @Param:     
 * @Ret:    
 */
LevelData process_level(LevelData l : level_data_raw(list[tuple[str, str]] lines, str _)) {
    LevelData new_l = level_data([x[0] | x <- lines]);
    return new_l;
}

/*
 * @Name:   
 * @Desc:   
 * @Param:     
 * @Ret:    
 */
default LevelData process_level(LevelData l) {
    return l;
}