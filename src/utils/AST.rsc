module utils::AST

import lang::java::m3::AST;

public bool isAbstract(Declaration c) 	= [X*, abstract(), Y*] := c@modifiers;
public bool isPublic(Declaration c)	= [X*, \public(), Y*] := c@modifiers;