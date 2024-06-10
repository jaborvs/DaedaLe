/*
 * @Module: AST
 * @Desc:   Module that defines the structures to parse the AST of Papyrus
 * @Author: Borja Velasco -> code, comments
 */
module Generation::AST

/******************************************************************************/
// --- Tutorial structure defines ----------------------------------------------

/*
 * @Name:   PapyrusData
 * @Desc:   Data structure that stores a parsed Tutorial for its generation
 */
data PapyrusData 
    = papyrus_data(str title, list[LevelDraftData] level_drafts);

/******************************************************************************/
// --- Level Draft structure defines -------------------------------------------

/*
 * @Name:   LevelDraftData
 * @Desc:   Data structure that stores a high level representation of a level
 *          for its generation
 */
data LevelDraftData
    = level_draft_data(str number, list[LessonData]);

/******************************************************************************/
// --- Lesson structure defines ------------------------------------------------

/*
 * @Name:   LessonData
 * @Desc:   Data structure that stores a lesson to be taught inside a level
 */
data LessonData
    = lesson_data(str number, str name, str description, list[Goal] goals);

/******************************************************************************/
// --- Goal structure defines --------------------------------------------------

/*
 * @Name:   GoalData
 * @Desc:   Data structure that models one of the goals to be taught by each
 *          lesson
 */
data GoalData
    = goal_data(str name, str modifier);
