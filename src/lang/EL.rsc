module lang::EL

import IO;
import String;
import ParseTree;     

layout Whitespace = [\t-\n\r\ ]*; 

lexical StrLiteral = [a-zA-Z0-9/.\-\']+;
lexical IntegerLiteral = [0-9]+;  
lexical Identifier = [a-zA-z.]+[a-zA-z.0-9]*;
lexical Identifier2 = Identifier "()";
lexical Identifier3 = Identifier "(" Identifier ")";

// We define the concrete syntax
start syntax EmbeddedEl
	= embeddedEl: StrLiteral
	| embeddedEl: StrLiteral ConcreteEl StrLiteral
	| ConcreteEl
	;
start syntax ConcreteEl
  	= el: "#{" ConcreteExpr "}"
  	| el: "${" ConcreteExpr "}"
  	;
syntax ConcreteExpr
	= ConcreteIdent
	| strLiteral: "\'" StrLiteral "\'"
	| bracket "(" ConcreteExpr ")"
	> boolExpr: ConcreteExpr "\>" ConcreteExpr
	> ternary: ConcreteExpr "?" ConcreteExpr ":" ConcreteExpr
	; 
syntax ConcreteIdent
	=  identifier: Identifier2
	|  identifier: Identifier3
	| identifier: Identifier
	;

// We define the abstract syntax
data El
	= el(ElExpr expr)
	| embeddedEl(str a)
	| embeddedEl(str a, El el, str b)
	;
data ElExpr
	= ternary(ElExpr expr, ElExpr exp1, ElExpr exp2)
	| boolExpr(ElExpr exp1, ElExpr exp2)
	| identifier(str name)
	| strLiteral(str val)
	| boolLiteral(bool b)
	;                

// Parser
public EmbeddedEl parse(str txt) = parse(#EmbeddedEl, txt);
// To Ast Imploder
public El load(str txt) = implode(#El, parse(txt));

// Compute possible productions
public set[El] possibleProductions(embeddedEl(str a, El el, str b)) 							= embed(a, b, possibleProductions(el));
public set[ElExpr] possibleProductions(el(ElExpr expr)) 											= possibleProductions(expr);
public set[El] possibleProductions(e:embeddedEl(str a)) 											= {e};
public set[ElExpr] possibleProductions(ternary(ElExpr expr, ElExpr exp1, ElExpr exp2))	= possibleProductions(exp1) + possibleProductions(exp2);
public set[ElExpr] possibleProductions(boolExpr(ElExpr exp1, ElExpr exp2)) 				= {boolLiteral(true), boolLiteral(false)};
public set[ElExpr] possibleProductions(ElExpr exp) 												= {exp};
// Helper to embed possible production in Embedded El
public set[El] embed(str a, str b, set[ElExpr] exprs) 											= {embeddedEl(a, el(expr), b) | expr <- exprs};

// Evaluate EL
public str eval(embeddedEl(str a, El el, str b)) 	= "<a><eval(el)><b>";
public str eval(embeddedEl(str a))						= a;
public str eval(el(ElExpr expr))							= eval(expr);
public str eval(strLiteral(str val))					= val;
public str eval(boolLiteral(bool val))					= "<val>";

// Evaluate a set of El
public set[str] eval(set[El] els) = {eval(el) | el <- els};
// Get all possible evaluations of the given EL text
public set[str] evals(str text) {
	try	return eval(possibleProductions(load(text)));
	catch e: println("WHOA! <text> :: <e>");
	return {};
}