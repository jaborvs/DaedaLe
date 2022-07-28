# ScriptButler

ScriptButler was an attempt at using meta-programming principles and Rascal to allow for rapid iterative game design. It was the 
project on which I based my master thesis. The full thesis can be read in thesis/Master_Thesis.pdf

## Abstract
The digital game industry is a thriving multi-billion dollar industry. Creating interesting and interactive
games is a complex process with two major parts: game design and game development. Game design
is the art of applying design to create games on a conceptual level. Game development is the process
of bringing the game design to life. Part of the game design process is the creation of game mechanics,
rules that define how the player interacts with the game. Playtesting is the process of evaluating the
impact of these rules on the player experience, with the goal being a net positive impact. However,
playtesting has a significant resource and time cost associated with it, as such game designers must
sometimes make decisions when evolving their game without the necessary knowledge of the impact on
the player experience.

We approach the study of this problem from a meta-programming perspective. We aim to empower
game designers with tools and techniques that give feedback about the quality of the games. In particular,
we study how dynamic analyses can provide live feedback about a game’s rules. We focus our efforts on
a concrete problem by studying PuzzleScript and evaluating our approach on a set of published games
written using that engine.

We formalize the design of PuzzleScript and implement a redesign of the technical implementation
using Rascal, a language workbench designed to facilitate meta-programming. This more extensible
and maintainable prototype implementation of PuzzleScript aids us in our initial goal and in future
PuzzleScript research. We then extend our implementation with our system of game mechanics analysis
and test games for game mechanic errors. Finally, we validate our approach on a set of real-world
published games and modify games to test for gameplay decay, the fall in gameplay quality as a result
of evolution in-game mechanics.

## Disclaimer
The code here is only a proof of concept and is in no way ready for mainstream use.
