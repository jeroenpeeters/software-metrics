module lang::Html::Html

import IO;
import String;
import ParseTree;

import lang::Html::Ast;
import lang::Html::Concrete;

	

public Html parse() = implode(#Html, parseHtml(|file:///D:/Data/jpeeters/Documents/GitHub/software-metrics/src/lang/test.xml|));

//public Html parse() = implode(#Html, parseHtml(|file:///D:/ictu/rni-all-src/applicatie/rni-loket/trunk/rni-parent-web/rni-main-web/src/main/webapp/pages/assign-bsn/assign-bsn.page.xml|));
