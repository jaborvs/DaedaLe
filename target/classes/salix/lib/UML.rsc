module salix::lib::UML

import lang::xml::DOM;
import salix::Node;
import salix::SVG;

salix::Node::SalixNode uml2svgNode(str src) = node2node(parseXMLDOM(uml2svg(src)));

private salix::Node::SalixNode node2node(lang::xml::DOM::SalixNode n) {
  switch (n) {
    case document(lang::xml::DOM::SalixNode root):
      return node2node(root);
      
    case element(_, str name, list[lang::xml::DOM::SalixNode] kids): {
      map[str,str] attrs = ( k: v | attribute(_, str k, str v) <- kids );
      list[salix::Node::SalixNode] nodes = [ node2node(kid) | lang::xml::DOM::SalixNode kid <- kids, attribute(_, _, _) !:= kid ];
      return svgElement(name, nodes, attrs, (), ());
    } 
    
    case charData(str text):
      return txt(text);
      
    case cdata(str text):
      return txt(text);

    case entityRef(str name):
      return txt("&<name>;");
      
    case charRef(int code):
      return txt("&#<code>;");
      
    case comment(_):
      return txt("");
      
    default:
      throw "Unsupported node: <n>";     
  }
}

@javaClass{salix.lib.PlantUML}
java str uml2svg(str src);
