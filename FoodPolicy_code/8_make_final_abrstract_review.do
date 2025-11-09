* Project:	Humane Practice Adoption
* Author:	Trevor Woolley
* Date:		02/05/24
* Purpose:	Make set of articles for final (?) human abstract review (where we assign motivators and barriers to all papers)
******************************************************************************
global homedir "D:\Projects\ASPCA"
global datadir "D:\Projects\ASPCA\data"
global figdir "D:\Projects\ASPCA\figures"


ssc install filelist
ssc install asdoc
***************************************************************************	
	* After manual review of Unassigned (by Trevor and Daisy)
******************************************************************************
	* Import the 320 newly-assigned manually reviewed papers
	import excel "${datadir}\double_check\post_human_abstract_review\human_review_unassigned_1_160_DF" , sheet("Sheet1") firstrow clear
	
	drop categories go_back_read_later M N O P Q R S T U
	
	save "${datadir}\double_check\post_human_abstract_review\human_review_unassigned_1_160_DF_keepers", replace
	
	import excel "${datadir}\double_check\post_human_abstract_review\human_review_unassigned_161_320_TW" , sheet("Sheet1") firstrow clear
	
	drop categories go_back_read_later
	
	save "${datadir}\double_check\post_human_abstract_review\human_review_unassigned_161_320_TW_keepers", replace
	
	append using "${datadir}\double_check\post_human_abstract_review\human_review_unassigned_1_160_DF_keepers", force
	
	* Merge with the previously unassigned batch of articles (which I reassigned via string search in the previous do file)
	merge 1:1 id using "${datadir}\double_check\post_human_abstract_review\post_human_review_newlyassigned"
	rename _m merge_unass
	
	replace category = term_category if category ==""
	drop term_category
	
	* Merge with the full batch of human-reviewed articles
	merge 1:1 id using "${datadir}\double_check\post_human_abstract_review\post_human_review_all"
	
	* Keep only those that were assigned a category
	keep if category != "NA" & category != "nA"
	
	* Rename categories to make more consistent
	replace category = term_category if category ==""
	
	gen Outdoors = 0
	replace Outdoors = 1 if strpos(category, "ccess") | strpos(category, "utdoor")
	gen Confinement = 0
	replace Confinement = 1 if strpos(category, "onfinement")
	gen Indoor_Env = 0 
	replace Indoor_Env = 1 if strpos(category, "ndoor")
	gen Enrichment = 0
	replace Enrichment = 1 if strpos(category, "nrichment")
	gen Mutilation = 0
	replace Mutilation = 1 if strpos(category, "utilation")
	gen Multiple = 0
	replace Multiple = 1 if strpos(category, "all") | strpos(category, "All") | strpos(category, "multiple") | strpos(category, ",")
	
	count if Confinement ==0 & Indoor_Env ==0 & Enrichment ==0 & Mutilation ==0 & Multiple ==0 & Outdoors ==0 // so all articles have at least one category . But note that 60 articles are unassigned a practice. 
	
	gen Category = ""
	foreach x in "Outdoors" "Confinement" "Indoor_Env" "Enrichment" "Mutilation" "Multiple" {
		replace Category = "`x'" if `x' == 1
	}
	
	* Drop non US articles
	drop if not_US == 1 // just 3 for now
	drop if strpos(reason, "not AW") | strpos(reason, "not US")
	drop if strpos(reason, "health but not comparison")
		
	* Dissect reason variable
	// I'm suspicious of articles listed only as biosecurity/health as the reason for inclusion. But as long as the practice itself isn't purely health related, then we'll keep it.
	// I'm also unsure about "technology" as a motivator/barrier.
	// The "comparison" reason means that two different systems are compared. Whether that system is a practice/factor is on the extensive margin (ex_marg ==1).
	
	* Make "Outcome" variable and fill in with some (health, productivity, price, cost, consumer pref, quality)
	gen Outcome = ""
// 	replace Outcome = reason if strpos(reason, "health") | strpos(reason, "cost") | strpos(reason, "productivity") | strpos(reason, "quality") | strpos(reason, "consumer")
//	
// 	* Remove non outcomes (temperature, technology, regulation, comparison) from "Outcome" variable
// 	replace Outcome = subinstr(Outcome, "temperature","", .)
// 	replace Outcome = subinstr(Outcome, "technology","", .)
// 	replace Outcome = subinstr(Outcome, "regulation","", .)
// 	replace Outcome = subinstr(Outcome, "comparison","", .)
// 	replace Outcome = subinstr(Outcome, "location/weather","", .)
// 	replace Outcome = subinstr(Outcome, "weather","", .)
// 	replace Outcome = subinstr(Outcome, "location","", .)
// 	replace Outcome = subinstr(Outcome, " , ","", .)
// 	replace Outcome = subinstr(Outcome, ",,", "", .)

	
	* Make "Ex_Margin" variable and fill with some (temperature, regulation, farm size, contracts, or simply the practice itself)
	gen Ex_Margin = ""
// 	replace Ex_Margin = reason if strpos(reason, "location") | strpos(reason, "weather") 
//	
// 	* Remove outcomes from Ex_Margin variable
// 	replace Ex_Margin = subinstr(Ex_Margin, "price","", .)
// 	replace Ex_Margin = subinstr(Ex_Margin, "costs","", .)
// 	replace Ex_Margin = subinstr(Ex_Margin, "cost","", .)
// 	replace Ex_Margin = subinstr(Ex_Margin, "consumer","", .)
// 	replace Ex_Margin = subinstr(Ex_Margin, "biosecurity/health","", .)
// 	replace Ex_Margin = subinstr(Ex_Margin, "biosecurity","", .)
// 	replace Ex_Margin = subinstr(Ex_Margin, "health","", .)
// 	replace Ex_Margin = subinstr(Ex_Margin, "health","", .)
// 	replace Ex_Margin = subinstr(Ex_Margin, "productivity","", .)
// 	replace Ex_Margin = subinstr(Ex_Margin, "production","", .)
// 	replace Ex_Margin = subinstr(Ex_Margin, "quality","", .)
// 	replace Ex_Margin = subinstr(Ex_Margin, "comparison","", .)
// 	replace Ex_Margin = subinstr(Outcome, " , ","", .)
// 	replace Ex_Margin = subinstr(Outcome, ",,", "", .)

	* Generate other important variables for this final abstract review
	gen Market_Motivator = ""
	gen Market_Barrier = ""
	gen External_Motivator = ""
	gen External_Barrier = ""
	gen Data_Source = ""
	
	* Replace meaningless practices (all, multiple, general) with ""
	replace practice = "" if practice == "all" | practice == "all " | practice == "All" | strpos(practice, "multiple") | strpos(practice, "general")
	
	* Replace species of multiple species with "" (because I am uncertain about the accuracy)
	replace species = "" if strpos(species, "&")
	
	* Keep only relevant variables
	rename Category Pract_Category
	rename species Species
	rename not_animal not_AW
	rename practice Practice
	rename ex_marg Ex_Score // "ex_margin" (lower case) is what Daisy and I called the score we gave to judge whether the article studied the practice on the extensive margin. Now I'm calling it Ex_Score
	
	keep id url doi authors title abstract Species Practice Pract_Category Outcome Ex_Margin Ex_Score Market_Motivator Market_Barrier External_Motivator External_Barrier Data_Source home_run not_AW not_US
	
	order id url doi authors title abstract Species Practice Pract_Category Outcome Ex_Margin Ex_Score Market_Motivator Market_Barrier External_Motivator External_Barrier Data_Source home_run not_AW not_US
	// The only thing I am unsure of atm is whether market motivators/barries have to be an outcome. For instance, many of the "reasons" given in the previous abstract read-through were not necessarily outcomes tested for in the abstracts themselves. I think this time I do want all market motivators/barries to be outcomes from the paper. That way we aren't drawing inferences that weren't actually results of the papers.
	// The inclusion criteria will be that the paper must (1) Study a practice that can be categorized into one of our 5 practice categories; (2) Study an outcome that producers care about; (3) Study that outcome on some degree of an extensive margin. Most of the time, that margin will probably be the practice itself (e.g. cage-free v. caged housing), but not always. It could also study outcomes of the same humane practice (e.g. pasture raised layers) in two  different settings (e.g. unregulated v. regulated state, hot v. cold climate, large farm v. small farm). 
	// The most important part of this step is documenting the motivators/barriers discussed in the paper. These come in two flavors depending on what you fill out in the Ex_Margin cell. If the Extensive Margin studied in the paper is the practice itself, then simply fill the "Market Motivator" or "Market Barrier" cell with the outcome studied (e.g. lameness, avian flu, consumer preferences, installation cost, etc). If the Extensive Margin is something other than the practice itself (climate, contracts, farm size, farmer age, regulation, etc.), then fill in the "External Motivator" or "External Barrier" cell with that something. 
 	
	* Randomize article order
	set seed 12345
	gen double rnd = runiform()
	sort rnd
	drop rnd
	
	save "${datadir}\double_check\human_abstract_review2\human_review2_all", replace
	
	* Make into 5 separate excel sheets to disseminate (839/5 = 167 papers each)	
	preserve
		keep if _n <168
		export excel "${datadir}\double_check\human_abstract_review2\human_review2_1_167", firstrow(variables) replace
	restore
	preserve
		keep if _n>167 & _n < 335
		export excel "${datadir}\double_check\human_abstract_review2\human_review2_168_334", firstrow(variables) replace
	restore
	preserve
		keep if _n>334 & _n < 502
		export excel "${datadir}\double_check\human_abstract_review2\human_review2_335_501", firstrow(variables) replace
	restore
	preserve
		keep if _n>501 & _n < 669
		export excel "${datadir}\double_check\human_abstract_review2\human_review2_502_668", firstrow(variables) replace
	restore
	preserve
		keep if _n>668
		export excel "${datadir}\double_check\human_abstract_review2\human_review2_669_839", firstrow(variables) replace
	restore
	
*******************************************************************************	
	* Merge with original data to get author affiliations
*******************************************************************************
use "${datadir}\clean_data\all_nodups.dta", clear
	
	gen url = urls
	replace url = documenturl if link ==""
	
	keep affiliations title authors authorkeywords keywordsplus id abstract doi search_terms documenttype url
	
	rename abstract abstract_2045 
	recast str2045 abstract_2045, force
	
	gen abstract_100 = abstract
	recast str100 abstract_100, force
	
	rename title title_2045 
	recast str2045 title_2045, force
	
	gen title_100 = title
	recast str100 title_100, force
	
	rename authors authors_2045 
	recast str2045 authors_2045, force
	
	gen authors_100 = authors
	recast str100 authors_100, force
	
	
	preserve
		keep if abstract_100==""
		save "${datadir}\clean_data\noabstract_nodups_str100", replace
	restore
	
	duplicates drop abstract_2045, force
	duplicates drop abstract_100, force
	
	save "${datadir}\clean_data\all_nodups_str100", replace
	

use "${datadir}\double_check\human_abstract_review2\human_review2_all", clear

	rename abstract abstract_2045 
	recast str2045 abstract_2045, force
	duplicates drop abstract_2045, force
	
	gen abstract_100 = abstract
	recast str100 abstract_100, force
	duplicates drop abstract_100, force
	
	merge 1:1 abstract_2045 using "${datadir}\clean_data\all_nodups_str100"
	drop if _m == 2
	rename _m first_merge
	// 88 papers from human review did not merge for whatever reason. 
		
	preserve	
		keep if first_merge==1
		drop title authors
		
		* merge with LDA_abstracts data 
		merge 1:1 abstract_100 using"${datadir}\clean_data\all_nodups_str100"
		// All but 4 merged using abstract_100
		
		keep if _m!=2
		rename _m second_merge
		
		save "${datadir}\merge_affiliation", replace
	restore	
		
	keep if first_merge==3	
	append using "${datadir}\merge_affiliation"
		
	// Since nodup data does not have id, cannot merge 4 papers with affiliations but that isn't a big deal
	
	save "${datadir}\double_check\human_abstract_review2\human_review2_all_v2", replace
	export excel using "${datadir}\double_check\human_abstract_review2\human_review2_all_v2", firstrow(variables) replace
	
*******************************************************************************	
	* I then removed all papers whose authors were not affiliated with any US institution (if they had a non-missing affiliations variable). This produced human_review2_all_v2_edited 
	// Number of papers went from 837 to 399
	// Among those papers with missing affiliations (191) may be some non-US ones
*******************************************************************************		
	import excel "${datadir}\double_check\human_abstract_review2\human_review2_all_v2_edited.xlsx", sheet("Sheet1") firstrow clear
	
	keep id
	
	save "${datadir}\double_check\human_abstract_review2\human_review2_v2_edited_id", replace
	
*******************************************************************************	
	* Merge with what people have already done
*******************************************************************************	
	preserve
		import excel "${datadir}\double_check\human_abstract_review2\human_review2_1_167_SP_edited", sheet("Sheet1") firstrow clear
		destring id, replace force
		merge m:1 id using "${datadir}\double_check\human_abstract_review2\human_review2_v2_edited_id"
		// 86 matches
		keep if _m ==3 | id==.
		export excel using  "${datadir}\double_check\human_abstract_review2\human_review2_v2_SP", firstrow(variables) replace
	restore
	
	preserve
		import excel "${datadir}\double_check\human_abstract_review2\human_review2_168_334_MS_edited", sheet("Sheet1") firstrow clear
		destring id, replace force
		merge m:1 id using "${datadir}\double_check\human_abstract_review2\human_review2_v2_edited_id"
		// 85 matches
		keep if _m ==3 | id==.
		export excel using  "${datadir}\double_check\human_abstract_review2\human_review2_v2_MS", firstrow(variables) replace	
	restore
		
	preserve		
		import excel "${datadir}\double_check\human_abstract_review2\human_review2_335_501_SR_edited", sheet("Sheet1") firstrow clear
		destring id, replace force
		merge m:1 id using "${datadir}\double_check\human_abstract_review2\human_review2_v2_edited_id"
		// 67 matches
		keep if _m ==3 | id==.
		export excel using  "${datadir}\double_check\human_abstract_review2\human_review2_v2_SR", firstrow(variables) replace
	restore
	
	preserve		
		import excel "${datadir}\double_check\human_abstract_review2\human_review2_502_668_JM_edited", sheet("Sheet1") firstrow clear
		destring id, replace force		
		merge m:1 id using "${datadir}\double_check\human_abstract_review2\human_review2_v2_edited_id"	
		// 77 matches
		keep if _m ==3 | id==.
		export excel using  "${datadir}\double_check\human_abstract_review2\human_review2_v2_JM", firstrow(variables) replace
	restore
	
	preserve		
		import excel "${datadir}\double_check\human_abstract_review2\human_review2_669_839_TW_edited", sheet("Sheet1") firstrow clear
		destring id, replace force		
		merge m:1 id using "${datadir}\double_check\human_abstract_review2\human_review2_v2_edited_id"	
		// 91 matches
		keep if _m ==3 | id==.
		export excel using  "${datadir}\double_check\human_abstract_review2\human_review2_v2_TW", firstrow(variables) replace
	restore

******************************************************************************
	* Merge affiliations with non-abstract papers
	// Just checking whether this could be a way to shrink the sample
	// It is not useful. We will need to ignore papers without abstracts
******************************************************************************	
import excel "D:\Projects\ASPCA\code\Jupyter\LDA_NoAbstract.xls", sheet("Sheet1") firstrow clear

	rename title title_2045 
	recast str2045 title_2045, force
	duplicates drop title_2045, force
	
	gen title_100 = title
	recast str100 title_100, force
	duplicates drop title_100, force
	
	rename authors authors_2045 
	recast str2045 authors_2045, force
	duplicates drop authors_2045, force
	
	gen authors_100 = authors
	recast str100 authors_100, force
	duplicates drop authors_100, force
	
	merge 1:1 title_2045 authors_2045 using "${datadir}\clean_data\noabstract_nodups_str100"
	rename _m first_merge
	// all merged
		
	keep if first_merge==3	
	append using "${datadir}\merge_noabstract_affiliation"
	
	count if affiliations !=""
	// Only 187 of these papers have any affiliations at all
	// There is no reasonable way to shrink the number of these papers (LDA wont work on titles and combing through by hand would be too burdensome)

	
******************************************************************************
	// The purpose of this final review is to
	// 1) Assign all articles to a species and practice(s)
	// 2) Make sure that the practice is relevant to one of our categories ("label" is itself a practice and would usually be in the "multiple" category)
	// 3) Document the "producer outcome(s)" studied (productivity, product quality, taste, health, disease, price, cost, adoption)
	// 4) Document the degree to which the paper studies outcomes on an "extensive margin" (either good v. bad practice or good v. good practice on farms that differ across some other dimension) 0, 1, or ? (if you don't know and don't have journal permissions)
	// 5) Document what the extensive (AKA comparison) dimension is (practice, temperature, regulation, farm size)
	// 6) Document which outcomes (other than adoption) are market motivators or market barriers, AND which margins (other than practice) are external motivators or external barriers.
	// 7) Document the data source (ARMS, opinion, survey, meta-analysis)
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	

















