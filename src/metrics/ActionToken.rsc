module metrics::ActionToken

import IO;
import Map;
import Set;
import List;
import lang::java::m3::AST;

import utils::AST;

public alias CountingMap = map[str, int];

public rel[str,int] getActionTokens(set[Declaration] ast){
	
	CountingMap actionTokens = ();
	
	for(/c:class(_, _,_, /m:method(_, methodName, _,_,_)) <- ast, !isAbstract(c)){
		if(/^<actionToken:[a-z]+>.*/ := methodName){
			actionTokens = add(actionTokens, actionToken);
		} else {
			println("No ActionToken detected in <methodName>");
		}
	}
	
	return toRel(actionTokens);
}

public list[tuple[str,int]] sort(rel[str,int] relation) = sort(toList(relation), bool(<str _, int i1>, <str _, int i2>){return i1 > i2;});


public CountingMap add(CountingMap cm, str s){
	if(s in cm) return cm[s] += 1; else return cm[s] = 1;
}