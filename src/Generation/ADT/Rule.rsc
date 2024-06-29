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

GenerationRule enter_horizontal_generation_rule = generation_rule("playerenter_horizontal", "playeridle_horizontal");
GenerationRule enter_vertical_generation_rule   = generation_rule("playerenter_vertical",   "playeridle_vertical");
GenerationRule exit_horizontal_generation_rule  = generation_rule("playeridle_horizontal",  "playerexit_horizontal");
GenerationRule exit_vertical_generation_rule    = generation_rule("playeridle_vertical",    "playerexit_vertical");