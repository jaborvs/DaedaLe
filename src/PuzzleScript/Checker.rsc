/*
 * @Module: Checker
 * @Desc:   Module to check all the parsed AST nodes. It prints warnings or 
 *          errors accordingly
 * @Auth:   Clement Julia -> code
 *          Borja Velasco -> comments
 */
module PuzzleScript::Checker

/*****************************************************************************/
// --- General modules imports ------------------------------------------------
import util::Math;
import String;
import List;
import Type;
import Set;
import IO;

// For visualizing
import util::IDEServices;
import vis::Charts;

/*****************************************************************************/
// --- Own modules imports ------------------------------------------------
import PuzzleScript::AST;
import PuzzleScript::Messages;
import PuzzleScript::Utils;

/*****************************************************************************/
// --- Data structures defines ------------------------------------------------

/*
 * @Name:   Checker
 * @Desc:   Data structure that contains all relevant information of a 
 *          PuzzleScript game to be checked (???). They are ordered in terms 
 *          of how they appear on a PuzzleScript file
 */
alias Checker = tuple[                
    map[str, str] prelude,               // Prelude section: Game's and author's name (???)                         
    bool debug_flag,                     // Debug flag
    list[str] objects,                   // List of all game objects
    list[str] used_objects,              // List of all used game objects
    list[str] all_moveable_objects,      // List of all moveable game objects
    map[str, list[str]] references,      // Map of references: name and its list of references (e.g., Player = PlayerHead1 or PlayerHead2 or PlayerHead3 or PlayerHead4)
    list[str] used_references,           // List of used references
    list[str] all_char_refs,             // (???)
    map[str, list[str]] combinations,    // Map of combinations: name and its list of combinations (e.g., @ = Crate and Target)
    list[str] layer_list,                // List of game layers
    map[                                 // Map of game sounds:
        str,                             //      Name
        tuple[list[int] seeds, loc pos]  //      Tuple: list of seeds and their location on file (???)
        ] sound_events,                                         
    list[str] used_sounds,               // List of used game sounds
    list[Condition] conditions,          // List of game win conditions
    list[Msg] msgs,                      // List of game messages
    map[str, list[str]] all_properties,  // Map of all properties: name and list of all properties
    PSGame game                          // AST node of a PuzzleScript game
];

/*
 * @Name:   Reference
 * @Desc:   Data structure for the references of a PuzzleScript game legend
 *          (e.g., Player = PlayerHead1 or PlayerHead2 or PlayerHead3 or PlayerHead4)
 */
alias Reference = tuple[
    list[str] objs,         // List of objects referenced
    Checker c,              // Checker
    list[str] references    // List of references (???)
];

/*
 * @Name:   Condition
 * @Desc:   Data structure for the win conditions of a PuzzleScript game
 */
data Condition (loc src = |unknown:///|)
    = some_objects(list[str] objects, ConditionData original)                       // Some type win condition
    | no_objects(list[str] objects, ConditionData original)                         // No type win condition
    | all_objects_on(list[str] objects, list[str] on, ConditionData original)       // All type win condition
    | some_objects_on(list[str] objects, list[str] on, ConditionData original)      // Some on type win condition
    | no_objects_on(list[str] objects, list[str] on, ConditionData original)        // No on type win condition
    ;

// anno loc Condition.src;

/*
 * @Name:   COLORS
 * @Desc:   Enummeration containing all the PuzzleScript colors.
 */
public map[str, str] COLORS = (
    "black":        "#000000",
    "white":        "#FFFFFF",
    "grey":         "#555555",
    "darkgrey":     "#555500",
    "transparent":  "#555500",
    "lightgrey":    "#AAAAAA",
    "gray":         "#555555",
    "darkgray":     "#555500",
    "lightgray":    "#AAAAAA",
    "red":          "#BE2633",
    "darkred":      "#AA0000",
    "lightred":     "#FF5555",
    "brown":        "#AA5500",
    "darkbrown":    "#550000",
    "lightbrown":   "#FFAA00",
    "orange":       "#FF5500",
    "yellow":       "#FFFF55",
    "green":        "#55AA00",
    "darkgreen":    "#005500",
    "lightgreen":   "#AAFF00",
    "blue":         "#5555AA",
    "lightblue":    "#AAFFFF",
    "darkblue":     "#000055",
    "purple":       "#550055",
    "pink":         "#FFAAFF"
);

str default_mask = "@None@";

/*****************************************************************************/
// --- Public Getter functions ------------------------------------------------

/*
 * @Name:   get_prelude
 * @Desc:   Function to get the data of the prelude section lines
 * @Params:
 *      values          AST nodes of the game's Prelude section
 *      key             One of the prelude section's keys (title, author, homepage...)
 *      default_str     Default string to be returned (???)
 * @Ret:    String with the name of the game, author or the webpage 
 *          (depending on key)
 */
str get_prelude(list[PreludeData] values, str key, str default_str){
    v = [x | x <- values, toLowerCase(x.key) == toLowerCase(key)];

    if (!isEmpty(v)) return v[0].string;
    return default_str;
}

/*
 * @Name:   get_representation_char
 * @Desc:   Function to get the representation char of a given object
 * @Param:
 *      name        Object name 
 *      references  Map of all game object references
 * @Ret:    Representation char of the object
 */
str get_representation_char(str name, map[str, list[str]] references) {
    for (str char <- references<0>) {
        if (size(char) == 1 && name in references[char]) {  
            return toLowerCase(char);
        }
    }

    return "";
}

/*
 * @Name:   get_resolved_references
 * @Desc:   Function to get the references of a key of the legend in a 
 *          map of references.
 *          Generally used with the keys of the game legend. For this purpose,
 *          remember that keys in the legend can be a representation char
 *          or an alias (such as Player, Obstacle...)
 * @Param:
 *      key         Legend key element
 *      references  Map of references on which to search
 * @Ret:    List of non duped references of the key
 */
list[str] get_resolved_references(str key, map[str, list[str]] references) {
    if (!(key in references<0>)) return [];
    return _get_resolved_references_rec(key, references);
}

list[str] _get_resolved_references_rec (str key, map[str, list[str]] references) {
    if (!(key in references<0>)) return [key];

    list[str] resolved_references = [];

    for (str rf <- references[key]) {
        resolved_references += _get_resolved_references_rec(rf, references);
    }

    return toList(toSet(resolved_references));
}

/*
 * @Name:   get_unresolved_references_and_properties
 * @Desc:   Function to get the all references (resolved and unresolved) of a given 
 *          references element
 * @Param:
 *      key         Element of the references dictionary 
 *      references  Map of all game object references
 * @Ret:    References of the object
 */
list[str] get_unresolved_references_and_properties(str key, map[str, list[str]] references) {
    if (!(key in references<0>)) return [];

    list[str] all_references = [];
    list[str] unresolved_references = references[key];

    all_references += unresolved_references;

    for (str rf <- unresolved_references) {
        all_references += get_properties(rf, references);
    }

    return toList(toSet(all_references));
}

/*
 * @Name:   get_properties
 * @Desc:   Function to get the all properties of a given key.
 *          A property is the string used as key in the set of references
 * @Param:
 *      key         Element from the references dictionary
 *      references  Map of all references
 * @Ret:    Properties of the reference
 */
list[str] get_properties(str key, map[str, list[str]] references) {
    list[str] all_references = [];

    for (str rf <- references) {
        if (size(rf) == 1) continue;

        if (key in references[rf]) {
            all_references += rf;
            all_references += get_properties(rf, references);
        }
    }

    return toList(toSet(all_references));
}

list[str] my_get_properties(str key, map[str, list[str]] references) {
    list[str] all_references = [];
    all_references += key;

    for (str rf <- references) {
        if (size(rf) == 1) continue;

        if (key in references[rf]) {
            all_references += rf;
            all_references += get_properties(rf, references);
        }
    }

    return toList(toSet(all_references));
}

/*****************************************************************************/
// --- Public Resolve functions -----------------------------------------------

/*
 * @Name:   resolve_references
 * @Desc:   Functions that resolves the references of a list of legend elements
 * @Param:
 *      names       List of legend elements to be reference resolved
 *      c           Checker
 *      pos         Location in file
 *      allowed     Determines where the reference is allowed. Why objects (???)    
 * @Ret:    Reference object with the resolved references
 */
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

/*
 * @Name:   resolve_reference
 * @Desc:   Function to resolve the references of an object or a legend character
 * @Param:  
 *      raw_name    Name of the element to be reference resolved
 *      c           Checker
 *      pos         Location in the PuzzleScript file
 *      allowed     Determines where the reference is allowed. Why objects (???)
 * @Ret:    A reference object containing the references object
 */
Reference resolve_reference(str raw_name, Checker c, loc pos, list[str] allowed=["objects", "properties", "combinations"]){
    Reference r;
    
    list[str] objs = [];
    list[str] references = [];    
    str name = toLowerCase(raw_name);
    
    // Case 1: There is already a reference to the name
    if (name in c.references && c.references[name] == [name]) return <[name], c, references>;
    
    references += [toLowerCase(name)];

    // Case 2:  The name is inside the legend combinations
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
    // Case 3: The name is inside the legend references 
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
    // Case 4: Object not defined, we include an error
    } else {
        c.msgs += [undefined_object(raw_name, error(), pos)];
    }
    
    return <dup(objs), c, references>;
}

/*
 * @Name:   resolve_properties
 * @Desc:   Function to resolve the properties of a game. Properties are resolved
 *          references. We perform the transitive closure of the references
 *          (e.g., "player":["playerhead1","playerhead2","playerhead3","playerhead4"
 *                 "playerbody":["playerbodyh","playerbodyv"])
 * @Param:  
 *      c   Checker
 * @Ret:    Tuple that contains
 *              map[
 *                  str,        Name of the property
 *                  list[str]   Names of the objects associated to the property
 *              ]
 *              list[str]       Those objects that either are a 1 to 1 reference or
 *                              that are part of a combination (there are duplicates)
 *
 * @Example:
 *      For the legend of Lime Rick:
 *          Player = PlayerHead1 or PlayerHead2 or PlayerHead3 or PlayerHead4
 *          Obstacle = PlayerBodyH or PlayerBodyV or Wall or Crate or Player
 *          PlayerBody = PlayerBodyH or PlayerBodyV
 *          . = Background
 *          P = PlayerHead1
 *          # = Wall
 *          E = Exit
 *          A = Apple
 *          C = Crate
 *      We would return:
 *          map = (
 *              "player":["playerhead1","playerhead2","playerhead3","playerhead4"],
 *              "playerbody":["playerbodyh","playerbodyv"],
 *              "obstacle":["playerbodyh","playerbodyv","wall","crate","playerhead1","playerhead2","playerhead3","playerhead4"]       
 *          )
 *          list = ["exit","background","playerhead1","apple","wall","crate"]
 */
tuple[map[str, list[str]], list[str]] resolve_properties(Checker c) {
    map[str, list[str]] properties_dict = ();
    list[str] char_refs = [];

    for (str name <- c.references<0>) {
        list[str] references = [];

        if (size(c.references[name]) > 1) {
            for (str reference <- c.references[name]) references += resolve_properties_rec(c, reference);    // Performs the transitive closure
            properties_dict += (name: references);
        } 
        else if (size(name) == 1) {
            char_refs += c.references[name];
        }
    }

    for (str name <- c.combinations<0>) {
        if (size(name) == 1) char_refs += [ref | ref <- c.combinations[name]];
    }

    return <properties_dict, char_refs>;
}

/*
 * @Name:   resolve_properties_rec
 * @Desc:   It performs the transitive closure for the references
 * @Param:  
 *      c       Checker
 *      name    String containing the name of the reference
 * @Ret:    List containing the resolved references
 */
list[str] resolve_properties_rec(Checker c, str name) {
    list[str] propertylist = [];

    if (c.references[name]?) {
        for(str name <- c.references[name]) propertylist += resolve_properties_rec(c, name);
    } else {
        propertylist += [name];
    }

    return propertylist;
}
        
/*****************************************************************************/
// --- Public Checker functions -----------------------------------------------

/*
 * @Name:   new_checker
 * @Desc:   Constructor function to create a new empty checker given an AST node
 *          of a PuzzleScript game
 * @Params: 
 *      debug_flag  Boolean indicating whether or not we are in the debug mode
 *      game        AST node of a PuzzleScript game
 */
Checker new_checker(bool debug_flag, PSGame game){        
    return <(), debug_flag, [], [], [], (), [], [], (), [], (), [], [], [], (), game>;
}

/*
 * @Name:   check_prelude
 * @Desc:   Function to check the prelude section. The used keywords are defined 
 *          in the Utils file
 * @Param:
 *      pr  AST node with the prelude data
 *      c   Checker
 * @Ret:   Checker with updated errors and warnings
 *      Errors
 *          invalid_prelud_key
 *            existing_prelude_key
 *          missing_prelude_value
 *          invalid_prelude_value
 *      Warnings
 *          redundant_prelude_value
 */
Checker check_prelude(PreludeData pr, Checker c){
    str key = toLowerCase(pr.key);

    // Case 1: Not a defined keyword
    if (!(key in prelude_keywords)){
        c.msgs += [invalid_prelude_key(pr.key, error(), pr.src)];
        return c;
    }
    
    // Case 2: Already defined keyword
    if (key in c.prelude){
        c.msgs += [existing_prelude_key(pr.key, error(), pr.src)];
    // Case 3: Key in prelude_without_arguments (???)
    } else if (key in prelude_without_arguments){
        if (pr.string != "") c.msgs += [redundant_prelude_value(pr.key, warn(), pr.src)];
        c.prelude[key] = "None";
    // Case 4: Key in prelude_with_arguments
    } else {
        // Case 4.1: Missing argument
        if (pr.string == ""){
            c.msgs += [missing_prelude_value(pr.key, error(), pr.src)];
            return c;
        }
        // Case 4.2: Invalid argument of type int
        if (key in prelude_with_arguments_int) {
            if (!(check_valid_real(pr.string))) c.msgs += [invalid_prelude_value(key, pr.string, "real", error(), pr.src)];
            c.prelude[key] = pr.string;
        // Case 4.3: Argument of type string
        } else {
            // Case 4.3.1: Invalid argument of type str_dim
            if (key in prelude_with_arguments_str_dim) {
                if (!(/[0-9]+x[0-9]+/i := pr.string)) c.msgs += [invalid_prelude_value(key, pr.string, "height code", error(), pr.src)];
                c.prelude[key] = pr.string;
            // Case 4.3.2: Invalid argument of type str_color (Complicated to validate since it can be both an hex code or a color name so for now we do nothing)
            } else if (key in prelude_with_arguments_str_color) {
                c.prelude[key] = pr.string;
            // Case 4.3.3: Other cases not considered (title, author, homepage...)
            } else {
                c.prelude[key] = pr.string;
            }
        }
    }

    return c;
}

/*
 * @Name:   check_object
 * @Desc:   Function to check an object
 * @Param:
 *      ojb     AST node with the object data
 *      c       Checker
 * @Ret:   Checker with updated errors and warnings
 *      Errors
 *          invalid_name
 *          existing_object
 *          existing_legend
 *          invalid_color
 *          invalid_sprite 
 *          invalid_index
 *      Warnings
 *          unused_colors
 */
Checker check_object(ObjectData obj, Checker c) {
    int max_index = 0;
    str id = toLowerCase(obj.name);    
    
    // Case 1: Check for a valid name
    if (!check_valid_name(id)) c.msgs += [invalid_name(id, error(), obj.src)];

    // Case 2: Check for duplicated objects
    if (id in c.objects) {
        c.msgs += [existing_object(obj.name, error(), obj.src)];
    } else {
        c.objects += [id];
    }
    
    // Case 3: Check the legend
    if (!isEmpty(obj.legend)) {
        if (toLowerCase(obj.legend[0]) in c.references) c.references[toLowerCase(obj.legend[0])] += [toLowerCase(obj.name)];
        else c.references += (toLowerCase(obj.legend[0]): [toLowerCase(obj.name)]);

        msgs = check_existing_legend(obj.legend[0], [obj.name], obj.src, c);
        if (!isEmpty(msgs)){
            c.msgs += msgs;
        } else {
            c.used_objects += [id];
        }
    }
    
    // Case 4: Check the colors (only default mastersystem palette supported currently)
    for (str color <- obj.colors) {
        if (toLowerCase(color) in COLORS) continue;
        if (/^#(?:[0-9a-fA-F]{3}){1,2}$/ := color) continue;
        
        c.msgs += [invalid_color(obj.name, color, error(), obj.src)];
    }

    // Case 5: Check if it has a sprite
    if (isEmpty(obj.sprite)) return c;

    bool valid_length = true;
    if (size(obj.sprite) != 5) valid_length = false;

    for(list[Pixel] line <- obj.sprite){        
        // Check if the sprite is of valid length
        if (size(line) != 5) valid_length = false;
    
        // Check if all pixels have the correct index
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
    
    // Case 5: Check if all sprite defined colors are used
    if (size(obj.colors) > max_index + 1) {
        c.msgs += [unused_colors(obj.name, intercalate(", ", obj.colors[max_index+1..size(obj.colors)]), warn(), obj.src)];
    }
    
    return c;
}

/*
 * @Name:   check_undefined_object
 * @Desc:   Function to check undefined objects
 * @Param:  
 *      name    String containing the name of the object
 *      pos     Location in the PuzzleScript file
 *      c       Checker
 * @Ret:    List of messages
 */
list[Msg] check_undefined_object(str name, loc pos, Checker c){
    list[Msg] msgs = [];
    
    if (!(toLowerCase(name) in c.objects)){
        if (isEmpty(check_existing_legend(name, [], pos, c))) msgs += [undefined_object(name, error(), pos)];
    }

    return msgs;
}

/*
 * @Name:   check_legend
 * @Desc:   Function to check the legend
 * @Param:
 *      l   AST node with the legend data
 *      c   Checker
 * @Ret:   Checker with updated errors and warnings
 *      Errors
 *          existing_legend
 *          undefined_object
 *          mixed_legend ('and' and 'or')
 *          mixed_legend (alias and cominations)
 *          invalid_name
 *      Warnings
 *          self_reference
 */
Checker check_legend(LegendData l, Checker c) {
    // Case 1: Invalid legend
    if (!check_valid_legend(l.legend)) c.msgs += [invalid_name(l.legend, error(), l.src)];
    c.msgs += check_existing_legend(l.legend, l.values, l.src, c);

    // Case 2: Legend references
    if (l is legend_reference) {
        for (str object <- l.values) {
            if (toLowerCase(l.legend) in c.references) c.references[toLowerCase(l.legend)] += [toLowerCase(object)];
            else c.references += (toLowerCase(l.legend): [toLowerCase(object)]);
        }
    }

    // Case 3: Legend object combination
    if (l is legend_combined) {
        for (str object <- l.values) {
            if (toLowerCase(l.legend) in c.combinations) c.combinations[toLowerCase(l.legend)] += [toLowerCase(object)];
            else c.combinations += (toLowerCase(l.legend): [toLowerCase(object)]);
        }
    }

    str legend = toLowerCase(l.legend);

    // Case 4: Check if object in legend is defined in objects section      Why commented(???)
    if (check_valid_name(l.legend)) c.objects += [legend];
    // for (str v <- values){
    //     if (!(v in c.objects)) {
    //         c.msgs += [undefined_object(v, error(), l.src)];
    //     } else {
    //         c.used_objects += [v];
    //     }
    // }
    
    // Case 5: if it's just one thing being defined with check it and return    Why commented(???)
    // if (size(values) == 1) {
    //     msgs = check_undefined_object(l.values[0], l.src, c);
    //     if (!isEmpty(msgs)) {
    //         c.msgs += msgs;
    //     } else {
    //         // check if it's a self definition and warn as need be
    //         if (legend == values[0]){
    //             c.msgs += [self_reference(l.legend, warn(), l.src)];
    //         } else {
    //             c.references[legend] = values;
    //         }
    //     }
        
    //     return c;
    // }
    
    // Case 6: if not we do a more expensive check for invalid legend and mixed types    Why commented(???)
    // switch(l) {
    //     case legend_reference(_, _): {
    //         // if our alias makes use of combinations that's a bonk
    //         list[str] mixed = [x | x <- values, x in c.combinations];
    //         if (!isEmpty(mixed)) {
    //             c.msgs += [mixed_legend(l.legend, mixed, "alias", "combination", error(), l.src)];
    //         } else {
    //             c.references[legend] = values;
    //         }
    //     }
    //     case legend_combined(_, _): {
    //         // if our combination makes use of aliases that's a bonk (just gotta make sure it's actually an alias)
    //         list[str] mixed = [x | x <- values, x in c.references && size(c.references[x]) > 1];
    //         if (!isEmpty(mixed)) {
    //             c.msgs += [mixed_legend(l.legend, mixed, "combination", "alias", error(), l.src)];
    //         } else {
    //             c.combinations[legend] = values;
    //         }
    //     }
    //     case legend_error(_, _): c.msgs += [mixed_legend(l.legend, l.values, error(), l.src)];    
    // }

    return c;
}

/*
 * @Name:   check_valid_legend
 * @Desc:   Function to check if a legend element is valid using a regular expression and
 *          checking if it is not one of the coding keywords
 * @Param:
 *      name String containing the name of the legend element
 * @Ret:    Boolean determining if valid
 */
bool check_valid_legend(str name){
    if (size(name) > 1){
        return check_valid_name(name);
    } else {
        return /^<x:[a-uw-z0-9.!@#$%&*,\-+]+>$/i := name && !(toLowerCase(name) in keywords);
    }
}

/*
 * @Name:   check_existing_legend
 * @Desc:   Function to check if a legend exists
 * @Param:  
 *      name    String containing the name of the legend element
 *      values  All values that it is associated with (using or/and)
 *      pos     Location in the PuzzleScript file
 *      c       Checker
 * @Ret:    List of messages
 */
list[Msg] check_existing_legend(str name, list[str] values, loc pos, Checker c){
    list[Msg] msgs = [];

    if (toLowerCase(name) in c.references) msgs += [existing_legend(name, c.references[toLowerCase(name)], values, error(), pos)];
    if (toLowerCase(name) in c.combinations) msgs += [existing_legend(name, c.combinations[toLowerCase(name)], values, error(), pos)];
    
    return msgs;
}

/*
 * @Name:   check_sound
 * @Desc:   Function to check a sound
 * @Param:
 *      s   AST node with a sound
 *      c   Checker
 * @Ret:   Checker with updated errors and warnings
 *      Errors
 *          invalid_sound
 *          invalid_sound_length
 *          existing_sound_object
 *          existing_mask
 *          existing_sound_seed
 *          mask_not_directional
 *          invalid_sound_verb
 *          undefined_sound_object
 *          undefined_sound_mask
 *          undefined_sound_seed
 *      Warnings
 *          existing_sound
 */
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

/*
 * @Name:   check_layer
 * @Desc:   Function to check a layer
 * @Param:
 *      l   AST node with a layer
 *      c   Checker
 * @Ret:   Checker with updated errors and warnings
 *      Errors
 *          undefined_object
 *      Warnings
 *          multilayered_object
 */
Checker check_layer(LayerData l, Checker c){
    Reference r = resolve_references(l.layer, c, l.src);

    c = r.c;
    for (str obj <- r.objs){
        if (obj in c.layer_list) c.msgs += [multilayered_object(obj, warn(), l.src)];
    }
    
    c.layer_list += r.objs;
    
    return c;
}

/*
 * @Name:   check_rule
 * @Desc:   Function to check a rule
 * @Param:
 *      r       AST node of a rule (loop)
 *      c       Checker
 * @Ret:   Checker with updated errors and warnings
 *      Errors
 *          invalid_rule_prefix
 *          invalid_rule_command
 *          undefined_sound
 *          undefined_object
 *          invalid_sound
 *          invalid_ellipsis_placement
 *          invalid_ellipsis
 *          invalid_rule_part_size
 *          invalid_rule_content_size
 *          invalid_rule_ellipsis_size
 */
Checker check_rule(RuleData r: rule_loop(_,_), Checker c){
    for(RuleData childRule <- r.rules){
        check_rule(childRule, c);
    }
    return c;
}

/*
 * @Name:   check_rule
 * @Desc:   Function to check a rule
 * @Param:
 *      r       AST node of a rule (normal)
 *      c       Checker
 * @Ret:   Checker with updated errors and warnings
 *      Errors
 *          invalid_rule_prefix
 *          invalid_rule_command
 *          undefined_sound
 *          undefined_object
 *          invalid_sound
 *          invalid_ellipsis_placement
 *          invalid_ellipsis
 *          invalid_rule_part_size
 *          invalid_rule_content_size
 *          invalid_rule_ellipsis_size
 */
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

/*
 * @Name:   check_rulepart
 * @Desc:   Function to check a rule part
 * @Param:
 *      p       Rule part (part)
 *      c       Checker
 *      late    Boolean indicating if its a late rule
 *      pattern Boolean indicating if its a pattern (???)
 * @Ret:   Checker with updated errors and warnings
 *      Errors
 *          undefined_object
 *      Warnings
 *          multilayered_object
 */
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

/*
 * @Name:   check_rulepart
 * @Desc:   Function to check a rule part
 * @Param:
 *      p       Rule part (command)
 *      c       Checker
 *      late    Boolean indicating if its a late rule
 *      pattern Boolean indicating if its a pattern (???)
 * @Ret:   Checker with updated errors and warnings
 *      Errors
 *          undefined_object
 *      Warnings
 *          multilayered_object
 */
Checker check_rulepart(RulePart p: command(str command), Checker c, bool late, bool pattern){
    if (!(toLowerCase(command) in rule_commands)) 
        c.msgs += [invalid_rule_command(command, error(), p.src)];
    
    return c;
}

/*
 * @Name:   check_rulepart
 * @Desc:   Function to check a rule part
 * @Param:
 *      p       Rule part (sound)
 *      c       Checker
 *      late    Boolean indicating if its a late rule
 *      pattern Boolean indicating if its a pattern (???)
 * @Ret:   Checker with updated errors and warnings
 *      Errors
 *          undefined_object
 *      Warnings
 *          multilayered_object
 */
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

/*
 * @Name:   check_rulepart
 * @Desc:   Function to check a rule part
 * @Param:
 *      p       Rule part (prefix)
 *      c       Checker
 *      late    Boolean indicating if its a late rule
 *      pattern Boolean indicating if its a pattern (???)
 * @Ret:   Checker with updated errors and warnings
 *      Errors
 *          undefined_object
 *      Warnings
 *          multilayered_object
 */
Checker check_rulepart(RulePart p: prefix(str prefix), Checker c, bool late, bool pattern){
    if (!(toLowerCase(p.prefix) in rule_prefix)) c.msgs += [invalid_rule_prefix(p.prefix, error(), p.src)];
    
    return c;
}   

/*
 * @Name:   check_condition
 * @Desc:   Function to check the win conditions
 * @Param:
 *      w   AST node with the win conditions  
 *      c   Checker
 * @Ret:   Checker with updated errors and warnings
 *      Errors
 *          invalid_condition_length
 *          undefined_object
 *          invalid_condition
 *          invalid_condition_verb
 *          impossible_condition_unstackable
 *          impossible_condition_duplicates
 */
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

/*
 * @Name:   check_level
 * @Desc:   Function to check a level
 * @Param:
 *      l   AST node with the level 
 *      c   Checker
 * @Ret:   Checker with updated errors and warnings
 *      Errors
 *          invalid_level_row
 *          invalid_name
 *          ambiguous pixel
 *          unefined_object
 *      Warnings
 *          message_too_long
 */
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

/*
 * @Name:   check_stackable
 * @Desc:   Function to check if two objects are stackable
 * @Param:
 *      objs1   Names of objects 1
 *      objs2   Names of objects 2
 *      c       Checker
 *      pos     Location (???)
 * @Ret:   Checker with updated errors and warnings
 *      Errors
 *          impossible_condition_unstackable
 */
Checker check_stackable(list[str] objs1, list[str] objs2, Checker c, loc pos){
    for (LayerData l <- c.game.layers){
        list[str] lw = [toLowerCase(x) | x <- l.layer];        
        if (!isEmpty(objs1 & lw) && !isEmpty(objs2 & lw)){
            c.msgs += [impossible_condition_unstackable(error(), pos)];
        }
    }
    
    return c;
}

/*
 * @Name:   check_valid_name
 * @Desc:   Function to check if a name is valid using a regular expression
 *          and verifiying is not one of the used coding keywords
 * @Param:  
 *      name    String to be checked
 * @Ret:    Boolean determining if valid
 */
bool check_valid_name(str name){
    return /^<x:[a-z0-9_]+>$/i := name && !(toLowerCase(name) in keywords);
}

/*
 * @Name:   check_valid_real
 * @Desc:   Function that checks if a string contains a positive real number
 * @Param:
 *      v   String to be checked
 * @Ret:    Boolean determining if valid
 */
bool check_valid_real(str v) {
    try
        real i = toReal(v);
    catch IllegalArgument: return false;
    return i > 0;
}

/*
 * @Name:   check_game
 * @Desc:   Function to check a PuzzleScript game. It calls all the others
 *          checker functions in order
 * @Param:
 *      g       AST node of a PuzzleScript game
 *      debug   Boolean indicating if we are in debug mode
 * @Ret:    Updated checker
 */
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

    tuple[map[str, list[str]], list[str]] all_objects = resolve_properties(c);

    println("---------------------------------------------------------");
    println("--- References ------------------------------------------");
    iprintln(c.references);
    println("--- Combinations ----------------------------------------");
    iprintln(c.combinations);
    println("--- Properties ------------------------------------------");
    iprintln(c.all_properties);
    println();
    println();
    println("--- References and properties ----------------------------------");
    println(get_resolved_references("test", c.references));
    println(get_unresolved_references_and_properties("test", c.references));
    println(get_properties("test", c.references));

    c.all_properties = all_objects[0];
    c.all_char_refs = all_objects[1];
    
    if (isEmpty(g.levels)) c.msgs += [no_levels(warn(), g.src)];
    
    return c;
}

/*****************************************************************************/
// --- Public Printing Functions ----------------------------------------------

/*
 * @Name:   print_msgs
 * @Desc:   Function to print all the checker messages
 * @Param:
 *      c   Checker 
 */
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
