module PuzzleScript::Syntax


//lexical Blankline = [^][\ \t]*;
// Blankline at least 2 newlines (2 separators)

//lexical Newlines = Newline*;
//lexical Blankline = [\n][\ ]*[\r];
//lexical Whitespace = [\ ];

//lexical SectionDelimiter = [=]* Newline;
lexical Pixel = [0-9.];
//keyword SectionHeader =  'RULES' | 'OBJECTS' | 'LEGEND' | 'COLLISIONLAYERS' | 'WINCONDITIONS' | 'LEVELS';

//syntax ID
//	= id: String;
//	
//syntax Color
//   = black: 'black'
//	|white: 'white'
//	|lightgray: 'lightgray' | 'lightgrey'
//	|gray: 'gray' | 'grey'
//	|darkgray: 'darkgray' | 'darkgrey'
//	|red: 'red'
//	|darkred: 'darkred'
//	|lightred: 'lightred'
//	|brown: 'brown'
//	|darkbrown: 'darkbrown'
//	|lightbrown: 'lightbrown'
//	|orange: 'orange'
//	|yellow: 'yellow'
//	|green: 'green'
//	|darkgreen: 'darkgreen'
//	|lightgreen: 'lightgreen'
//	|blue: 'blue'
//	|lightblue: 'lightblue'
//	|darkblue: 'darkblue'
//	|purple: 'purple'
//	|pink: 'pink'
//	|transparent: 'transparent';
	
//syntax Sprite = sprite: Pixel*;

keyword Keywords
	= 'RULES' | 'OBJECTS' | 'LEGEND' | 'COLLISIONLAYERS' 
	| 'WINCONDITIONS' | 'LEVELS' | 'title' | 'author' 
	| 'homepage' | 'or' | '\<' | '\>' | '^' | 'v' | 'Some'
	| 'All' | 'No'|'on' | 'message' | 'and' | 'randomDir';

lexical Newline = [\n];

//syntax Newline = '\r\n';
lexical String = [a-z0-9.A-Z]+ !>> [a-z0-9.A-Z] \ Keywords;
//layout Standard = [\ \t\r]*;

lexical LAYOUT = [\t\r\ ];
layout LAYOUTLIST = LAYOUT*  !>> [\t\r\ ] ;

start syntax PSGame
 	= game:Prelude;

//syntax Section
//	= Prelude
//	| SectionDelimiter? SectionHeader SectionDelimiter? SectionContent
//	;
//	
//syntax SectionContent
//	= empty_section: ;
 	
syntax Prelude
	= prelude: {PreludeData Newline}*
	// | empty_prelude: Newline*
	;
	
syntax PreludeData
	= title: 'title' String*
	| author: 'author' String*
	| homepage: 'homepage' String*
	| empty_pd:
	;

//syntax Objects
//	= objects: SectionDelimiter? 'Objects' Newline SectionDelimiter? Newline* ObjectData*
//	|empty_objects:
//	;
//	
//syntax ObjectData
//	= objectdata: String Newline String* Newline {Sprite Newline}*
//	;
//
//syntax Legend
//	= empty:
//	;
//
//syntax Sounds
//	= empty:
//	;
//
//syntax Layers
//	= empty:
//	;
//
//syntax Rules
//	= empty:
//	;
//	
//syntax WinConditions
//	= empty:
//	;
//	
//syntax Levels
//	= empty:
//	;