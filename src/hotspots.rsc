module hotspots

import IO;
import List;
import Set;
import lang::java::m3::AST;
import lang::java::jdt::m3::AST;

import metrics::Volume;

public loc main_web = 				|project://rni-main-web/|;
public loc deelnemers_service = 	|project://rni-deelnemers-service/|;

private data Block = Block(loc, int);

private alias Blocks 		= list[Block];
private alias Declarations 	= set[Declaration];
private alias Statements 	= list[Statement];


public void hotspots(loc project){
	Declarations ast = createAstsFromEclipseProject(project, false);
	
	print("Nested Loops", 	nestedLoops(ast));
	print("Nested Ifs", 	nestedIfs(ast), 20);
	print("Large Setters", 	largeSetters(ast));
	print("Large Getters", 	largeGetters(ast));
}

public list[Declaration] largeSetters(Declarations ast){
	return for(x <- ast){
		visit(x){
			case s:\method(_, /set.*/, _, _, statement) : if(sloc(statement@src,{})>11) append s;
		}
	}
}

public list[Declaration] largeGetters(Declarations ast){
	return for(x <- ast){
		visit(x){
			case s:\method(_, /get.*/, _, _, statement) : if(sloc(statement@src,{})>11) append s;
		}
	}
}

public Statements nestedIfs(Declarations ast){
	return for(/compilationUnit(package, _, /class(className, _,_, /m:method(_, name, _, _, stmnt) )) <- ast){
		visit(stmnt){
			case s:\if(_,/\if(_,_))				: append s; // if within then branch
			case s:\if(_,_,/\if(_,_))			: append s; // if within else branch
			case s:\if(_,/\if(_,_),/\if(_,_))	: append s; // if within then + else branch
		}
	}
}

public Statements nestedLoops(Declarations ast){
	// for each package found, find all classes, find all methods
	return for(/compilationUnit(package, _, /class(className, _,_, /m:method(_, name, _, _, stmnt) )) <- ast){
		visit(stmnt){
    		case loop:\for(_,_,_, /\for(_,_,_,_)) 		: append loop; // for within for
    		case loop:\for(_,_,_, /\for(_,_,_)) 		: append loop; // for within for
    		case loop:\for(_,_,_, /\foreach(_,_,_)) 	: append loop; // foreach within for
    		case loop:\for(_,_,_, /\while(_,_)) 		: append loop; // while within for
    		case loop:\for(_,_, /\for(_,_,_,_)) 		: append loop; // for within for
    		case loop:\for(_,_, /\for(_,_,_)) 			: append loop; // for within for
    		case loop:\for(_,_, /\foreach(_,_,_)) 		: append loop; // foreach within for
    		case loop:\for(_,_, /\while(_,_)) 			: append loop; // while within for
    		
    		// for each
    		case loop:\foreach(_,_, /\foreach(_,_,_)) 	: append loop; // foreach within foreach
    		case loop:\foreach(_,_, /\for(_,_)) 		: append loop; // for within foreach
    		case loop:\foreach(_,_, /\for(_,_,_)) 		: append loop; // for within foreach
    		case loop:\foreach(_,_, /\while(_,_)) 		: append loop; // while within foreach

			case loop:\while(_,/\while(_,_)) 			: append loop; // while within while
			case loop:\while(_,/\for(_,_,_,_)) 			: append loop; // for within while
			case loop:\while(_,/\for(_,_,_)) 			: append loop; // for within while
			case loop:\while(_,/\foreach(_,_,_)) 		: append loop; // foreach within while
    	}
	}
}


// private helper functions from this point onwards...

private Blocks makeBlocks(stmnts) = makeBlocks(stmnts, 0);
private Blocks makeBlocks(stmnts, int minSize) = [ Block(stmnt@src, sloc(stmnt@src, {})) | stmnt <- stmnts,  sloc(stmnt@src, {}) >= minSize];

private bool (Block, Block) blockSort = bool (Block(_, aVolume), Block(_, bVolume)) {
	return aVolume > bVolume;
};

// private print helpers

private void print(str name, stmnts) = print(name, stmnts, 0);
private void print(str name, stmnts, int minSize){
	blocks = sort(makeBlocks(stmnts, minSize), blockSort);
	//TODO: filter subset blocks
	println("\n#########################################################\n<name>: found <size(blocks)> with minSize of <minSize>\n#########################################################");
	for(Block(loc src, int volume) <- blocks){
		println("<volume>: <src>");
	}
}
