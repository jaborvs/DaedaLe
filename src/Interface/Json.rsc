/*
 * @Module: Draw
 * @Desc:   Module that contains de JSON functionality
 * @Auth:   Borja Velasco -> code, comments
 */
module Interface::Json

/******************************************************************************/
// --- General modules imports -------------------------------------------------

import String;
import List;
import Type;
import Set;

/******************************************************************************/
// --- Own modules imports -----------------------------------------------------

import PuzzleScript::Utils;
import PuzzleScript::AST;
import PuzzleScript::Compiler;

/******************************************************************************/
// --- Public Json Conversion Functions ----------------------------------------

/*
 *  @Name:  level_to_json
 *  @Desc:  Converts a pixel to JSON format for the level GUI representation
 *  @Param: engine -> Engine of the application
 *          index  -> Index of the model
 *  @Ret:   Tuple containing the coordinates in json, the level size in json 
 *          and the index in json
 */
tuple[str,str,str] level_to_json(Engine engine, int index) {
    tuple[int width, int height] level_size = engine.level_checkers[engine.current_level.original].size;
    str json = "[";
    tmp = 0;

    for (int i <- [0..level_size.height]) {
        for (int j <- [0..level_size.width]) {
            if (!(engine.current_level.objects[<i,j>]?) 
                || isEmpty(engine.current_level.objects[<i,j>])) continue;

            for (Object object <- engine.current_level.objects[<i,j>]) {
                json += object_to_json(engine.objects[object.current_name], i, j);                
            }
        }
    }

    json = json[0..size(json) - 1];
    json += "]";

    return <json, "{\"width\": <level_size.width>, \"height\": <level_size.height>}", "{\"index\": <index>}">;
}

/*
 *  @Name:  level_to_json
 *  @Desc:  Converts a pixel to JSON format for the level GUI representation
 *  @Param: engine -> Engine of the application
 *          index  -> Index of the model
 *  @Ret:   Tuple containing the coordinates in json, the level size in json 
 *          and the index in json
 */
str object_to_json(ObjectData object, int i, int j) {
    str json = "";

    for (int k <- [0..5]) {
        for (int l <- [0..5]) {
            json += "{";
            json += "\"x\": <j * 5 + l>,";
            json += "\"y\": <i * 5 + k>,";

            if(isEmpty(object.sprite)) {
                json += "\"c\": \"<COLORS[toLowerCase(object.colors[0])]>\"";
            }
            else {
                Pixel pix = object.sprite[k][l];
                if (pix.color_number == ".") {
                    json += "\"c\": \"<COLORS["transparent"]>\"";
                }
                else if (COLORS[object.colors[toInt(pix.color_number)]]?) {
                    json += "\"c\": \"<COLORS[object.colors[toInt(pix.color_number)]]>\"";
                }
                else {
                    json += "\"c\": \"#FFFFFF\"";
                }
            }
            json += "},";
        }
    }

    return json;
}