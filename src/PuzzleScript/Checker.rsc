module PuzzleScript::Checker

import PuzzleScript::AST;
import util::Math;
import List;
import String;

data Msg
	// object messages
	= invalid_index(str object_name, int pos)
	;
	
list[Msg] check_objects(list[OBJECTDATA] objects) {
	list[Msg] msgs = [];
	
	for(OBJECTDATA object <- objects){
		if (size(object.sprite) < 1) continue;
	
		for(str sprite <- object.sprite[0]){
			for(str pixel <- split("", sprite)){
				if (pixel == ".") {
					continue;
				}
				
				int converted = toInt(pixel);
				if (converted + 1 >= size(object.colors)) {
					msgs = msgs + invalid_index(object.id, converted);
				}
				
			}
		}
		
	}
	
	return msgs;
}