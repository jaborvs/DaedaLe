/*
 * @Module: Config
 * @Desc:   Module that contains the functionality for the generation config
 * @Auth:   Borja Velasco -> code, comments
 */
module Generation::ADT::Command

/******************************************************************************/
// --- Data structure defines --------------------------------------------------

/*
 * @Name:   GenerationConfig
 * @Desc:   Data structure that models the configuration for generation
 */
data GenerationCommand
    = generation_command_chunk_size(int width, int height)
    | generation_command_objects_permanent(list[str] objects)
    | generation_command_pattern_max_size(int width, int height)
    | generation_command_empty()
    ;