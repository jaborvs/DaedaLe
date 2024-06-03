/*
 * @Module: Checker
 * @Desc:   Module to check all the parsed AST nodes. This module will probably
 *          dissapear (FIX)
 * @Auth:   Borja Velasco -> code, comments
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
import PuzzleScript::Utils;

/*****************************************************************************/
// --- Data structures defines ------------------------------------------------

/*
 * @Name:   Checker
 * @Desc:   Data structure that contains all relevant information of a 
 *          PuzzleScript game to be checked.
 */
alias Checker = tuple[                        
    map[str key, list[str] values] references,              // Map of references: name and its list of references (e.g., Player = PlayerHead1 or PlayerHead2 or PlayerHead3 or PlayerHead4)
    map[str key, list[str] values] resolved_references,     // Map of all resolved references: these are what 
    map[str key, list[str] values] combinations,            // Map of combinations: name and its list of combinations (e.g., @ = Crate and Target)                                          
    GameData game                                             // AST node of a PuzzleScript game
];



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
Checker new_checker(GameData game) 
    = <
        (),     // References map
        (),     // Resolved references map
        (),     // Combinations map
        game    // Game AST node
    >;

/*
 * @Name:   check_game
 * @Desc:   Function to check a PuzzleScript game. It calls all the others
 *          checker functions in order
 * @Param:
 *      g       Game AST node
 * @Ret:    Updated checker
 */
Checker check_game(GameData g) {
    Checker c = new_checker(g);

    for (LegendData l <- g.legend){
        if (l is legend_reference) {
            for (str object <- l.items) {
                if (toLowerCase(l.key) in c.references) c.references[toLowerCase(l.key)] += [toLowerCase(object)];
                else c.references += (toLowerCase(l.key): [toLowerCase(object)]);
            }
        }

        if (l is legend_combined) {
            for (str object <- l.items) {
                if (toLowerCase(l.key) in c.combinations) c.combinations[toLowerCase(l.key)] += [toLowerCase(object)];
                else c.combinations += (toLowerCase(l.key): [toLowerCase(object)]);
            }
        }
    }

    c.resolved_references = ();
    for(str key <- c.references<0>) {
        if (size(c.references[key]) == 1) continue;
        c.resolved_references += (key: get_resolved_references(key, c.references));
    }

    return c;
}

/*****************************************************************************/
// --- Public Getter functions ------------------------------------------------

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
 * @Name:   get_resolved_references (list version)
 * @Desc:   Function to get the references of a key of the legend in a 
 *          map of references.
 *          Generally used with the keys of the game legend. For this purpose,
 *          remember that keys in the legend can be a representation char
 *          or an alias (such as Player, Obstacle...)
 * @Param:
 *      keys         Legend key elements
 *      references  Map of references on which to search
 * @Ret:    List of non duped references of the key (including the actual keys)
 */
list[str] get_resolved_references(list[str] keys, map[str, list[str]] references) {
    list[str] resolved_references = [];

    for(str key <- keys){
        resolved_references += get_resolved_references(key, references);
    }

    return toList(toSet(resolved_references));
}

/*
 * @Name:   get_resolved_references (single key version)
 * @Desc:   Function to get the references of a key of the legend in a 
 *          map of references.
 *          Generally used with the keys of the game legend. For this purpose,
 *          remember that keys in the legend can be a representation char
 *          or an alias (such as Player, Obstacle...)
 * @Param:
 *      key         Legend key element
 *      references  Map of references on which to search
 * @Ret:    List of non duped references of the key (including the actual keys)
 */
list[str] get_resolved_references(str key, map[str, list[str]] references) {
    list[str] resolved_references = [];

    if (!(key in references<0>)) return resolved_references;

    for (str rf <- references[key]) {
        new_references = get_resolved_references(rf, references);
        if (isEmpty(new_references)) resolved_references += [rf];
        else resolved_references += new_references;
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
 * @Name:   get_properties_rep_char
 * @Desc:   Function to get the properties of a representatio char. This are the 
 *          properties of each of the object names it references.
 * @Param:  rep_char   -> Representation char of the references dictionary 
 *          references -> Map of all game object references
 * @Ret:    References of the representation char
 */
list[str] get_properties_rep_char(str rep_char, map[str, list[str]] references) {
    if (!(rep_char in references<0>)) return [];

    list[str] all_properties = [];
    list[str] unresolved_references = references[rep_char];
    all_properties += unresolved_references;

    for (str rf <- unresolved_references) {
        all_properties += get_properties(rf, references);
    }

    return toList(toSet(all_properties));
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
    list[str] all_references = [key];

    for (str rf <- references) {
        if (size(rf) == 1) continue;

        if (key in references[rf]) {
            all_references += rf;
            all_references += get_properties(rf, references);
        }
    }

    return toList(toSet(all_references));
}

/*
 * @Name:   get_properties_name
 * @Desc:   Function to get the all properties of a given object name.
 *          A property refers to the non-sized 1 keys of the legend that contain
 *          the object name
 * @Param:  name       -> Object name (or alias of object names)
 *          references -> Map of all references
 * @Ret:    Properties of the reference
 */
list[str] get_properties_name(str name, map[str, list[str]] references) {
    list[str] all_properties = [name];

    for (str rf <- references) {
        if (size(rf) == 1) continue;

        if (name in references[rf]) {
            all_properties += rf;
            all_properties += get_properties(rf, references);
        }
    }

    return toList(toSet(all_properties));
}