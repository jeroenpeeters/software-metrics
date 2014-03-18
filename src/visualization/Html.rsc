module visualization::Html

import IO;
import List;
import vis::Figure;
import vis::Render;
import vis::KeySym;

public Figure b1 = box(size(150,50), fillColor("lightGray"));
public Figure b0 = pack([box(size(150,50), fillColor("lightGray")), box(size(160,100), fillColor("red"))]);

public Figure mkfig(){
	b1 = box(vshrink(0.5), fillColor("Red"));
	b2 = box(vshrink(0.8),  fillColor("Blue"));
	b3 = box(vshrink(1.0), fillColor("Yellow"));
	return hcat([b1, b2, b3]);
}

public void htmlMain(Figure f){
	println(f);
	render(f);
	println("html -\> <renderToHtml(f)>");
	writeFile(|file:///D:/Data/jpeeters/Desktop/htmlout.html|, htmlWrap(renderToHtml(f)));
}

data Layout = relative() | fixed();

public str htmlWrap(str s) = "\<!DOCTYPE html\>\<html style=\"height:100%;\"\>\<head\>\</head\>\<body style=\"height:100%;\"\><s>\</body\>\</html\>";

// roots
public str renderToHtml(Figure f) 							= renderToHtml(f, relative()); // defaults to relative
public str renderToHtml(_widthDepsHeight(fig,_)) 			= renderToHtml(fig);
public str renderToHtml(_pack(Figures figs,_))				= renderToHtml(figs,fixed());
public str renderToHtml(_grid(list[Figures] figlist, p), l)	= joinl([gridRow(figs, 100/size(figlist), l) | figs <- figlist]);
public str renderToHtml(Figures figs, Layout l)				= renderToHtml(figs, "", l);
public str renderToHtml(Figures figs, str style, Layout l)	= joinl([renderToHtml(fig, style, l) | fig <- figs]);

// grid
private str gridRow(Figures figs, int height, Layout l)		= div(renderToHtml(figs, "float:left; width:<100/size(figs)>%;", l), "height:<height>%;");

// figures
private str renderToHtml(b:_box(_), Layout l) 						= renderToHtml(b, "", l);
private str renderToHtml(_box(FProperties props), style, Layout l) 	= div(joinl([css(props, l), style, "border:1px solid black;"], " "));

// css
private str css(unpack(FProperties props), l) 	= css(props, l);
private str css(FProperties props, Layout l) 	= joinl([css(prop, l) | prop <- props], " ");

// fixed css rules
private str css(hsize(int i), fixed()) 		= "width:<i>px;";
private str css(vsize(int i), fixed()) 		= "height:<i>px;";

// relative css rules
private str css(hsize(int i), relative()) 	= "width:inherit;";
private str css(vsize(int i), relative()) 	= "height:inherit;";

// general css rules
private str css(fillColor(str color), _) 	= "background-color:<color>;";
private str css(vshrink(real i), _) 		= "height:<i*100>%;";


// html element helpers
private str div(str style)						= elem("div", style);
private str div(str val, str style)				= elem("div", val, style);
private str elem(str name, str style)			= elem(name, "&nbsp;", style);
private str elem(str name, str val, str style)	= "\<<name> style=\"<style>\"\><val>\</<name>\>";


private str joinl(list[str] l) = joinl(l, "");
// helper
private str joinl(list[str] l, str on){
	str v = "";
	for(s <- l){
		if(v != "") v += on;
		v += s;
	}
	return v;
}