module metrics::NanoPattern

import IO;
import String;
import List;
import Set;
import lang::java::m3::AST;
import lang::java::jdt::m3::AST;

data NannoPattern 
	// Calling patterns
	= noParam()			// Takes no argument
	| noReturn()		// Returns void
	| recursive()		// Calls itself recursively
	| sameName()		// Calls another method with the same name
	| leaf()			// Does not issue any method calls
	
	// Object orientation
	| objectCreator()	// Creates new object
	| fieldReader()		// Reads (static or instance) field values from an object
	| fieldWriter()		// Writes values to (static or instance) field of an object
	| typeManipulator()	// Uses type casts or instanceof operations
	
	// Control flow
	| straightLine()	// No branches in method body
	| looping()			// One or more control flow loops in method body
	| exceptions()		// May throw an unhandled exception
	
	// Data flow
	| localReader()		// Reads values of local variables on stack frame
	| localWriter()		// Writes values of local variables on stack frame
	| arrayCreator()	// Creates a new array
	| arrayReader()		// Reads values from an array
	| arrayWriter()		// Writes values to an array
	;

public loc main_web = 				|project://rni-main-web/|;

public void runNanoPatterns(loc project){
	set[Declaration] ast = createAstsFromEclipseProject(project, false);
	for(/compilationUnit(package, _, /class(className, _,_, /m:method(_, name, _, _, stmnt) )) <- ast){
		println("<isRecursive(m)> :: <m@src>" );
	}
}
/*
\method(Type \return, str name, list[Declaration] parameters, list[Expression] exceptions, Statement impl)
| \method(Type \return, str name, list[Declaration] parameters, list[Expression] exceptions)
*/

public bool isNoParam(method(_,_,params,_,_)) 	= size(params) == 0;
public bool isNoParam(method(_,_,params,_)) 	= size(params) == 0;

public bool isNoReturn(method(\void(),_,_,_,_)) = true;
public bool isNoReturn(method(\void(),_,_,_)) 	= true;
public bool isNoReturn(method(_,_,_,_,_)) 		= false;
public bool isNoReturn(method(_,_,_,_)) 		= false;

/*
\methodCall(bool isSuper, str name, list[Expression] arguments)
    | \methodCall(bool isSuper, Expression receiver, str name, list[Expression] arguments)
    */
public bool isRecursive(m:method(rtype, name, params, _, stmnt)) = /methodCall(false, name, _) := stmnt;

public bool isSameName(m:method(rtype, name, params, _, stmnt)) = /methodCall(_, name, _) := stmnt;

