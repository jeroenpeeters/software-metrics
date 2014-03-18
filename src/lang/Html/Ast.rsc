module lang::Html::Ast

data Html
	= html(list[Element])
	;
data Preamble
	= preamble(list[Attribute] attributes)
	;
data Element
	= preamble(list[Attribute] attributes) 
	| element(str name, list[Attribute] attributes)
	| element(str prefix, str name, list[Attribute] attributes)
	| element(str name, list[Attribute] attributes, list[Element] elements, str endTag)
	| element(str prefix, str name, list[Attribute] attributes, list[Element] elements, str endTag)
	
	;
data Attribute
	= attribute(str name, str val)
	;