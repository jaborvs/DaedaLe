/*
 * @Module: Utils
 * @Desc:   Module with some general functionality to be used accross all modules
 * @Auth:   Borja Velasco -> code, comments
 */

module Utils

/******************************************************************************/
// --- General modules imports -------------------------------------------------
import String;

/******************************************************************************/
// --- Data structures defines -----------------------------------------------

/*
 * @Name:   Coords
 * @Desc:   Data structure to model coordinates
 */
alias Coords = tuple[
    int x,  // x-coordinate
    int y   // y-coordinate
];

/******************************************************************************/
// --- Public functions --------------------------------------------------------

str string_capitalize(str word:/^<letter:[a-z]><rest:.*>/) 
    = "<toUpperCase(letter)><rest>";

str string_capitalize(str word) 
    = word;