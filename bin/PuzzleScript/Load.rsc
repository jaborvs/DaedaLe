module PuzzleScript::Load

import PuzzleScript::Syntax;
import PuzzleScript::AST;
import ParseTree;

game1 = parse(#PSGame, |project://AutomatedPuzzleScript/src/PuzzleScript/Test/Test.PS|);
game2 = implode(#Game, game1);

r = parse(#PSPreludeData, "title Tico");
b = implode(#PreludeData, r);
// restart console often, reloading module doesn't always work well
