module Rni

import String;
import IO;
import List;
import Set;
import lang::java::m3::AST;
import lang::java::jdt::m3::AST;

public alias Declarations = set[Declaration];

public loc main_web 		= |project://rni-main-web/|;
public loc common_web 		= |project://rni-common-web/|;

private loc resources_webapp 	= |file:///home/jepee/Projects/ws-rni-trunk/rni-loket/rni-resources-web/src/main/webapp/|;
private loc main_webapp			= |file:///home/jepee/Projects/ws-rni-trunk/rni-loket/rni-parent-web/rni-main-web/src/main/webapp/|;
private loc main_webapp_java	= |file:///home/jepee/Projects/ws-rni-trunk/rni-loket/rni-parent-web/rni-main-web/src/main/java/|;
	
public set[loc] webapps 		= {resources_webapp, main_webapp};

public loc _sitemapFile 		= |file:///home/jepee/Projects/ws-rni-trunk/rni-loket/rni-parent-web/rni-main-web/src/main/resources/sitemap.xml|;

public set[loc] _indexFiles = {
	_sitemapFile,
	|file:///home/jepee/Projects/ws-rni-trunk/rni-loket/rni-resources-web/src/main/webapp/WEB-INF/custom-tags/batok-taglib.xml|,
	|file:///home/jepee/Projects/ws-rni-trunk/rni-loket/rni-parent-web/rni-main-web/src/main/webapp/pages/demo/index.xhtml|,
	|file:///home/jepee/Projects/ws-rni-trunk/rni-loket/rni-parent-web/rni-main-web/src/main/webapp/WEB-INF/web.xml|,
	|file:///home/jepee/Projects/ws-rni-trunk/rni-loket/rni-parent-web/rni-main-web/src/main/webapp/WEB-INF/pages.xml|,
	|file:///home/jepee/Projects/ws-rni-trunk/rni-loket/rni-parent-web/rni-main-web/src/main/webapp/pages/home/start-screen.xhtml|
};

public loc siteMapFile = |file:///home/jepee/Projects/ws-rni-trunk/rni-loket/rni-parent-web/rni-main-web/src/main/resources/sitemap.xml|;

public set[loc] listXml() = toSet(crawl(toList(webapps), ".xml"));
public set[loc] listPageXml() = toSet(crawl(toList(webapps), ".page.xml"));
public set[loc] listXhtml() = toSet(crawl(toList(webapps), ".xhtml"));
public set[loc] listJava() = toSet(crawl([main_webapp_java], ".java"));

public Declarations mainWebAst() 	= createAstsFromEclipseProject(main_web, false);
public Declarations commonWebAst() 	= createAstsFromEclipseProject(common_web, false);
public Declarations getLoketAst()	= mainWebAst() + commonWebAst();


// Private utils for crawling directories and
// finding files with a specifix suffix
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