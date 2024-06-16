/*
 * @Module: Exception
 * @Desc:   Module that contains all the exceptions to be thrown by the code
 * @Auth:   Borja Velasco -> code, comments
 */
module Generation::Exception

/******************************************************************************/
// --- Public config functions -------------------------------------------------

void exception_config_args_len() {
    throw "Exception Configuration: Too many configuration commands defined";
}

void exception_config_unknown_cmd(str cmd) {
    throw "Exception Configuration: Unknown command <cmd>";
}

void exception_config_chunk_size_illegal_arg(value v) {
    throw "Exception Configuration: Argument <v> cannot be converted to int";
}

/******************************************************************************/
// --- Public modules functions ------------------------------------------------

void exception_modules_duplicated_module(str name) {
    throw "Exception Modules: Duplicated module <name>";
}

void exception_modules_duplicated_verb(str verb) {
    throw "Exception Modules: Duplicated verb <verb>";
}

void exception_rules_no_verb() {
    throw "Exception Rules: All rules must have an assigned verb";
}