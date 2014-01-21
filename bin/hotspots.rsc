module hotspots

import IO;
import String;
import List;
import Set;
import lang::java::m3::AST;
import lang::java::jdt::m3::AST;
import lang::xml::DOM;

import utils::Utils;
import metrics::Volume;

public loc main_web = 				|project://rni-main-web/|;
public loc deelnemers_service = 	|project://rni-deelnemers-service/|;

private data Block = Block(loc, int);

private alias Blocks 		= list[Block];
private alias Declarations 	= set[Declaration];
private alias Statements 	= list[Statement];

public void main(){

	list[loc] folders = [
		|project://rni-main-web/src/main/webapp/pages/home|,
		|project://rni-main-web/src/main/webapp/pages/register|,
		|project://rni-main-web/src/main/webapp/pages/search|,
		|project://rni-main-web/src/main/webapp/pages/assign-bsn|,
		|project://rni-main-web/src/main/webapp/pages/dossier|];

	list[loc] pages = [];
	for(f <- folders){
		pages += crawl(f, "xhtml");
	}
	println("NumPages: <size(pages)>");
	
	set[str] beanRefs = {};
	for(loc page <- pages){
		try
			beanRefs += getBeans(page);
		catch e: println("Skipping <page>! <e>");
	}
	println(beanRefs);
	
	/*list[loc] javaFiles = crawl(|project://rni-main-web/src/main/java/|, "java");
	for(loc l <- javaFiles){
		println(substring(l.file, 0, size(l.file)-5) );
	}*/
	
	set[str] classes = {};
	Declarations ast = createAstsFromEclipseProject(|project://rni-main-web|, false);
	for(beanRef <- beanRefs){
		for(/compilationUnit(package, _, /class(n:/^<beanRef>$/i, _,_, _ )) <- ast){
			classes += fqPackageName(package) + ".<n>";
		}
	}
	
	ac = allPackages(ast);
	println(size(ac));
	println(size(classes));
	//set[str] diff = ac - classes;
	for(c <- sort(toList(classes))){
		println(c);
	}
}

private set[str] allPackages(ast){
	set[str] packages = {};
	for(/compilationUnit(package, _, _) <- ast){
		packages += fqPackageName(package);
	}
	return packages;
}

private set[str] allClasses(ast){
	set[str] classes = {};
	for(/compilationUnit(package, _, /class(n, _,_, _ )) <- ast){
		classes += fqPackageName(package) + ".<n>";
	}
	return classes;
}

private set[str] getBeans(loc page){
	set[str] beanRefs = {};
	str N = readFile(page);
	for(m:/<bean:\w*>\.<method:\w*>\(\)/ := N ){ // beans
		beanRefs += toLowerCase(bean);
	}
	for(m:/\#\{<bean:\w*>\}/ := N ){ // converters + validators
		beanRefs += toLowerCase(bean);
	}
	for(m:/validatorId=\"<bean:\w*>/ := N ){ // validators
		beanRefs += toLowerCase(bean);
	}
	
	
	return beanRefs;
}

public list[loc] crawl(loc dir, str suffix){
  res = [];
  for(str entry <- listEntries(dir)){
      loc sub = dir + entry;   
      if(isDirectory(sub)) {
          res += crawl(sub, suffix);
      } else {
	      if(endsWith(entry, suffix)) { 
	         res += [sub]; 
	      }
      }
  };
  return res;
}

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
		case s:\if(_,/\if(_,_))					: append s; // if within then branch
		case s:\if(_,_,/\if(_,_))				: append s; // if within else branch
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
    		case loop:\foreach(_,_, /\foreach(_,_,_)) : append loop; // foreach within foreach
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
