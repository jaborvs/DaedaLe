/*
 * @Module: Config
 * @Desc:   Module that contains the functionality for the generation config
 * @Auth:   Borja Velasco -> code, comments
 */
module Generation::ADT::Config

/******************************************************************************/
// --- Data structure defines --------------------------------------------------

/*
 * @Name:   GenerationConfig
 * @Desc:   Data structure that models the configuration for generation
 */
data GenerationConfig 
    = generation_config(int width, int height)
    | generation_config_empty()
    ;