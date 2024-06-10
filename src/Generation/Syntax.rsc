/*
 * @Module: Syntax
 * @Desc:   Module that defined the syntax of Papyrus, my DSL for tutorial 
 *          generation
 * @Author: Borja Velasco -> code, comments
 */
module Generation::Syntax

/******************************************************************************/
// --- Layout ------------------------------------------------------------------

layout LAYOUTLIST
  = LAYOUT* !>> "//" !>> "/*";

lexical LAYOUT
  = Comment
  | [\t-\n \r \ ];


/******************************************************************************/
// --- Keywords ----------------------------------------------------------------

keyword Keywords 
    = GeneralKeyword | ModifierKeyword;  

keyword GeneralKeyword 
    = "tutorial" | "level" | "lesson"; 

keyword ModifierKeyword
    = "+" | "*";

/******************************************************************************/
// --- Lexicals ----------------------------------------------------------------

lexical STRING
    = ![\"]* ;

lexical INT
    = [0-9]+ val;

lexical COMMENT
    = "//" ![\n]* [\n];

lexical ID = [a-z0-9.A-Z#_+]+ !>> [a-z0-9.A-Z#_+] \ Keywords;

/******************************************************************************/
// --- Syntax ------------------------------------------------------------------

start syntax Tutorial
    = tutorial_data: 'tutorial' ID "{" Level+ "}";

syntax Level
    = level_description_data: 'level' INT "{" Lesson+ "}";

syntax Lesson
    = lesson_data: 'lesson' INT ":" ID "{" Description Goal+ "}";

syntax Description
    = description_data: "\"" STRING "\"";

syntax LessonGoal
    = legoal_data: ID ModifierKeywords ";";