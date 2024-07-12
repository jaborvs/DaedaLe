/*
 * @Module: Rule
 * @Desc:   Module that contains the functionality for the generation rule
 * @Auth:   Borja Velasco -> code, comments
 */
module Generation::ADT::Rule

/******************************************************************************/
// --- Data structure defines --------------------------------------------------

/*
 * @Name:   GenerationRule
 * @Desc:   Data structure that models a generation rule
 */
data GenerationRule
    = generation_rule(str left, str right)
    | generation_rule_empty()
    ;

/******************************************************************************/
// --- Global implicit generation rule defines ---------------------------------

GenerationRule enter_right_generation_rule = generation_rule("playerenter_right", "playeridle_right");
GenerationRule enter_up_generation_rule    = generation_rule("playerenter_up",    "playeridle_up");
GenerationRule enter_down_generation_rule  = generation_rule("playerenter_down",  "playeridle_down");
GenerationRule exit_right_generation_rule  = generation_rule("playeridle_right",  "playerexit_right");
GenerationRule exit_up_generation_rule     = generation_rule("playeridle_up",     "playerexit_up");
GenerationRule exit_down_generation_rule   = generation_rule("playeridle_down",   "playerexit_down");