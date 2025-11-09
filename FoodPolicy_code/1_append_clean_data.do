* Project:	Humane Practice Adoption
* Author:	Trevor Woolley
* Date:		9/3/23
* Purpose:	Append EconLit, Scopus, and CAB search research results (journal article info) and clean
******************************************************************************
global homedir "D:\Projects\ASPCA"
global datadir "D:\Projects\ASPCA\data"
global figdir "D:\Projects\ASPCA\figures"

ssc install filelist
******************************************************************************
*								Append Files
******************************************************************************
* Append EconLit files
******************************************************************************
	import excel "C:\Users\trevor_woolley\Documents\ASPCA\data\EconLit\EL_access_farm.xls", sheet("Export Data") firstrow clear

	gen order_id = _n
	gen search_engine = "EconLit"
	
	save  "${datadir}\clean_data\EL_appended.dta", replace
	
	local files : dir "${datadir}\EconLit" files "*.xls"

	cd "${datadir}\EconLit"

	foreach file in `files' {
		import excel `file', sheet("Export Data") firstrow clear
		
		gen search_terms = "`file'"
		gen order_id = _n
		gen search_engine = "EconLit"
		
		append using "${datadir}\clean_data\EL_appended.dta"

		save  "${datadir}\clean_data\EL_appended.dta", replace
	}
	
	rename * , lower
	
	duplicates drop title abstract, force	
	duplicates drop title authors, force	
	duplicates drop abstract authors, force
	duplicates drop title search_terms, force
	
	// This one has "title", "abstract", "authors", "entrydate" (month year), "language", "pubdate" (month year), "pubtitle" (name of journal), "subjectterms" (e.g. "Micro Analysis of Farm Firms, Farm Households, and Farm Input Markets"), "authoraffiliation", "findacopy" (this is the real link I think), "link" (missing all)
	
	* Separate pubdate
	split pubdate
	replace pubdate2 = pubdate1 if pubdate2 == ""
	replace pubdate2 = pubdate4 if pubdate4 !=""
	replace pubdate1 = pubdate3 if pubdate3 != ""
	
	* Rename vars
	rename pubdate1 pubmonth
	rename pubdate2 pubyear
	rename authoraffiliation affiliations
	rename pubtitle publication
	
	* Reformat documenttype
	replace documenttype = "Journal article" if documenttype == " Journal Article"
	replace documenttype = "Book" if documenttype == " Book"
	replace documenttype = "Collective volume article" if documenttype == " Collective Volume Article"
	replace documenttype = "Dissertation" if documenttype == " Dissertation"
	replace documenttype = "Working paper" if documenttype == " Working Paper"
	
	* Reformat author var to have space after ;
	replace authors = subinstr(authors, ";", "; ",.)
	
	* Save 
	save  "${datadir}\clean_data\EL_appended.dta", replace //41 vars, 536 obs

******************************************************************************
* Append CAB files
*****************************************************************************
	import delimited "C:\Users\trevor_woolley\Documents\ASPCA\data\CAB\CAB_access_farm.csv", clear

	gen order_id = _n
	gen search_engine = "CAB"
	
	save  "${datadir}\clean_data\CAB_appended.dta", replace
	
	local files : dir "${datadir}\CAB" files "*.csv"

	cd "${datadir}\CAB"

	foreach file in `files' {
		import delimited `file', clear
		
		gen search_terms = "`file'"
		gen order_id = _n
		gen search_engine = "CAB"
	
		append using "${datadir}\clean_data\CAB_appended.dta", force

		save  "${datadir}\clean_data\CAB_appended.dta", replace
	}
		
	duplicates drop title abstract, force	
	duplicates drop title authors, force	
	duplicates drop abstract authors, force
	duplicates drop title search_terms, force	
	
	// This one has "title", "authors", "documenttitle" (name of journal), "placeofpublication" (all missing values), "yearofpublication", "locationofpublisher", "countryofpublisher", "languageoftext", "abstracttext", "authoraffiliation", "descriptors" (like keywords?), "geographicallocations", "urls" (seems to be complete)
	
	* Rename variables to match EconLit
	rename documenttitle publication
	rename yearofpublication pubyear
	rename languagesoftext language
	rename abstracttext abstract
	rename authoraffiliations affiliations
	rename itemtype documenttype_CAB

	* Gen documenttype to be same format as EconLit
	// If itemtype has multiple categories, this labels them as one with the following precidence: Journal article, Book chapter, Book, Conference paper, Conference procedings
	gen documenttype = documenttype_CAB
	replace documenttype = "Conference proceedings" if strpos(documenttype_CAB, "Conference proceedings")
	replace documenttype = "Conference paper" if strpos(documenttype_CAB, "Conference paper")
	replace documenttype = "Book" if strpos(documenttype_CAB, "Book")
	replace documenttype = "Book chapter" if strpos(documenttype_CAB, "Book chapter")
	replace documenttype = "Journal article" if strpos(documenttype_CAB, "Journal")
	
	* Append with EconLit articles
	append using "${datadir}\clean_data\EL_appended.dta", force //60 vars, 5,046 obs
	
	* save
	save  "${datadir}\clean_data\EconLit_CAB.dta", replace
		
******************************************************************************
* Append WOS files
******************************************************************************
	import excel "C:\Users\trevor_woolley\Documents\ASPCA\data\WOS\WOS_access_farm.xls", sheet("savedrecs") firstrow clear

	gen order_id = _n
	gen search_engine = "WOS"
	
	save  "${datadir}\clean_data\WOS_appended.dta", replace
	
	local files : dir "${datadir}\WOS" files "*.xls"

	cd "${datadir}\WOS"

	foreach file in `files' {
		import excel `file', sheet("savedrecs") firstrow  clear
		
		gen search_terms = "`file'"
		gen order_id = _n
		gen search_engine = "WOS"
	
		append using "${datadir}\clean_data\WOS_appended.dta", force

		save  "${datadir}\clean_data\WOS_appended.dta", replace
	}
	
	rename * , lower
	rename articletitle title
	
	duplicates drop title abstract, force	
	duplicates drop title authors, force	
	duplicates drop abstract authors, force
	duplicates drop title search_terms, force		
	
	// This one has "authors", "title", "astract", "sourcetitle" (name of journal--all caps), "authorkeywords" (separated by ;), "keywordsplus" (all caps), "fundingorgs" (could search this for country), "woscategories", "researchareas" (good for categorizing fields), "publcationdate", "publicationyear"
	
	* Rename variables to match EconLit_CAB
	rename sourcetitle publication
	rename publicationyear pubyear
	rename documenttype documenttype_WOS
	
	// If itemtype has multiple categories, this labels them as one with the following precidence: Journal article, Book chapter, Book, Conference paper, Conference procedings, Editorial Material, Review
	gen documenttype = documenttype_WOS
	replace documenttype = "Review" if strpos(documenttype_WOS, "Review")
	replace documenttype = "Editorial material" if strpos(documenttype_WOS, "Editorial Material")
	replace documenttype = "Book" if strpos(documenttype_WOS, "Book")
	replace documenttype = "Book chapter" if strpos(documenttype_WOS, "Book Chapter")
	replace documenttype = "Journal article" if strpos(documenttype_WOS, "Article")
	
	* Append all papers (EconLit, CAB, and WOS)
	append using "${datadir}\clean_data\EconLit_CAB.dta", force //116 vars, 11,636 obs
	
	* Some final formatting
	replace publication = strproper(publication)
	replace keywordsplus = strproper(keywordsplus)
	replace publisheraddress = strproper(publisheraddress)
	replace publisher = strupper(publisher)
	
	* Drop irrelevant variables
	drop publicationtype bookauthors bookeditors bookgroupauthors authorfullnames bookauthorfullnames groupauthors bookseriestitle bookseriessubtitle bookdoi earlyaccessdate subtitle foreigntitle editors corporateauthors notes caption v30
	
	save "${datadir}\clean_data\all_appended.dta", replace
	
******************************************************************************
*								SHARON GO HERE
******************************************************************************
// Note to Sharon: If you are interested in publication type, the best variable to look at is "documenttype", which I formatted across all search engines. I decided to keep all types throughout this do file and only dropped abstract-less papers at the very end of this do file. I would like your help deciding how to drop duplicates.

*use "C:\Users\sharon.pailler\Box\Sharon  Pailler Home Drive\Trevor consultancy\data\Stata\all_appended.dta", clear

use "${datadir}\clean_data\all_appended.dta" , clear
	
	* Flag duplicate articles (and figure out how best to drop them)
	***some article titles have a "." at the end so do not get flagged as duplicates so first remove all "."
	***some article titles also have some capitalized letters and others don't so make them all small caps (or same)
	gen simpletitle = strlower(title)
	replace simpletitle = subinstr(simpletitle, ".", "",.) 
	duplicates tag simpletitle, gen(dup_title) 
	***also checked duplicates of title+publications and title+author - the title+author had NO duplicates
	tab dup_title
	***>1000 dups
	sort simpletitle
	
// 	export excel using "C:\Users\sharon.pailler\Box\Sharon  Pailler Home Drive\Trevor consultancy\data\Stata\title duplicates.xls" if dup_title>0, firstrow(variables)

	***used this excel file to check title duplicates and id best ways to drop duplicates
	***some journal names don't match b/c different conference proceedings, some journal names are called "introduction" so would falsely match
	***year is missing and/or could be wrong if 2 different conference proceedings
	***author seems best
	
	***author names may be abbreviated e.g. Haynes, Blake or Haynes, B. and similar all caps issue
	***created a variable with JUST the first author last name
	gen firstauthor=substr(authors,1, strpos(authors, " ") - 1)
	***tried parsing at "," but had too many missing
	replace firstauthor=strlower(firstauthor)
	replace firstauthor = subinstr(firstauthor, ",", "",.) 
	duplicates tag firstauthor, gen(dup_authors)

	
	***to generate variables to keep all the different search engines for each observation
	gen EconLit2=0
	replace EconLit2=1 if search_engine == "EconLit"
	gen WOS2=0
	replace WOS2=1 if search_engine == "WOS"
	gen CAB2=0
	replace CAB2=1 if search_engine == "CAB"
	bys title firstauthor: egen EconLit = max(EconLit2)
	bys title firstauthor: egen CAB = max(CAB2)
	bys title firstauthor: egen WOS = max(WOS2)
	
	
	*recommend dropping duplicates by title and first author name - may lose some information from the other columns (like where abstracts don't match) do we care about this?
	duplicates drop simpletitle firstauthor, force	
	// 582 obs deleted
		
	duplicates tag abstract, gen(dup_abstract)
	tab dup_abstract
	*30 with 1 duplicate, 9192 with 9191 duplicates - these are the missing abstracts
	sort title
	
	*further drop duplicates where titles and abstracts match and where abstracts and authors matched but titles didn't (usually b/c of special characters)
	duplicates drop abstract simpletitle if dup_abstract==1, force
	duplicates drop abstract firstauthor if dup_abstract==1, force
	
	save  "${datadir}\clean_data\all_nodups.dta", replace
	
	export excel using "${datadir}\clean_data\all_nodups.xls", firstrow(variables) replace

******************************************************************************
* what to do with missing abstracts...
	count if abstract==""
	****9192 of 23,476 obs
	tab publication if abstract==""
	***no one journal seems to be the culprit, but there are some that have 100s of articles w/o abstracts
	***perhaps remove all the publications that start with "proceedings"? if these are conference proceedings? 
	***also lots of international journals "Revista..." etc... 
	
	save  "${datadir}\clean_data\all_abstracts.dta", replace
	