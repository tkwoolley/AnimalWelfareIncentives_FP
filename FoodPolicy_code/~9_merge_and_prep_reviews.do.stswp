* Project: Factors of Humnane Production
* Author: Sharon R and Trevor W
* Date: May 31, 2024
* Purpose: Append excel sheets from human review 2 and isolate the "home run" papers
*******************************************************************************
global data "D:\Projects\ASPCA\data\double_check\human_abstract_review2"
global findata "D:\Projects\ASPCA\data\"


*******************************************************************************
* Import excel sheets from box and save as dta
*******************************************************************************
	/*
	import excel "C:\Users\sharon.pailler\Box\Sharon  Pailler Home Drive\Trevor consultancy\coding review\human_review2\human_review2_v2_SP_edited.xlsx", sheet("Sheet1") firstrow clear
	save "C:\Users\sharon.pailler\Box\Sharon  Pailler Home Drive\Trevor consultancy\coding review\human_review2\Stata\SP reviewed papers.dta", replace
	import excel "C:\Users\sharon.pailler\Box\Sharon  Pailler Home Drive\Trevor consultancy\coding review\human_review2\human_review2_v2_JL_edited_for_merge.xlsx", sheet("Sheet1") firstrow clear
	save "C:\Users\sharon.pailler\Box\Sharon  Pailler Home Drive\Trevor consultancy\coding review\human_review2\Stata\JL reviewed papers.dta", replace
	import excel "C:\Users\sharon.pailler\Box\Sharon  Pailler Home Drive\Trevor consultancy\coding review\human_review2\human_review2_v2_MS_edited_for_merge.xlsx", sheet("Sheet1") firstrow clear
	save "C:\Users\sharon.pailler\Box\Sharon  Pailler Home Drive\Trevor consultancy\coding review\human_review2\Stata\MS reviewed papers.dta", replace
	import excel "C:\Users\sharon.pailler\Box\Sharon  Pailler Home Drive\Trevor consultancy\coding review\human_review2\human_review2_v2_SR_edited.xlsx", sheet("Sheet1") firstrow clear
	save "C:\Users\sharon.pailler\Box\Sharon  Pailler Home Drive\Trevor consultancy\coding review\human_review2\Stata\SR reviewed papers.dta", replace
	import excel "C:\Users\sharon.pailler\Box\Sharon  Pailler Home Drive\Trevor consultancy\coding review\human_review2\human_review2_v2_ZR_edited.xlsx", sheet("Sheet1") firstrow clear
	save "C:\Users\sharon.pailler\Box\Sharon  Pailler Home Drive\Trevor consultancy\coding review\human_review2\Stata\ZR reviewed papers.dta", replace
	import excel "C:\Users\sharon.pailler\Box\Sharon  Pailler Home Drive\Trevor consultancy\coding review\human_review2\jm_papers_final.xlsx", sheet("Sheet1") firstrow clear
	save "C:\Users\sharon.pailler\Box\Sharon  Pailler Home Drive\Trevor consultancy\coding review\human_review2\Stata\JM reviewed papers.dta", replace
	import excel "${data}\human_review2_v2_TW_edited.xlsx", sheet("Sheet1") firstrow clear
	rename significantP05 significant
	save "${data}\TW_reviewed_papers.dta", replace
*/	
	
	use "${data}\TW_reviewed_papers.dta", clear

	* Append dta files
	append using "${data}\JM reviewed papers.dta"
	append using "${data}\SR reviewed papers.dta"
	append using "${data}\ZR reviewed papers.dta"
	append using "${data}\SP reviewed papers.dta"
	append using "${data}\MS reviewed papers.dta"
	append using "${data}\JL reviewed papers.dta"

	* Drop unnecessary vars
	drop countdown home_run External_Barrier External_Motivator Market_Barrier Market_Motivator Y X W AC AB AA Z

	*******************************************************************************
	* Keep only home runs
*******************************************************************************
	drop if id==.

	drop if not_US!="0" 

	// keep a file of where Dep_Var=="" for Kevin and Jojo to skim to confirm coding and identify lit reviews to use for vaidating our sample of papers
	//might need to reclassify those that do not have dependent variables so as to say xx were excluded becuase xx were guidance documents, xx were lit reviews, xx were chapters, xx were opinion, etc...
	//MS coded some reviews as having dependent variables, which they did, but should remove from analysis if from a lit review and not original research 

	//later review anything dropped to id why it was dropped eg.. if not orig research or not relevant to our categories

	gen todrop = 0
	replace todrop=1 if  Dep_Var=="" // 177 replaced
	replace todrop=1 if  Dep_Var=="NA" // 48 replaced

	replace todrop=1 if Indep_Var =="" // 10 replaced
	replace todrop=1 if  Indep_Var=="NA" // 2 replaced

	replace todrop=1 if Practice =="" // 1 replaced
	replace todrop=1 if  Practice =="NA" // 6 replaced

	replace todrop=1 if Relationship =="" // 18 replaced
	replace todrop=1 if  Relationship =="NA" // 10 replaced

	tab article_type if todrop==0
	//JL left some article type blank where the paper was "abandoned"  drop these
	replace todrop=1 if article_type==""

	// different types of articles mentioned -  book chapter, case study, conference, extension publication, lit review, opinion/perspective, other, overview journal article, peer review, student thesis/dis, teaching material, working paper

	*drop anything that seems like a review - where article_type is conference or extension publication, lit review or overview journal article
	replace todrop=1 if strpos(article_type, "book chapter")
	replace todrop=1 if strpos(article_type, "conference")
	replace todrop=1 if strpos(article_type, "extension publication")
	replace todrop=1 if strpos(article_type, "lit review")
	replace todrop=1 if strpos(article_type, "overview journal article")
	replace todrop=1 if strpos(article_type, "teaching material")
	// Replaced 87 total

	* JM included a "most likely keep" variable.
	replace todrop=1 if MostLikelyKeep == "0"
	// This includes a paper talking about beef cows and a paper where the practice was not an indep or dep variable
	drop MostLikelyKeep

	* Flag whether Practice does not match Dep or Indep variable
	gen pract_indep_exact = 0
	replace pract_indep_exact = 1 if Indep_Var == Practice
	gen pract_dep_exact = 0
	replace pract_dep_exact = 1 if Dep_Var == Practice
	// 421 obs don't have a Practice that exactly matches the indep or dep var...

	*******************************************************************************
	* Export data
*******************************************************************************
	*to review "final" list of papers for consistency coding and categorizing - flagging any issues or questions, etc... 
	export excel using "${data}\paper_list_for_secondary_review.xls" if todrop==0, firstrow(variables) replace
	// In its excel form, I renamed as "post_humanreview2_included_editsTW" and uploaded to Box folder human_review2/post_review_checks

	codebook id if todrop==0
	//130 unique ids

	* to identify the number of those dropped for no dep variable, outside practice scope, etc... 
	export excel using "${data}\papers_excluded_from_secondary_review.xls" if todrop==1, firstrow(variables) replace

	codebook id if todrop==1
	// 134 unique ids dropped (that are US)

	*******************************************************************************
	// I manually (in excel) read through all practices in "paper_list_for_secondary_review.xls" (renamed to human_review2/post_review_checks) to (1) check whether every practice mentioned is within our scope and (2) make sure all species were filled out; (3) double-checked that all practices matched either the indep or dep variable; and (4) changed "dep_var_good_for_prod" to "NA" if the pract is dep var (since that is only meaningful in cases where the pract is the indep var); and (5) flag practices that are hygene related to potentially make that a medium practice category

	// I added four variables: double_check_note_TW (my notes for why I flagged certain papers to drop --based on practice); pract_irrel (an indicator 1 if not a relevant practice); double_check (flag whether the paper needs to be double-checked); and hygene (an indicator 1 if the practice is hygene oriented)
	*******************************************************************************

	*******************************************************************************
	* Create double-checked versions of everyone's papers along with my notes	*******************************************************************************
	* Import data
	 import excel "${data}\post_humanreview2_included_editedTW.xls", sheet("Sheet1") firstrow clear

	* Drop the results I flagged as irrelevant practices
	drop if pract_irrel == 1

	codebook id // 116 unique papers now

*******************************************************************************	
	* Save all in one spot
*******************************************************************************	
	save "${data}\post_humanreview2_included", replace
	
	* sort by least likely to be removed to most likely (pract_is_dep_var; stat sig (reverse sort); dep_var_good_for_prod (reverse); pract_good_for_AW (reverse))
	// Had to sort by hand in excel since Stata won't sythesize sort and gsort
	
	export excel using "${data}\categorization\post_humanreview2_included_factorsZR.xls", firstrow(variables) replace
	
*******************************************************************************
	* Save everyone's flaggeed papers as separate docs
*******************************************************************************
	** JM
	export excel using "${data}\separate_checks\post_humanreview2_included_JM.xls" if reviewer == "JM" & double_check == 1, firstrow(variables) replace

	** SP
	export excel using "${data}\separate_checks\post_humanreview2_included_SP.xls" if reviewer == "SP" & double_check == 1, firstrow(variables) replace

	** SR
	// export excel using "${data}\post_humanreview2_included_SR.xls" if reviewer == "SR" & double_check == 1, firstrow(variables) replace 
	//none for SR!

	** ZR
	export excel using "${data}\separate_checks\post_humanreview2_included_ZR.xls" if reviewer == "ZR" & double_check == 1, firstrow(variables) replace

	** JL
	export excel using "${data}\separate_checks\post_humanreview2_included_JL.xls" if reviewer == "JL" & double_check == 1, firstrow(variables) replace

	// Once everyone has edited their flagged papers, I'll put them back together into one list which will then become the penultimate list. The only that might change would be dropping more results for the sake of consistency (based on consistency survey)--the "secondary review".
	
*******************************************************************************
	* Add double-check edits back into sample
*******************************************************************************
	
	** JM
	import excel  "${data}\separate_checks\post_humanreview2_included_JM_fixed.xlsx", sheet("Sheet1") firstrow clear
	tempfile JM
	save `JM'

	** SP
	import excel  "${data}\separate_checks\post_humanreview2_included_SP_fixed.xls", sheet("Sheet1") firstrow clear
	
	append using `JM', force
	tempfile SP
	save `SP'
	
	** ZR
	import excel  "${data}\separate_checks\post_humanreview2_included_ZR_fixed2.xls" , sheet("Sheet1") firstrow clear
	// "2" bc I dropped the bottom row bc ZR said should not be in final sample
	
	append using `SP', force
	tempfile ZR
	save `ZR'
	
	** JL
	import excel "${data}\separate_checks\post_humanreview2_included_JL_fixed2.xlsx", sheet("Sheet1") firstrow clear
	// "2" bc JL told me to drop the organic-focused results 
	
	append using `ZR', force
	tempfile JL
	save `JL'
	
	** All results
	use "${data}\post_humanreview2_included"
	drop if double_check ==1
	append using `JL', force
	
	drop if id==.
	
	sort id
	
	export excel using "${data}\penultimate_sample_for_review", firstrow(variables) replace
	
*******************************************************************************
	* TW Review of everyone's notes and clean data accordingly
*******************************************************************************
// TW read through everyone's notes to see whether people mentioned whether the result should be included. Before, I had kept all rows that were completely filled out, but some people completely filled out rows that they did not think should be included in our table.
	
	import excel "${data}\penultimate_sample_for_review_TWedited", sheet("Sheet1") firstrow clear

	drop if Toss_BasedOnNotes == 1
	drop if strpos(Dep_good_for_prod, "abandoned")
	drop if strpos(Pract_Category, "NA")
	
	* Drop variables that aren't useful from here on out
	drop todrop Toss_BasedOnNotes pract_indep_exact pract_dep_exact double_check pract_irrel double_check_note_TW
	
	tab article_type
	gen academic = 0
	replace academic = 1 if strpos(article_type, "peer") & !strpos(article_type, "not")
	
	* Make the significant values consistent
	tab significant
	codebook id if significant == "Y" // 83 unique papers
	codebook id if significant != "N" // 104 unique papers
	codebook id // 112 unique papers
	
	replace significant = "Y" if (strpos(significant, "Y") | strpos(significant, "y")) & !strpos(significant, "?")
	replace significant = "Y?" if (strpos(significant, "Y") | strpos(significant, "y")) & strpos(significant, "?")
	replace significant = "N" if (strpos(significant, "N") | strpos(significant, "n")) & !strpos(significant, "?") & !strpos(significant, "NA")
	// SP and JM both have results they would like to double check. These should be double-checked when putting result table together (the results would be partucularly useful). Search for "double" in NOTES variable.
	
	* Make Relationship values consistent
	tab Relationship
	replace Relationship = "pos" if strpos(Relationship, "pos") & !strpos(Relationship, "(") & !strpos(Relationship, "neg")
	replace Relationship = "none" if strpos(Relationship, "pos") & !strpos(Relationship, "(") & strpos(Relationship, "neg")
	replace Relationship = "none" if strpos(Relationship, "equal") |  strpos(Relationship, "0") | strpos(Relationship, "none") | strpos(Relationship, "zero")
	replace Relationship = "neg" if strpos(Relationship, "neg") & !strpos(Relationship, "(") & !strpos(Relationship, "pos")
	
	// Need to have Sharon fix her parentheticals. If it need clarification here, then it needs clarification in the variables. All these have NA significance. So, should they actually have sig = N?
	
	tab Relationship if significant== "NA"
	
	* None of the NA sig should have a "none" relationship. If so, must be accident.
	replace significant = "N" if Relationship == "none"
	
	* How many are pract_is_dep_var == 1?
	tab pract_is_dep_var
	// 696 results are pract_is_dep_var == 0
	// 195 results are pract_is_dep_var == 1
	
	* Make sure pract_good_for_AW is consistent within id Practice
	replace pract_good_for_AW = "Y" if id == 13357 & strpos(Practice, "aviary")
	replace pract_good_for_AW = "N" if id == 20292 & strpos(Practice, "molting")

	* Make sure Pract_Category is consistent within id Practice
	replace Pract_Category = "Enrichment" if id == 19030 & strpos(Practice, "enrichment")
	
	* Make sure hygiene variable is consistent
	replace hygiene = "1" if id == 1876 & strpos(Practice, "Cross-ventilated")
	
	********** Merge with ZR 
	bysort id Dep_Var Indep_Var Practice: gen dup3 = _N
	bysort id Dep_Var Indep_Var Practice: gen dup = _n
	drop if dup==2
	
	tempfile main
	save `main'
	
	import excel "${data}\categorization\post_humanreview2_included_factorsZR_061024.xls", sheet("Sheet1") firstrow clear
		
	bysort id Dep_Var Indep_Var Practice: gen dup3 = _N
	bysort id Dep_Var Indep_Var Practice: gen dup = _n
	drop if dup==2
		
	merge 1:1 id Dep_Var Indep_Var Practice using `main'
	drop if _m==1

*******************************************************************************
	* Clean a little more and export data for "final" sample histograms
*******************************************************************************	
	* Save excel sheet of ? practices and outcomes
	tab pract_good_for_AW
	replace pract_good_for_AW = "?" if strpos(pract_good_for_AW, "?")
	replace pract_good_for_AW = "Y" if strpos(pract_good_for_AW, "Y") |  strpos(pract_good_for_AW, "y")
	replace pract_good_for_AW = "N" if strpos(pract_good_for_AW, "N") 
	
	tab Dep_good_for_prod
	replace Dep_good_for_prod = "?" if strpos(Dep_good_for_prod, "?")
	replace Dep_good_for_prod = "Y" if strpos(Dep_good_for_prod, "Y") |  strpos(Dep_good_for_prod, "y")
	replace Dep_good_for_prod = "N" if strpos(Dep_good_for_prod, "N") |  strpos(Dep_good_for_prod, "n")
	
*******************************************************************************
	* Export Excel Sheets for manual categorizations: (1) Review ? good for; (2) JM make medium practice categories; (3) SP make five freedom categories
*******************************************************************************	
	
	* ? whether practice good for AW
	preserve
		replace pract_good_for_AW = "" if strpos(pract_good_for_AW, "?")
		replace pract_good_for_AW = "1" if strpos(pract_good_for_AW, "Y")
		replace pract_good_for_AW = "0" if strpos(pract_good_for_AW, "N") 
		destring pract_good_for_AW, replace
		
		collapse (mean) pract_good_for_AW (first) Species NOTES, by(Practice id)
		export excel using "${data}\separate_checks\question_checks_goodAW" if pract_good_for_AW == . , firstrow(variables) replace
	restore
	
	* ? whether dep var (outcome) good for producer		
	preserve
		replace Dep_good_for_prod = "" if strpos(Dep_good_for_prod, "?")  | market_factor == "animal wellbeing"
		replace Dep_good_for_prod = "1" if strpos(Dep_good_for_prod, "Y")
		replace Dep_good_for_prod = "0" if strpos(Dep_good_for_prod, "N")
		destring Dep_good_for_prod, replace
		
		collapse (mean) Dep_good_for_prod (first) Species NOTES, by(Dep_Var id)
		export excel using "${data}\separate_checks\question_checks_goodProd" if Dep_good_for_prod == . , firstrow(variables) replace
	restore
	
	* Export excel sheets for JM to categorize practice variables into medium practices and SP to categorize practice variables into Five Freedoms
	// FYI, Because I got ZR market factor categories back after sending the below lists to SR and JM, the lists will be slightly different. Keep this in mind when merging what is above with what is within the following presever/restore
	preserve
		replace pract_good_for_AW = "" if strpos(pract_good_for_AW, "?")
		replace pract_good_for_AW = "1" if strpos(pract_good_for_AW, "Y")
		replace pract_good_for_AW = "0" if strpos(pract_good_for_AW, "N") 
		destring pract_good_for_AW, replace
		
		bysort Practice id: gen N = _N
		collapse (mean) pract_good_for_AW (first) Pract_Category N hygiene, by(Practice id Dep_Var)
		
		bysort Practice id: gen counter = _n
		reshape wide Dep_Var, i(Practice id) j(counter)
				
		order id Practice N pract_good_for_AW Pract_Category Dep_Var*
		sort Practice
			
	// JM: "Right pract cat", "practice at all", and "good for AW?" variables	
	
		export excel using "${data}\categorization\medium_practices_JM" , firstrow(variables) replace
		export excel using "${data}\categorization\five_freedoms_SP" , firstrow(variables) replace
	restore
	
	* Save a Penultimate sample
	// The final sample will not look much different. We may drop some results if ppl can't decide whether a practice is good/bad for AW or an outcome is good/bad for producers, but that is pretty much it at this point.
	save "${findata}\clean_data\final\penultimate_sample"	
	
	*******************************************************************************
	* What to do for Secondary Review
*******************************************************************************
/*

1. Double-check practice categories, add "hygene" as category, and replace most "indoor environment" practices (ventilation, cooling, heating, bedding?, flooring, maneur removal, bathing, cleaning, etc) with "hygene". But if it is about comfort (perches) or expressing natural behaviors (chew toys), then categorize as "enrichments". At the end of the day, the practice categories are what will be in tables; not specific practices. The difference between "hygene" and "biosecurity" is that we simply wanted to avoid "vaccines", "antibiotics", and "feed supplements" as practices because of the difficulty of assigning them as good/bad for AW. But we have been keeping track of other things like manuer removal and ventilation. 
2. Make sure that indep match valence and meaning of the practice (why not exact match?). Even when pract_is_dep_var==1, the dependent variables will likely never exactly match the practice but it should match the valence. I noticed some by MS. Use the pract_indep_exact and pract_dep_exact for this.
3. Categorize the dependent variables (when not practice) into "market factor" categories like cost, price, quantity, quality, market power, health, demand.
4. Make sure that practice is not more than 15 words long (I'm looking at you, JL lol). Try to make it shorter if possible (with same valence, of course).
5. Need to determine valence of practices that are "?" for AW and valence of dep vars that are "?" for farmers. If no valence is obvious for either, drop obs.
6. Need to make sure that reviewers gave the same valence to the same practices

*/

