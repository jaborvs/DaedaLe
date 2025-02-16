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
    level_json_loc = |project://daedale/src/Interface/bin/level.json|;

    level_json = level_to_json(engine, index);
    writeFile(level_json_loc, level_json);
    tmp = execWithCode("python", workingDir=|project://daedale/src/Interface/py/|, args = ["ImageGenerator.py", resolveLocation(level_json_loc).path, "1"]);
    println(tmp);
}