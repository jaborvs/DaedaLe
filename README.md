# ScriptButler
PuzzleScript is a textual language for puzzle game design created by Stephen Lavelle.
The PuzzleScript engine can be found here: https://github.com/increpare/PuzzleScript

### Running TutoMate on source code repositories
TutoMate is built using the Rascal meta-programming language and language workbench.
More information about setting up Rascal can be found here: https://www.rascal-mpl.org

1. The project must be stored in a directory called automatedpuzzlescript.

2. Setting the to-be-analysed game is done in the following way.
```
loc game_loc = |project://automatedpuzzlescript/bin/PuzzleScript/Tutorials/demo/blockfaker.PS|;
```

3. Using Tutomate requires executing the following commands in Rascal's REPL.
```
import PuzzleScript::Interface::GUI;
game = load(game_loc);
main()();
```
These commands host the interface through which the analyses can take place.
The DSL can be edited in the GUI file.


## Thesis
TutoMate was developed as part of the Master's thesis of Dennis Vet.
