module metrics::series1

import IO;
import List;
import Set;
import String;
import lang::java::jdt::m3::Core;
import lang::java::jdt::m3::AST;
import lang::java::m3::AST;

import metrics::CyclomaticComplexity;
import metrics::Volume;
import metrics::Duplication;
import metrics::Rank;

public loc main_web 	= |project://rni-main-web/|;

public void series1(loc project, bool verbose){
	M3 m3 = createM3FromEclipseProject(project);
	
	comments = {};
	for(<_,l> <- m3@documentation){
		comments += toSet(readFileLines(l));
	}

	ast = createAstsFromEclipseProject(project, false);
	
	int totalSloc = sloc(ast, comments);
	println("\n## Volume ##");
	println("Total SLOC: <totalSloc>");
	
	if(verbose) println("SLOC per unit:");
	slocList = slocPerUnit(ast, comments);
	if(verbose){
		for(a <- reverse(sort(slocList))){
			println("<a[0]> :: <a[1]> :: (<a[2]>)");
		}
	}
	
	println("\n## Cyclomatic complexity per unit ##");
	ccList = ccPerUnit(ast, true);
	if(verbose){
		for((name: <cc, ref>) <- /*reverse(sort(ccList))*/ ccList){
			println("<name> :: <cc> :: (<ref>)");
		}
		//println("Number of methods with minimal CC of 10 is <size(minCC(10,ccList))>");
	}
	
	real duplicationPrcnt = duplication(ast, 6, comments);
	println("\n## Duplication ##");
	println("%: <duplicationPrcnt>");
	
	println("\n## Summary ##");
	println("Total SLOC : <rankSloc(totalSloc)>");
	println("UnitSize: <rankUnitSize(slocList)>");
	println("Duplication: <rankDuplication(duplicationPrcnt)>");
	println("Complexity: <rankComplexity(ccList, slocList)>");
}
