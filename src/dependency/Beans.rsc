module dependency::Beans

import IO;
import Set;
import List;
import Relation;
import String;

import lang::java::m3::AST;
import lang::java::jdt::m3::AST;

import Rni;

data Bean 
	= bean(str name, str method, str trail, loc page)
	;
	
private bool inSet(<str name, str method>, set[Bean] beans){
	for(bean(bname, bmethod, _, _) <- beans){
		if(eqLowerCase(bname, name) && eqLowerCase(bmethod, method)) return true;
	}
	return false;
}

private bool eqLowerCase(str a, str b) = toLowerCase(a) == toLowerCase(b);


public void findOutjectedValues(){
	rel[str,loc] outjectedVars = {<name, f@src> | /c:class(n:/^<beanName:.*bean>$/i, _,_, /f:field(/simpleName(typeName), /variable(name, _))) <- (getLoketAst()), !isAbstract(c), hasOutAnnotation(f) && !hasInAnnotation(f) };
	println(outjectedVars);
	println(size(outjectedVars));
	
	rel[str,loc] els = {};
	for(loc page <- listXhtml() + listPageXml()){
		els += getElExpressions(page);
	}
	
	set[str] usedOutjectedVars = {};
	for(var <- domain(outjectedVars)){
		for(<el, page> <-els){
			if(/<var>/ := el){
				usedOutjectedVars += var;
			}
		}
	}
	println("used :: <size(usedOutjectedVars)>");
	set[str] unusedOutjectedVars = domain(outjectedVars) - usedOutjectedVars;
	println("unused :: <size(unusedOutjectedVars)>");
	
	for(str var <- unusedOutjectedVars){
		for(<var, page> <- outjectedVars) println("<var> :: <page>");
	}
}

private bool hasOutAnnotation(Declaration decl) = /normalAnnotation("Out",_) := decl@modifiers || /markerAnnotation("Out") := decl@modifiers;
private bool hasInAnnotation(Declaration decl) = /normalAnnotation("In",_) := decl@modifiers || /markerAnnotation("In") := decl@modifiers;

public void findUnusedBeanMethods(){
	set[Bean] beans = getBeans(listXhtml() + listPageXml());
	set[tuple[str,str]] beanRefs = 	{ <toLowerCase(n), toLowerCase(m)> | bean(n, m, _, _) <- beans } +
	  								{ <toLowerCase(n), "get<toLowerCase(m)>"> | bean(n, m, _, _) <- beans } +
	  								{ <toLowerCase(n), "set<toLowerCase(m)>"> | bean(n, m, _, _) <- beans } +
	  								{ <toLowerCase(n), "is<toLowerCase(m)>"> | bean(n, m, _, _) <- beans };
	 		
	set[tuple[str,str]] unusedBeans = {};
	for(/c:class(n:/^<beanName:.*bean>$/i, _,_, /m:method(_, methodName, _,_,_)) <- (getLoketAst()), !isAbstract(c))
		if(isPublic(m) && <toLowerCase(beanName),toLowerCase(methodName)> notin beanRefs) unusedBeans += <beanName, methodName>;
	
	set[str] commonBeanMethods = getMethodsForBeans(beans, {"commonmanagedbean", "currmanagedbean", "managedbean"});
	
	unusedBeans = {b | b:<bname, bmethod> <- unusedBeans, toLowerCase(bmethod) notin commonBeanMethods,
		 !startsWith(bmethod, "get"), !startsWith(bmethod, "set"), !startsWith(bmethod,"is")  };
	
	for(s <- sort(toString(unusedBeans))) println(s);
	println(size(unusedBeans));
	
}

public void findUnusedAbstractBeanMethods(){
	set[Bean] beans = getBeans(listXhtml() + listPageXml());
	set[tuple[str,str]] beanRefs = 	{ <toLowerCase(n), toLowerCase(m)> | bean(n, m, _, _) <- beans } +
	  								{ <toLowerCase(n), "get<toLowerCase(m)>"> | bean(n, m, _, _) <- beans } +
	  								{ <toLowerCase(n), "set<toLowerCase(m)>"> | bean(n, m, _, _) <- beans } +
	  								{ <toLowerCase(n), "is<toLowerCase(m)>"> | bean(n, m, _, _) <- beans };
	
	rel[str,str] abstract = {};
	rel[str,str] used = {};
	ast = getLoketAst();
	for(/c:class(n:/^<beanName:.*bean>$/i, list[Type] extends,_, _) <- (mainWebAst()), !isAbstract(c), size(extends)>0){
		rel[str,str] methodInvocs = toLowerCase(beanMethodInvocations(lookupClassDeclarations(ast, extends)));
		abstract += methodInvocs;
		for(invoc:<_,m> <- methodInvocs){
			if(<toLowerCase(beanName),m> in beanRefs){
				used += invoc;
			}
		}
	}
	println(size(used));
	println(used);
	println(size(abstract - used));
	println(abstract - used);
}

private rel[str,str] toLowerCase(rel[str,str] rels) = {<toLowerCase(a),toLowerCase(b)> | <a,b> <- rels};

private rel[str,str] beanMethodInvocations(set[Declaration] classes) = 
	{<beanName, mname> | /class(beanName,_,_,/m:method(_,mname,_,_,_)) <- classes, isPublic(m)};

private set[Declaration] lookupClassDeclarations(ast, list[Type] types) = 
	{c | /c:class(/className, _,_,_) <- ast, className in getTypeNames(types)};
	
private set[str] getTypeNames(list[Type] types) = 
	{typeName | /simpleType( simpleName(typeName)) <- types};

public void findMissingBeanMethods(){
	beanMethods = for(/c:class(n:/^<beanName:.*bean>$/i, _,_, /m:method(_, methodName, _,_,_)) <- (mainWebAst()))
		if(isPublic(m) ) append <toLowerCase(beanName), toLowerCase(methodName)>;
		
	set[tuple[str,str]] beanRefs = 	{ <toLowerCase(n), toLowerCase(m)> | bean(n, m, _, _) <- getBeans(listXhtml() + listPageXml()) };
	
	a = for(</<bname:.*bean>/, bmethod> <- beanRefs){
		if(<bname, bmethod> notin beanMethods && <bname, "get<bmethod>"> notin beanMethods 
			&& <bname, "set<bmethod>"> notin beanMethods && <bname, "is<bmethod>"> notin beanMethods){
			append <bname, bmethod>;
		}
	}
	
	for(<bname, bmethod> <- sort(a)){
		println("<bname>.<bmethod>");
	}
}

private set[str] getMethodsForBeans(set[Bean] beans, set[str] beanNames){
	beanNames = { toLowerCase(s) | s <- beanNames};
	a = for(bean(bname, bmethod, _, _) <- beans){
		if(size(bname) > 0 && toLowerCase(bname) in beanNames) append "<bmethod>";
	}
	return toSet(a);
}

public set[str] toString(set[tuple[str,str]] input) = { "<a>.<b>" | <a, b> <- input };
	
public set[Declaration] findUnusedBeanClasses(){
	Declarations ast = mainWebAst();
	set[Declaration] allBeansClasses = getBeanClasses(ast); // al bean classes
	set[loc] pages = listXhtml() + listPageXml(); // all pages
	set[Bean] beanRefs = getBeans(pages); // all bean references in pages
	map[str, set[loc]] beanMap = beanMap(beanRefs); // create set of unique beans mapped onto the locations
	
	// foreach bean reference, lookup the bean
	set[Declaration] usedBeanClasses = {};
	for(beanName <- beanMap){
		for(/compilationUnit(package, list[Declaration] imports, /c:class(n:/^<beanName>$/i, _,_, _ )) <- ast){
			usedBeanClasses += {c};
		}
	}
	// extract used beans from all beans, filter abstract classes
	set[Declaration] unusedBeansClasses = filterAbstract(allBeansClasses - usedBeanClasses);
	
	return unusedBeansClasses;
}

public set[str] findInconsistentlyNamedBeans(){
	Declarations ast = mainWebAst();
	set[Declaration] allBeansClasses = getBeanClasses(ast);
	set[str] inconsistentBeanNames = {};
	
	for(c:class(name, _,_,_) <- allBeansClasses){
		if([X*, annotation(singleMemberAnnotation("Name",stringLiteral(/\"<annotationName:.*>\"/))), Y*] := c@modifiers){
			if(toLowerCase(name) != toLowerCase(annotationName)){
				inconsistentBeanNames += {name};
			}
		}
	}
	return inconsistentBeanNames;
}

public set[str] findBeansWithoutNameAnnotation(){
	Declarations ast = mainWebAst();
	set[Declaration] allBeansClasses = getBeanClasses(ast);
	set[str] noNameAnno = {};
	
	for(c:class(name, _,_,_) <- allBeansClasses){
		if(![X*, annotation(singleMemberAnnotation("Name",stringLiteral(/\"<annotationName:.*>\"/))), Y*] := c@modifiers){
			if(!isAbstract(c)) noNameAnno += {name};
		}
	}
	return noNameAnno;
}

private set[Declaration] filterAbstract(set[Declaration] beans) = { c | c <- beans, !isAbstract(c)};
private bool isAbstract(Declaration c) 	= [X*, abstract(), Y*] := c@modifiers;
private bool isPublic(Declaration c)	= [X*, \public(), Y*] := c@modifiers;


private set[Declaration] getBeanClasses(Declarations ast) =
	 {clazz | /compilationUnit(package, imports, /clazz:class(n:/^.*bean$/i, _,_, _ )) <- ast};

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

private set[Bean] getBeans(set[loc] pages){
	set[Bean] beanRefs = {};
	for(loc page <- pages){
		rel[str, loc] els = getElExpressions(page);
		for(<el, _> <- els){
			try
				beanRefs += getBeans(el, page);
			catch e: println("Skipping <page>! <e>");
		}
	}
	return beanRefs;
}

private map[str, set[loc]] beanMap(set[Bean] beans){
	map[str, set[loc]] beanMap = ();
	for(bean(name,_,_, page) <- beans){
		if(name in beanMap) beanMap[name] += {page};
		if(name notin beanMap) beanMap[name] = {page};
	}
	return beanMap;
}

public set[str] classNames(set[Declaration] ast) = {n | class(n, _,_,_) <- ast};

public rel[str,loc] getElExpressions(loc page) = {<s,page> | /(?s)((?!\#\{messages\[\')\#\{)<s:((?!\}).)+>\}/ := readFile(page)};
public set[Bean] getBeans(str el, loc page) = { bean(toLowerCase(bname), toLowerCase(bmethod), "", page) | /<bname:\w*>\.<bmethod:\w*>[^\w]?/ := el};

private set[Bean] getBeans(loc page) = 
	{ bean(toLowerCase(bname), toLowerCase(bmethod), trail, page) | m:/((?!\#\{messages)\#\{)((?!\.).){0,}?<bname:\w*>\.(<bmethod:\w+><trail:.*?>)?\}/ := readFile(page), endsWith(toLowerCase(bname), "bean")  } +
	{ bean(toLowerCase(bname), "", "", page) | m:/((?!\#\{messages)\#\{)((?!\.).){0,}?<bname:\w*>\}/ := readFile(page), endsWith(toLowerCase(bname), "bean")  } +
	{ bean(toLowerCase(bname), toLowerCase(bmethod), trail, page) | m:/#\{messages\[<bname:\w*>\.(<bmethod:\w+><trail:.*?>)?\]\}/ := readFile(page), endsWith(toLowerCase(bname), "bean")  };
