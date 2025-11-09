* Project:	Humane Practice Adoption
* Author:	Trevor Woolley
* Date:		12/11/23
* Purpose:	Analyze the Human Abstract Exclusion Review and make set of papers without assigned practice categories (for Trevor and Daisy to assign by hand)
******************************************************************************
global homedir "D:\Projects\ASPCA"
global datadir "D:\Projects\ASPCA\data"
global figdir "D:\Projects\ASPCA\figures"
global jupdir "D:\Projects\ASPCA\code\Jupyter"

ssc install filelist
ssc install asdoc
******************************************************************************
* 				Human Abstract Review for Exclusion 
******************************************************************************
	* Pull in Sharon P 600 (1-603)
	import excel "${datadir}\double_check\human_abstract_review\Abstracts_1_603_SP_TWcheck.xlsx", sheet("Sheet1") firstrow clear
	
	replace keep = 0 if keep !=1
	sum keep 
	tab reason
	sum not_research 
	gen who = "SP"

	count if strpos(reason, "AW but not profit")
	count if strpos(reason, "not AW")
	count if strpos(reason, "breed")
	count if strpos(reason, "pollution")
	count if strpos(reason, "non US")
	count if strpos(reason, "non-related")
	count if strpos(reason, "not animal")
	count if strpos(reason, "health")
	
	drop exclusion_labels inclusion_labels notes TW_check
	
	gen health = 0
	replace health = 1 if strpos(reason, "health")>0
	sum keep if health == 1
	replace keep =1 if health == 1 // 20 abstracts were relabeled as "kept" which would have otherwise not been kept (though they were probably excluded for good reason)
	
	tempfile SP
	save `SP'
	
	* Pull in Jon M 600 (604-1206)
	// Notes: Need to check PreNonAnimalandHealthBiosec == 1 obs because some of those are likely biosecurity/health
	// Need to check biosecurity/health papers bc probably don't want to include them all
	import excel "${datadir}\double_check\human_abstract_review\JM Abstracts_604_1206_first300.xlsx", sheet("Sheet1") firstrow clear
	drop if id ==.
	tempfile jon
	save `jon'

	import excel "${datadir}\double_check\human_abstract_review\JM Abstracts_604_1206_last 300.xlsx", sheet("Sheet1") firstrow clear
	drop if id==.
	merge 1:1 id using `jon'

	sum keep //38.8% (try looking through biosecurity/health ones. Prob not all good)
	tab reason //4% are biosecurity/health
	sum not_research //18.9%
	gen who = "JM"

	count if strpos(reason, "AW but not profit")
	count if strpos(reason, "not AW")
	count if strpos(reason, "breed")
	count if strpos(reason, "pollution")
	count if strpos(reason, "non US")
	count if strpos(reason, "non-related")
	count if strpos(reason, "not animal")
	count if strpos(reason, "health")

	gen health = 0
	replace health = 1 if strpos(reason, "health")>0
	sum keep if health == 1
	
	drop  AWexclude2358 not_researchmostlyinclude PreNonAnimalandHealthBiosec _merge health _merge
	
	append using `SP', force
	
	tempfile JM
	save `JM'
	
	* Pull in Sharon Raszap 600 (1207-1809)
	// Note: First 150 overlap with Monica and should use Monica's bc she was keeping track of health
	import excel "${datadir}\double_check\human_abstract_review\Abstracts_1207_1809_SR.xlsx", sheet("Sheet1") firstrow clear

	sum keep //38.8% (try looking through biosecurity/health ones. Prob not all good)
	tab reason //4% are biosecurity/health
	sum not_research //18.9%
	gen who = "SR"
	
	drop exclusion_labels inclusion_labels I J K L M
	
	gen health = 0
	replace health = 1 if strpos(reason, "health")>0
	sum keep if health == 1
	
	append using `JM'
	
	tempfile SR
	save `SR'
	
	* Pull in Monica 600 (1810-2412)
	// Note: She did not finish reviewing the last 50 of her list. I will need to review these on a later date
	import excel "${datadir}\double_check\human_abstract_review\Abstracts_1810_2412_MS.xlsx", sheet("Sheet1") firstrow clear

	sum keep, d // 36% kept
	tab reason // 6% biosecurity/health; many are likely irrelevant
	sum not_research //
	gen who = "MS"
	
	drop exclusion_labels inclusion_labels
	
	gen health = 0
	replace health = 1 if strpos(reason, "health")>0
	sum keep if health == 1
	
	append using `SR'
	
	tempfile MS
	save `MS'

	* Pull in TW 600 (2413-3017)
	import excel "${datadir}\double_check\human_abstract_review\Abstracts_2413_3017_TW.xlsx", sheet("Sheet1") firstrow clear
	// note that "3017" is a typo, it should be 3117  

	sum keep //38.8% (try looking through biosecurity/health ones. Prob not all good)
	tab reason //4% are biosecurity/health
	sum not_research //18.9%
	gen who = "TW"

	count if strpos(reason, "AW but not profit")
	count if strpos(reason, "not AW")
	count if strpos(reason, "breed")
	count if strpos(reason, "pollution")
	count if strpos(reason, "non US")
	count if strpos(reason, "non-related")
	count if strpos(reason, "not animal")
	count if strpos(reason, "health")

	drop exclusion_labels inclusion_labels
	// Note that I keep the home_run variable so that I can see which LDA category contains those.
	
	gen health = 0
	replace health = 1 if strpos(reason, "health")>0
	sum keep if health == 1
	replace keep =1 if health == 1 // 24 abstracts were relabeled as "kept" which would have otherwise not been kept (though they were probably excluded for good reason)
	
	append using `MS'
	
******************************************************************************
* 				Make dataset of abstracts (LDA Round 3 Abstracts)
******************************************************************************
	gen abstract_2045 = abstract
	recast str2045 abstract_2045, force
	duplicates drop abstract_2045, force
	
	gen abstract_100 = abstract
	recast str100 abstract_100, force
	duplicates tag abstract_100, g(dup_100)
	drop if dup_100==1 & who=="SR" //somehow we got a duplicate abstract!
	
	keep if keep ==1
	
	duplicates tag id, g(dup_id) //no id duplicates
	
	save "${jupdir}\LDA_round3_temp", replace
	
*****************************************************************************
	* Make dataset with important variables: species, search_terms, etc 
	* Only possible with WOS, which excludes about 200 articles at the moment
******************************************************************************
	* Pull in original (categorized) data
	use "${datadir}\clean_data\all_categorized.dta", clear
	
	gen url = urls
	replace url = documenturl if link ==""
	
	keep title authors authorkeywords keywordsplus id abstract doi search_terms documenttype species pub_subject term_category url
	
	rename abstract abstract_2045 
	recast str2045 abstract_2045, force
	duplicates drop abstract_2045, force
	
	gen abstract_100 = abstract
	recast str100 abstract_100, force
	duplicates drop abstract_100, force
	
	save "${datadir}\clean_data\all_categorized_str100", replace
	
	* Merge the list of non-excluded abstracts into the original data (consider merging based on shortened abstract) to make dataset of keywords to put through LDA for categorization
	
	merge 1:1 abstract_2045 using "${jupdir}\LDA_round3_temp"
	drop if _m == 1
	rename _m first_merge
	// 58 papers from human review did not merge for some reason. 
		
	preserve	
		keep if first_merge==2
		drop title term_category authors species
		
		* merge with LDA_abstracts data 
		merge 1:1 abstract_100 using"${datadir}\clean_data\all_categorized_str100"
		// All but 3 merged using abstract_100
		
		keep if _m!=2
		rename _m second_merge
		
		save "${jupdir}\LDA_round3_merge2", replace
	restore	
		
	keep if first_merge==3	
	append using "${jupdir}\LDA_round3_merge2"
		
	// Note: this preseve/restore section cannot be run until the IDs for unmerged papers are found in the LDA_Abstracts dataset
	preserve
		keep if second_merge == 1
		replace id = 16088 if strpos(abstract, "An observational study of growth performance was performed")
		replace id = 10635 if strpos(abstract, "The present study was conducted on 412")
	replace id = 21887 if  strpos(abstract, "The research was carried out in the Solex")
		//I just found these papers myself in the all_categorized dataset
		drop abstract_100
		drop title term_category authors species
		
		* merge with LDA_abstracts data 
		merge 1:1 id using "${datadir}\clean_data\all_categorized_str100"

		keep if _m==3
		rename _m third_merge

		save "${jupdir}\LDA_round3_merge3", replace
	restore
	
	keep if second_merge != 1
	append using "${jupdir}\LDA_round3_merge3"
	
	gen keywords = keywordsplus
	replace keywords = authorkeywords if keywordsplus==""
	
	* Split search_term variable into search engine and practice (search term)
	// Note: If a paper was pulled by two different searches, it should be labeled with two search terms (practices) but I will need to do this later
	replace search_terms=subinstr(search_terms,".xls","",.)
	replace search_terms=subinstr(search_terms,".csv","",.)
	replace search_terms=subinstr(search_terms,"_1000","",.)
	replace search_terms=subinstr(search_terms,"_2000","",.)
	replace search_terms=subinstr(search_terms,"_2255","",.)
	replace search_terms=subinstr(search_terms,"_3000","",.)
	replace search_terms=subinstr(search_terms,"_4000","",.)
	replace search_terms=subinstr(search_terms,"_4200","",.)
	replace search_terms=subinstr(search_terms,"_farm","",.)
	replace search_terms=subinstr(search_terms,"environmental_","",.)
	
	gen search_engine = "wos" if strpos(search_terms,"wos_")
	replace search_engine = "el" if strpos(search_terms,"el_")
	replace search_engine = "cab" if strpos(search_terms,"cab_")

	replace search_terms=subinstr(search_terms,"wos_","",.)
	replace search_terms=subinstr(search_terms,"cab_","",.)
	replace search_terms=subinstr(search_terms,"el_","",.)
	
	tab search_terms
	
	gen practice = search_terms
	replace practice = "teeth_clip" if strpos(practice,"_cut") 
	replace practice = "beak clip" if practice == "teeth_clip" & species == "Hens" // These two articles actually talk about hens
	replace practice = "pasture" if strpos(practice,"_raised")
	replace practice = "farrow_crate" if strpos(practice,"farrow") | strpos(practice,"gestat")
	replace practice = "flooring" if strpos(practice,"floor") | strpos(practice,"gestat")
	replace practice = "cooling" if strpos(practice,"coolling") // I checked and thankfully this was not a typo in the actual search term that I used
	replace practice = "weaning" if strpos(practice,"wean")
	replace practice = "stall" if strpos(practice,"stall")
	// Need to check if the "lot size" cow practice is about a feed lot
	
	tab practice
	
	* Identify papers without an explicit "practice" (to run through LDA)
	gen term_not_practice = 0
	replace term_not_practice = 1 if strpos(practice,"welfare") | strpos(practice,"humane") | strpos(practice,"organic") | strpos(practice,"housing") | strpos(practice,"aviary") | strpos(practice,"enrichment") | strpos(practice,"shelter")
	// should I also include "one health" as an unassigned practice?
	// practices with only one paper might be easier to assign manually than throwing in LDA? (shelter, )
	
	replace practice = "unassigned" if term_not_practice == 1 //120 papers are unassigned a specific practice yet
	
	replace practice = subinstr(practice,"_"," ",.)
	
	replace species = "Cows & Hens & Pigs" if practice == "tie stall" & species == "Hens"
	
	tab reason if term_not_practice == 1
	
	* Change term_category to unassigned if practice is unassigned
	replace term_category = "Unassigned" if term_not_practice == 1
	replace term_category = "Outdoors" if term_category == "Outdoor Access"
	replace term_category = "Outdoors" if practice =="paddock"
	
	
	* Change term_category to "Indoor Environment" for certain practices that used to be categorized under "confinement"
	replace term_category = "Indoor Env" if strpos(practice,"floor") | strpos(practice,"cool") | strpos(practice,"ventilation") | strpos(practice,"light")
	// Add to this things like bedding, stocking density, etc when I get back LDA results
	
	* Generate a second id variable (bc two papers share id for some reason)
	gen id_2 = _n
	replace id = 999 if id_2 == 1104 & id==11193 // This is the one with a duplicate id
	
	* Save dataset for preliminary analysis (for Daisy, Dec 2023)
	save "${datadir}\double_check\post_human_abstract_review\post_human_review_all", replace
	
******************************************************************************
	* Make preliminary figs for Daisy (Dec 2023)
******************************************************************************
// Main takeaways from discussion with Daisy: (a) create 5th category "indoor environment" (b) "organic" and "aviary" do not matter on their own (c) animal outcomes are not themselves "practices" (mastitis, disease, etc)

// To do: (1) Run the unassigned through LDA (by species) (2) identify practices from the LDA (3) Add term categories to these once the practices are identified

	preserve
		collapse (count) id (first) term_category, by(practice species)
		
		separate id, by(term_category) veryshortlabel
		
		foreach s in "Cows" "Hens" "Pigs" {
			graph hbar (asis) id? if species=="`s'", over(practice, sort(id) label(labsize(*.7))) ysize(7) nofill legend(pos(3) col(1)) ///
			title(Practices for `s')
			
			graph export "${figdir}/practices_`s'.png", replace
		}
		// Why are tie stall and teeth_clip in hens practices? IDK but when I check the two abstracts that mention "teeth clip" they both talked about beak trimming so I recoded them accordingly. The tie stall one should be labeled as all species.
		
	restore
	
	
*****************************************************************************
	* Save data for LDA round 3 (and preliminary figs for Daisy)
	// Note: this round is intended to identify practices for the papers that were pulled using a search term that did not involve a practice ("animal welfare", "humane", "housing", "organic")
*****************************************************************************
// 	preserve
// 		keep if term_not_practice == 1 // 171 abstracts
//		
// 		* Save separate files for different species (except for joint categories "Cows & Pigs" and "Cows & Hens & Pigs"--these are so few and would be easier to assign without LDA)
// 		export excel using "${jupdir}\LDA_round3_cows.xls" if species=="Cows", firstrow(variables) replace
// 		save "${jupdir}\LDA_round3_cows", replace
//		
// 		export excel using "${jupdir}\LDA_round3_hens.xls" if species=="Hens", firstrow(variables) replace
// 		save "${jupdir}\LDA_round3_hens", replace
//		
// 		export excel using "${jupdir}\LDA_round3_pigs.xls" if species=="Pigs", firstrow(variables) replace
// 		save "${jupdir}\LDA_round3_pigs", replace
//		
// 		export excel using "${jupdir}\LDA_round3_cowshens.xls" if species=="Cows & Hens", firstrow(variables) replace
// 		save "${jupdir}\LDA_round3_cowshens", replace
//		
// 		export excel using "${jupdir}\LDA_round3_henspigs.xls" if species=="Hens & Pigs", firstrow(variables) replace
// 		save "${jupdir}\LDA_round3_henspigs", replace
// 	restore
	
******************************************************************************
	* Categorizing papers with "unassigned" practices
******************************************************************************
	use "${datadir}\double_check\post_human_abstract_review\post_human_review_all", clear
	keep if term_not_practice ==1
	
	* Search abstracts for search term practices
	gen assigned_practice =""
	local practices `" "automatic" "beak cut" "bedding" "cage free" "cage-free" "cooling" " clip" " cut" "debeak" "dehorn" "density" "disbud" " dock" "dry period" "farrow" "crate" "feedlot" "floor" "free range" "free-range" "gestat" "grassfed" "parlor" "natural light" "nest box" "paddock" "pasture" "perch" "shackle" "tether" "tie stall" "ventilation" "wean" "wire" "'

	foreach x in `practices' {
		replace assigned_practice = "`x'" if strpos(abstract, "`x'")
	}
	// there are definitely papers that were flagged with more than one of these search terms. I'll need to eventually redo this so that every practice has its own dummy.
	
	replace practice = assigned_practice if assigned_practice!=""
	
	* Remove spaces from practice strings
	replace practice = "cut" if practice == " cut"
	replace practice = "dock" if practice == " dock"
	replace practice = "free range" if practice == "free-range"
	replace practice = "cage free" if practice == "cage-free"
	replace practice = "farrow crate" if strpos(practice, "farrow") | strpos(practice, "gestat")
	replace practice = "weaning" if strpos(practice, "wean")
	replace practice = "flooring" if strpos(practice, "floor")
	// Still unsure about whether "wire" papers refer to wire cages or flooring

	* Assign category to these newly assigned practices
	replace term_category = "Enrichment" if strpos(practice, "automatic") | strpos(practice, "parlor") | strpos(practice, "perch") | strpos(practice, "weaning") | strpos(practice, "dry period")
	replace term_category = "Indoor Env" if strpos(practice, "bedding") | strpos(practice, "cooling") | strpos(practice, "density") | strpos(practice, "flooring") | strpos(practice, "ventilation") | strpos(practice, "wire")
	replace term_category = "Mutilation" if strpos(practice, "cut") | strpos(practice, "dehorn") | strpos(practice, "dock")
	replace term_category = "Confinement" if strpos(practice, "crate") | strpos(practice, "cage free") | strpos(practice, "tether") 
	replace term_category = "Outdoors" if strpos(practice, "free range") | strpos(practice, "paddock") | strpos(practice, "pasture") |  strpos(practice, "feedlot")
	
	tab practice if term_category == "Unassigned"
	
	//Are there any papers that still can't be assigned a practice? We'll need to assign these by hand
	
	* Search these abstracts for intentionally EXCLUDED search terms (e.g. "antibiotic")
	gen excluded_term =""
	local excluded_term `" "antibiotic" "biosecurity" "hormon"  "probiotic" "forced molt" "prebiotic" "slow growth" "anesthet" "somatropin" "inseminat" "nutritionist" "deworm" "improvest" "transdermal" "transport" "vehicle" "'
	
	foreach x in `excluded_term' {
		replace excluded_term = "`x'" if strpos(abstract, "`x'")
	}
	tab excluded_term if assigned_practice ==""
	// 62 papers flagged with an excluded term; 46 of which were not also flagged as having an assigned practice
	
	* Remove website links from abstract strings
	rename abstract abstract_messy
	gen abstract = ustrregexra(abstract_messy,"<[^\>]*>","")
	replace abstract = trim(stritrim(abstract))
	
	* save data 
	save "${datadir}\double_check\post_human_abstract_review\post_human_review_newlyassigned", replace
	//This is a dataset of only the papers whose practices were "unassigned" in human_review_all. Now, some of them are assigned.
	
******************************************************************************
	* Make excel sheets for manual review (categorization into practices)
	// The purpose of manual review will be to assign papers a practice and term_category. If no relevant category can be assigned, the paper will be excluded.
******************************************************************************
	* Make some dummy variables
	gen excluded_term_dummy = 0
	replace excluded_term_dummy = 1 if excluded_term!=""
	
	gen organic = 0 
	replace organic = 1 if search_terms == "organic"
	
	* Keep only relevant variables
	keep if practice == "unassigned"
	keep id title abstract 
	
	order id title abstract
		
	* export as two excel sheets with 160 papers each
	save "${datadir}\double_check\post_human_abstract_review\human_review_unassigned", replace
	preserve
		keep if _n <161
		export excel "${datadir}\double_check\post_human_abstract_review\human_review_unassigned_1_160", firstrow(variables) replace
	restore
	preserve
		keep if _n>160
		export excel "${datadir}\double_check\post_human_abstract_review\human_review_unassigned_161_320", firstrow(variables) replace
	restore
	
	
	