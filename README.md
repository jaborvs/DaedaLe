# ScriptButler
PuzzleScript is a textual language for Puzzle game design created by Stephen Lavelle.
The PuzzleScript engine can be found here: https://github.com/increpare/PuzzleScript

ScriptButler is a tool for analyzing PuzzleScript source code. Its objectives are:
1. *Empower designers.* ScriptButler's analyzers provide feedback about the source code during a game's design, directy in the IDE.
2. *Enable empirical studies.* ScriptButler also supports bulk analyses, which is needed for empirical studies.

## Research Paper
ScriptButler has been used in the following research paper:

* Clement Julia and Riemer van Rozen. 2023. ScriptButler serves an Empirical Study of PuzzleScript: Analyzing the Expressive Power of a Game DSL through Source Code Analysis. In Foundations of Digital Games 2023 (FDG 2023), April 12-14, 2023, Lisbon, Portugal. ACM, New York, NY, USA, 11 pages. https://doi.org/10.1145/3582437.3582467

### Running the analysis
Here we describe how to reproduce the automated part of this study.

ScriptButler is built using the Rascal meta-programming language and language workbench.
More information about setting up Rascal can be found here: https://www.rascal-mpl.org

1. The project must be stored in a directory called AutomatedPuzzleScript.

2. The analyzed PuzzleScript source code repository and the generated report are stored in the following directories.
```
loc DemoDir = |project://AutomatedPuzzleScript/src/PuzzleScript/Test/demo|;
loc ReportFile = |project://AutomatedPuzzleScript/src/PuzzleScript/report.csv|;
```

3. Running the analysis requires executing the following commands in Rascal's REPL.
```
import PuzzleScript::Report;
generateReport(DemoDir, ReportFile);
```
The result will be a report that stores the data as comma separated values.

4. The manual part of our analysis can be found in an Excel sheet: paper/report_analysis.xlsx

## Thesis
ScriptButler was developed as part of the Master's thesis of Clement Julia.

The original repository can be found here: https://github.com/ClementJ18/ScriptButler

The ScriptButler version provided here has an improved PuzzleScript grammar, and adds a report generator.
