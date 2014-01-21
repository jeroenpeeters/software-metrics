module metrics::Dependency

import IO;
import String;
import List;
import Set;
import lang::java::m3::AST;
import lang::java::jdt::m3::AST;

import utils::Utils;

public loc main_web = 	|project://rni-main-web/|;

private alias Declarations 	= set[Declaration];

public void main(){

	list[loc] folders = [
		|project://rni-main-web/src/main/webapp/pages/home|,
		|project://rni-main-web/src/main/webapp/pages/register|,
		|project://rni-main-web/src/main/webapp/pages/search|,
		|project://rni-main-web/src/main/webapp/pages/assign-bsn|,
		|project://rni-main-web/src/main/webapp/pages/dossier|];

	list[loc] pages = crawl(folders, "xhtml");
	println("NumPages: <size(pages)>");
	
	set[str] beanRefs = getBeans(pages);
	println(beanRefs);
	
	set[str] classes = {};
	set[Declaration] imp = {};
	Declarations ast = createAstsFromEclipseProject(main_web, false);
	for(beanRef <- beanRefs){
		for(/compilationUnit(package, list[Declaration] imports, /c:class(n:/^<beanRef>$/i, _,_, _ )) <- ast){
			classes += fqPackageName(package) + ".<n>";
			imp += toSet(imports);
		}
	}
	
	ac = allPackages(ast);
	println(size(ac));
	println(size(classes));
	//set[str] diff = ac - classes;
	for(c <- sort(toList(classes))){
		println(c);
	}
	for(/\import(name) <- filterPackages(imp, "nl.rni")){
		println(name);
	}
}

private set[Declaration] filterPackages(set[Declaration] packages, str prefix){
	set[Declaration] newset = {};
	for(/i:\import(/^<prefix>.*$/) <- packages){
		newset += i;
	}
	return newset;
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

private set[str] getBeans(list[loc] pages){
	set[str] beanRefs = {};
	for(loc page <- pages){
		try
			beanRefs += getBeans(page);
		catch e: println("Skipping <page>! <e>");
	}
	return beanRefs;
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

private list[loc] crawl(list[loc] folders, str suffix){
	list[loc] pages = [];
	for(f <- folders){
		pages += crawl(f, suffix);
	}
	return pages;
}

private list[loc] crawl(loc dir, str suffix){
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
