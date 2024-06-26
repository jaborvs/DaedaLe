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

GenerationRule enter_generation_rule = generation_rule("player_entry_start", "player_idle");
GenerationRule exit_generation_rule = generation_rule("player_idle", "player_exit_end");