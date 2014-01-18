module visualization::VolumeCC

import IO;
import List;
import Set;
import String;
import util::Math;
import lang::java::jdt::m3::Core;
import lang::java::jdt::m3::AST;
import lang::java::m3::AST;
import vis::Figure;
import vis::Render;
import vis::KeySym;

import util::Editors;

import metrics::Volume;
import metrics::CyclomaticComplexity;
import utils::Utils;

public loc main_web 	= |project://rni-main-web/|;

private data Class = Class(loc class, str className, str package);
private anno list[Unit]  Class @ units;
private anno num Class @ volume;

private data Unit = Unit(loc method, str name);
private anno int Unit @ cc;
private anno int Unit @ volume;

public void volumeCCVis(loc project){
	ast = createAstsFromEclipseProject(project, false);
	render("UnitVolumeCC Vis", unitVolumeCCViz(ast, readComments(project), 5, 5));
}

public Figure unitVolumeCCViz(ast, comments, int minVolume,int  minCC){
	list[Figure] figures = []; // list of figures to be rendered into the treemap
	num totalSize = 0; // total size of the project
	
	c = false;
	str selClass = "";
	str selMethod = "";
	str selSize = "";
	str selCC = "";
	row1 = [
		box(text( str () {return selClass;}, left(), fontSize(10)), hshrink(0.5), lineWidth(0)), 
		text("Volume LOC", fontSize(10), fontBold(true), left()), 
		text( str () {return selSize;}, left(), fontSize(10), left())];
	row2 = [
		box(text( str () {return selMethod;}, left(),fontSize(12), fontBold(true)), hshrink(0.5), lineWidth(0)), 
		text("Cyclomatic complexity", fontSize(10), fontBold(true), left()),
		text( str () {return selCC;}, left(), fontSize(10), left())];
	
	int nf = 1;
	infoBox = vcat([grid([row1,row2], hgap(10)) 
	,scaleSlider(int() { return 1; },     
                                    int () { return 100; },  
                                    int () { return nf; },    
                                    void (int s) { nf = s; println(nf); }, 
                                    width(200))
	], hgap(10), fillColor("white"), vshrink(0.1));
	
	list[Class] classList = sort(composedMetric(ast, comments), classSort);
	for(class:Class(loc classLoc, str className, str package) <- classList){
		list[Figure] blocks = []; 
		num classSize = class@volume;
		setPrecision(1000);
		for(u:Unit(loc methodLoc, str unitName) <- sort(class@units, unitSort)){
			itemSize = u@volume;
			complexity = u@cc;
			mpackage = "<package>.<className>";
			mname = unitName;
			
			real epsilon = 0.00000001;
			
			blocks += box(hshrink((itemSize/toReal(classSize))-epsilon), fillColor(determineComplexityColor(complexity)), lineColor(color("grey")), lineWidth(0),
				onMouseDown(openLocation(methodLoc)), onMouseEnter(void () {c=true; selMethod=mname; selClass=mpackage;selSize="<itemSize>";selCC="<complexity>";}), onMouseExit(void () { c = false ; }));
		}
		totalSize += classSize;
		figures += box( hcat(blocks), area(classSize), lineColor(color("black")), lineWidth(3));
	}
	println("figs: <size(figures)>");
	println("totalSize: <totalSize>");
	return vcat([infoBox, vscrollable(treemap(slice(figures,0, size(figures)-1), height((totalSize/50 )*nf), width((totalSize/50)*nf)), lineWidth(0)) ], height(100));
}

public bool (Class, Class) classSort = bool (Class a, Class b) {
	return a@volume > b@volume;
};

public bool (Unit, Unit) unitSort = bool (Unit a, Unit b) {
	return a@cc > b@cc;
};

public int totalVolume(list[Unit] units) = sum([ u@volume | u <- units]);

public list[Class] composedMetric(set[Declaration] ast, set[str] comments){
	list[Class] classSet = [];
    for(/compilationUnit(package, _, /c:class(className, _,_, list[Declaration] body)) <- ast){
    	
    	Class clazz = Class(c@src, className, fqPackageName(package));
    	clazz@units = [];
    	
    	for(/m:method(_, name, _, _, s) <- body){
    		Unit u = Unit(m@src, name);
    		u@cc = cc(s, false);
    		u@volume = sloc(s@src, comments);
    		clazz@units += u;
    	}
		clazz@volume = sum([u@volume | u <- clazz@units]);
    	classSet += clazz;
    }
    return classSet;
}