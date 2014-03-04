module dependency::JsfXhtml

import IO;
import String;
import List;
import Set;
import Map;
import lang::java::m3::AST;
import lang::java::jdt::m3::AST;
import util::ShellExec;

import lang::EL;

import utils::Utils;

import Rni;

public set[str] listDeadPageCodes(){
	set[str] foundPageCodes = {};
	for(loc page <- listXhtml()){
		foundPageCodes += listPageCodes(page);
	}
	return foundPageCodes - listPageCodes(siteMapFile);
}

public set[str] listUnusedPageCodes(){
	set[str] sitemapPageCodes = listPageCodes(siteMapFile);
	for(loc xmlfile <- listXhtml() + listJava()){
		content = readFile(xmlfile);
		for(code <- sitemapPageCodes){
			if( /\"<code>\"/ := content){
				sitemapPageCodes -= {code};
			}
		}
	}
	return sitemapPageCodes;
}

public map[str, set[loc]] listUsedPageCodes(){
	map[str, set[loc]] usedPageCodes = ();
	for(loc page <- listXhtml()){
		for(code <- listPageCodes(page)){
			if( code in usedPageCodes){
				usedPageCodes[code] += {page};
			}else{
				usedPageCodes[code] = {page};
			}
		}
	}
	return usedPageCodes;
}

private set[str] listPageCodes(loc file) =  {code | /pageCode=\"<code:[\w\d]+>\"/ := readFile(file)} + listPageCodesInUiParams(file);
private set[str] listPageCodesInUiParams(loc file) = {code | /name=\"pagecode\"\s+value=\"<code:[\w\d]+>\"/ := readFile(file)};

public void listPagesOnlyReferredBySitemap(){

	map[loc, set[loc]] refMap = listReferencedPages(_indexFiles);
	
	set[loc] siteMapRefs = {file | file <- refMap, refMap[file] ==  {_sitemapFile}};
	
	str html = readFile(_sitemapFile);
	
	set[loc] xhtmls = listXhtml();
	
	for(loc ref <- siteMapRefs){
		str path = substring(ref.path, findLast(ref.path, "/pages"));
		set[str] codes = {pageCode | /pageCode=\"<pageCode:[\w-_]+>\"\s* url=\"<path>\"/ := html};
		if(size(codes) == 0) println("WARNING: NO PAGECODE DETECTED FOR URL <url>");
		
		for(str code <- codes){
			set[loc] foundLocs = search(xhtmls, "\"<code>\"");
			if(foundLocs == {ref}) println("Found: <code> <foundLocs>");
		}
	}
}

public void scanXhtmlReferences(){
	
	println("Total: <size(listAllPages())>, Referenced: <size(listReferencedPages())>");
	set[loc] filesToBeDeleted = listUnreferencedFiles();
	println("ToBeDeleted: <size(filesToBeDeleted)>");
	
	for(f <- filesToBeDeleted){
		println("<f>");
	}
	
	//delete(filesToBeDeleted);
}

public set[loc] listAllPages() = listXhtml();

public set[loc] listUnreferencedFiles() = listXhtml() - keys(listReferencedPages());

public map[loc, set[loc]] listReferencedPages() = listReferencedPages(_indexFiles);

public map[loc, set[loc]] listReferencedPages(set[loc] indexFiles){
	// find all .xhtml pages by crawling
	set[loc] allPages = listAllPages();
	
	// find all referenced pages by crawling the indexFiles
	map[loc, set[loc]] refMap = ();
	for(loc indexFile <- indexFiles){
		// add index file to the map, so they won't get deleted when not referenced
		refMap[indexFile] = {};
		// pass refMap with already referenced files so these will not be scanned again
		refMap = findPageReferences(refMap, indexFile);
	}
	// keys from refMap are all referenced pages
	set[loc] pageRefs = keys(refMap);
	
	// for all referenced pages, find the page.xml files and other xhtml files they reference.
	set[loc] xmlFiles = findPageXmlFiles(pageRefs);
	map[loc, set[loc]] xmlFilesRefMap = findPageReferences(refMap, xmlFiles);
	set[loc] xmlFilesPageRefs = keys(xmlFilesRefMap);
	
	set[loc] previous = pageRefs;
	while(size(xmlFilesPageRefs - previous) > 0){
		//println("New references via page.xml: <size(xmlFilesPageRefs - previous)>");
		
		set[loc] xmlFiles2 = findPageXmlFiles(xmlFilesPageRefs - previous);
		xmlFilesRefMap = findPageReferences(xmlFilesRefMap, xmlFiles2);
		previous = xmlFilesPageRefs;
		xmlFilesPageRefs = keys(xmlFilesRefMap);
	}
	
	//return xmlFilesPageRefs;
	return xmlFilesRefMap;
}

private void delete(set[loc] files){
	for(loc file <- files){
		rm(file);
		println("removed: <file>");
		
		pageXml = getPageXmlForFile(file);
		if(exists(pageXml)){
			rm(pageXml);
			println("removed Page Xml");
		}
	}
}

private PID rm(loc file) = createProcess("/bin/rm", ["<file.file>"], file.parent);

public set[&T] keys(map[&T, &V] m) = toSet([k | k <- m]);

private set[loc] findPageXmlFiles(set[loc] pages){
	set[loc] xmlFiles = {};
	for(page <- pages){
		loc xmlFile = getPageXmlForFile(page);
		if(exists(xmlFile)){
			xmlFiles += xmlFile;
		}
	}
	return xmlFiles;
}

private loc getPageXmlForFile(loc page){
	str xmlFileName = substring(page.file, 0, size(page.file)-size(page.extension)-1) + ".page.xml";
	return  page.parent + xmlFileName;
}

private map[loc, set[loc]] findPageReferences(map[loc, set[loc]] refMap, set[loc] pages) {
	for(page <- pages){
		map[loc, set[loc]] refs = findPageReferences(refMap, page);
		for(k <- refs){
			if( k in refMap){
				refMap[k] += refs[k];
			}else{
				refMap[k] = refs[k];
			}
		}
	}
	return refMap;
}

private map[loc, set[loc]] findPageReferences(map[loc, set[loc]] refMap, loc page) = 
	findPageReferences(refMap, page, true);
	
public map[loc, set[loc]] findPageReferences(map[loc, set[loc]] refMap, loc page, bool recursive){
		str html = readFile(page);
		// match on double quotes
		for(/"<match:((?!").)+\.xhtml>"/ := html){
			refMap += resolvePageReferenceAndAddToMap(refMap, page, match, recursive);
		}
		// match on single quotes
		for(/'<match:((?!').)+\.xhtml>'/ := html){
			refMap += resolvePageReferenceAndAddToMap(refMap, page, match, recursive);
		}
		// match on fishooks
		for(/\><match:[\w\/\-_\d\']+\.xhtml>\</ := html){
			refMap += resolvePageReferenceAndAddToMap(refMap, page, match, recursive);
		}
	return refMap;
}

private map[loc, set[loc]] resolvePageReferenceAndAddToMap(map[loc, set[loc]] refMap, loc page, str match, bool recursive){
	set[loc] resolvedRefs = resolvePageReference(page, match);
	for(p <- resolvedRefs){
		if (p in refMap){
			set[loc] locset = refMap[p];
			locset += page;
			refMap[p] = locset;
		} else {
			refMap += (p : {page});
			if(recursive) refMap += findPageReferences(refMap, p);
		}
	}
	return refMap;
}

private set[loc] search(set[loc] files, str needle) = { file | file <- files, /<needle>/ := readFile(file) };

private set[loc] resolvePageReference(loc page, str el){
	set[loc] pageRefs = {};
	for(pageRef <- evals(el)){
		for(webapp <- webapps){
			loc pageLoc = webapp + pageRef;
			if(startsWith(pageRef, "/loket")){
				pageLoc = webapp + replaceFirst(pageRef, "/loket", "");
			}else if(!startsWith(pageRef, "/")){
				pageLoc = page.parent + "/" +pageRef;
			}
			if( exists(pageLoc) ){
				pageRefs += pageLoc;
			}
		}
	}
	if(size(pageRefs) == 0) println("Error: dead link found <el> in page <page>");
	//if(size(pageRefs)> 1) println("Warning: pageRef <el> exists <size(pageRefs)> times! Set <pageRefs>");
	return pageRefs;
}
