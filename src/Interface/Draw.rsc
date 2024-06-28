/*
 * @Module: Draw
 * @Desc:   Module that contains de drawing
 * @Auth:   Borja Velasco -> code, comments
 */
module Interface::Draw

/******************************************************************************/
// --- General modules imports -------------------------------------------------

import IO;
import util::ShellExec;

/******************************************************************************/
// --- Own modules imports -----------------------------------------------------

import Interface::Json;
import PuzzleScript::Compiler;

/******************************************************************************/
// --- Drawing Functions ------------------------------------------------------

/*
 * @Name:   draw
 * @Desc:   Function that draws a level
 * @Params: engine -> Engine
 *          index  -> Current Turn
 * @Ret:    void
 */
void draw(Engine engine, int index) {
    data_loc = |project://daedale/src/Interface/bin/data.dat|;

    tuple[str, str, str] json_data = level_to_json(engine, index);
    writeFile(data_loc, json_data[0]);
    tmp = execWithCode("python3", workingDir=|project://daedale/src/Interface/py|, args = ["ImageGenerator.py", resolveLocation(data_loc).path, json_data[1], json_data[2], "1"]);
}