module PuzzleScript::Syntax2

layout Sandard = [\ \r\t\n]*;
// such a layout causes a lot of ambiguity in a syntax that use
// spaces and linebreaks to structure itself, but maybe with a 
// a good syntax it's still possible to parse?
// it would depend on how strict we want to be, where do we draw the line

lexical Newline ='\r\n';
lexical Whitespace = [\ ];
lexical String = [a-z0-9.A-Z]+ >> [\r\ ][\n]?;
lexical SectionDelimiter = [=]*;
lexical Pixel = [0-9.];
keyword SectionHeaders 
	=  'RULES' | 'OBJECTS' | 'LEGEND' | 'COLLISIONLAYERS' | 'WINCONDITIONS' | 'LEVELS';

keyword PreludeKeywords
	= 'title' | 'author' | 'homepage';

keyword Keywords
	= | 'or' | '\<' | '\>' 
	| '^' | 'v' | 'Some'
	| 'All' | 'No'|'on' | 'message' | 'and' | 'randomDir'
	|PreludeKeywords
	|SectionHeaders
	;

syntax ID
	= id: String \ Keywords;
	
syntax Color
   = black: 'black'
	|white: 'white'
	|lightgray: 'lightgray' | 'lightgrey'
	|gray: 'gray' | 'grey'
	|darkgray: 'darkgray' | 'darkgrey'
	|red: 'red'
	|darkred: 'darkred'
	|lightred: 'lightred'
	|brown: 'brown'
	|darkbrown: 'darkbrown'
	|lightbrown: 'lightbrown'
	|orange: 'orange'
	|yellow: 'yellow'
	|green: 'green'
	|darkgreen: 'darkgreen'
	|lightgreen: 'lightgreen'
	|blue: 'blue'
	|lightblue: 'lightblue'
	|darkblue: 'darkblue'
	|purple: 'purple'
	|pink: 'pink'
	|transparent: 'transparent';
	
syntax Sprite = sprite: Pixel* >> [\r][\n]  \ Keywords;

start syntax PSGame
 	= game: Prelude Objects [$];

syntax Section
	= Prelude
	| SectionDelimiter? SectionHeaders SectionDelimiter? SectionContent
	;
	
syntax SectionContent
	= empty_section: ;
 	
syntax Prelude
	= prelude: PreludeData*
	|empty_prelude:
	;

syntax PreludeKeyword = p_key: 'title' | 'author' | 'homepage';
syntax PreludeData = p_value: PreludeKeyword ' ' ID*;

syntax PreludeData
	= title: 'title ' ID*
	|author: 'author ' ID*
	|homepage: 'homepage ' ID*
	;

syntax Objects
	= objects: SectionDelimiter? 'Objects' SectionDelimiter? ObjectData*
	|empty_objects:
	;
	
syntax ObjectData
	= objectdata: ID ID* Sprite*
	;

syntax Legend
	= empty:
	;

syntax Sounds
	= empty:
	;

syntax Layers
	= empty:
	;

syntax Rules
	= empty:
	;
	
syntax WinConditions
	= empty:
	;
	
syntax Levels
	= empty:
	;