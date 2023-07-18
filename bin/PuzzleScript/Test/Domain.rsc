module PuzzleScript::Design::Syntax

start syntax Tutorial
  = "tutorial" ID "{" {Module";"}* "}";

syntax Module
  = "module" ID "{" {Goal ";"}* "}";

syntax Goal
  = "goal" ID name "perform" ID verb;

syntax Verb  //climb, fall
  = "verb" ID;

syntax Mechanism
  = "mechanism" ID name "[" {INT line ","}* "]"; 




syntax Trace
  = "[" {Action ","}* "]";

syntax Action
  = ID key "@" Time time
  | ID key;



data Action
  = action(ID key)
  | action(ID key, Time tine)
  | action(ID key, Time time, ID mechanism);

