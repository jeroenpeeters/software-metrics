module lang::Html::Concrete

import String;

//  <test attr1 = "ke es "/>
lexical LayoutList 
	= [\n\r\ ]
//	| [\ ] >> "/"
//	| "\"" !<< [\ ] !>> "\""
	;
	
layout Whitespace = LayoutList*;

lexical Char 	= [a-zA-Z];
lexical Num 	= [0-9];
lexical CharNum	= Char|Num;
lexical TagName = Char+ CharNum*;
lexical AttrName = Char+ CharNum*;
lexical AttrValue = [a-zA-Z0-9\ \-.]*;

start syntax Html
	= html: Element+
	;
	
syntax Preamble
	= preamble: "\<?xml" Attribute* "?\>"
	;
	
syntax Element
	= Preamble
	| element: "\<" TagName Attribute* "/\>"
	| element: "\<" TagName ":" TagName Attribute* "/\>"
	> element: "\<" TagName Attribute* "\>" Element+ "\</" TagName "\>"
	> element: "\<" TagName ":" TagName  Attribute* "\>" Element+ "\</" TagName "\>"
	;

syntax Attribute
	= attribute: AttrName "=" "\"" AttrValue "\""
	| attribute: AttrName "=" "\'" AttrValue "\'"
	;



void element(TagName startTag, Element endTag, TagName endTag){
	if(startTag != endTag) filter;
	//return sort(startTag, elem);
}

public Html parseHtml(loc file) = parse(#Html, file);