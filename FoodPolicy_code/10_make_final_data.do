* Project:	Humane Practice Adoption
* Author:	Trevor Woolley
* Date:		03/28/24
* Purpose:	Create final data for primary figures and analysis
******************************************************************************
global homedir "D:\Projects\ASPCA"
global datadir "D:\Projects\ASPCA\data"
global figdir "D:\Projects\ASPCA\figures"

ssc install filelist
	
******************************************************************************
* Merge with categorized data
******************************************************************************
// 	use "${datadir}\clean_data\final\penultimate_sample", clear
//	drop _m
	import excel "D:\Projects\ASPCA\data\clean_data\final\penultimate_sample_SP_TW.xls", sheet("Sheet1") firstrow clear
	drop _merge
	// SP and TW updated the penultimate sample according to poll results (to fill in the places where reviewers had put "?"). There is now a drop_poll_SP_TW variable to determine which observations to drop based on poll results (irrelevnt practices to AW or irrelevnt outcomes to producers).
	
	merge m:1 id using "${datadir}\double_check\post_human_abstract_review\post_human_review_all", force
	keep if _merge==3 
	// only the explanation observations did not merge
	drop _merge practice third_merge second_merge first_merge dup_id dup_100 I AW abstract_100 abstract_2045
	
	* Drop observations that did not pass the poll or consistency check
	drop if drop_poll_SP_TW ==1
	
******************************************************************************
* Clean data
// This is where JM and SP categories will come in handy
******************************************************************************
	* Clean practices (JM medium practices)
	replace Indep_Var = "consumer information" if strpos(Indep_Var, "information") 
	replace Indep_Var = "consumer budget" if strpos(Indep_Var, "budget") 
	replace Indep_Var = "importance to consumer" if strpos(Indep_Var, "importance") 
	
	* Clean market factors (make into dummies)
	gen mf_Profit = 0
	replace mf_Profit = 1 if strpos(market_factor, "profit")
	gen mf_Sales = 0
	replace mf_Sales = 1 if strpos(market_factor, "sale")
	gen mf_Productivity = 0
	replace mf_Productivity = 1 if strpos(market_factor, "producti")
	gen mf_Quality = 0
	replace mf_Quality = 1 if strpos(market_factor, "quality") & !strpos(market_factor, "life")
	gen mf_Price = 0
	replace mf_Price = 1 if strpos(market_factor, "price")
	gen mf_OperationC = 0
	replace mf_OperationC = 1 if strpos(market_factor, "operation")
	gen mf_FixedC = 0
	replace mf_FixedC = 1 if strpos(market_factor, "fixed")
	gen mf_Life = 0
	replace mf_Life = 1 if strpos(market_factor, "life")
	gen mf_Demand = 0
	replace mf_Demand = 1 if strpos(market_factor, "demand")
	gen mf_AnHealth = 0
	replace mf_AnHealth = 1 if strpos(market_factor, "health")
	gen mf_TechEff = 0
	replace mf_TechEff = 1 if strpos(market_factor, "echnical")

******************************************************************************	
	* Somewhat clean market factors
	// Keep in mind that the order of the following commands matters
******************************************************************************	
	* Clean some
	replace market_factor = "productivity" if market_factor == "production"
	replace market_factor = "profit" if market_factor == "profits"
	replace market_factor = "operation cost" if market_factor == "operation costs"
	
	* Remove Animal Wellbeing as a market factors
	replace market_factor = subinstr(market_factor, "animal wellbeing","",.)
	
	* Remove "animal wellbeing" and "(-)" and "(+)"
	replace market_factor = subinstr(market_factor, "(-)","",.)
	replace market_factor = subinstr(market_factor, "(+)","",.)

	replace market_factor = "productivity" if strpos(market_factor, "production")
	
	* Very targeted string cleaning
	replace market_factor = "animal health" if market_factor == "/animal health"
	replace market_factor = "animal health" if market_factor == "animal health/"
	replace market_factor = "operation cost" if market_factor == "/operation cost"
	
	tab market_factor
	
	replace market_factor = "farmer QOL" if strpos(market_factor, "farmer")
	
******************************************************************************	
	* Somewhat clea nPractice Categories
******************************************************************************	
	* Clean some
	replace Pract_Category = "Confinement" if strpos(Pract_Category, "onfinement")
	replace Pract_Category = "Enrichment" if strpos(Pract_Category, "nrichment")
	replace Pract_Category = "Indoor Env" if strpos(Pract_Category, "ndoor") | strpos(Pract_Category, "Ventilation")
	replace Pract_Category = "Mutilation" if strpos(Pract_Category, "utilation")
	replace Pract_Category = "Outdoor Access" if strpos(Pract_Category, "utdoor")
	
******************************************************************************
* Identify motivators and barriers
******************************************************************************
	gen motivator = ""
	replace motivator = market_factor if (Relationship == "pos" & pract_good == "Y" & Dep_good_ == "Y") | (Relationship == "pos" & pract_good == "N" & Dep_good_ == "N") | (Relationship == "neg" & pract_good == "N" & Dep_good_ == "Y") | (Relationship == "neg" & pract_good == "Y" & Dep_good_ == "N") 
	replace motivator = Indep_Var if (Relationship == "pos" & pract_good == "Y" & pract_is_dep =="Y") |  (Relationship == "neg" & pract_good == "N" & pract_is_dep =="Y") 
	gen motivator_dum = 0
	replace motivator_dum = 1 if motivator != ""
	
	gen barrier = ""
	replace barrier = market_factor if (Relationship == "pos" & pract_good == "N" & Dep_good_ == "Y") | (Relationship == "pos" & pract_good == "Y" & Dep_good_ == "N") | (Relationship == "neg" & pract_good == "Y" & Dep_good_ == "Y") | (Relationship == "neg" & pract_good == "N" & Dep_good_ == "N")
	replace barrier = Indep_Var if (Relationship == "pos" & pract_good == "N" & pract_is_dep =="Y") |  (Relationship == "neg" & pract_good == "Y" & pract_is_dep =="Y") 
	gen barrier_dum = 0
	replace barrier_dum = 1 if barrier != ""
	
	tab motivator if pract_is_dep == "N"
	tab barrier if pract_is_dep == "N"
	
	foreach var of varlist mf_* {
		disp "****************** `var' *****************"
		count if `var' == 1 & motivator_dum == 1
		count if `var' == 1 & barrier_dum == 1
	}
	// Op Cost was the only factor with more barriers

******************************************************************************
* Make some dummy vars for collapsing data
// ideally, I'd like broilers and layers to be different, but that isn't possible until people go through the papers by hand
******************************************************************************
	replace Species = "Dairy Cow" if strpos(Species, "ow")
	replace Species = "Dairy Cow" if strpos(Species, "airy")
	replace Species = "Broiler" if strpos(Species, "roiler") | id == 7349
	// TW read through the abstracts of Hen Species and labeled as Layers or Broilers. All but id 7349 was layers
	// 	export excel using "${data}\categorization\Hens_relabel" if Species == "Hens" | Species == "hens", firstrow(variables) replace
	replace Species = "Layer" if strpos(Species, "ayer") | strpos(Species, "en")
	replace Species = "Pig" if strpos(Species, "ig")

	gen about_cows = 0
	replace about_cows = 1 if strpos(Species, "ow")
	gen about_pigs = 0
	replace about_pigs = 1 if strpos(Species, "ig")
	gen about_layers = 0
	replace about_layers = 1 if strpos(Species, "ayer")
	gen about_broilers = 0
	replace about_broilers = 1 if strpos(Species, "roiler")
	// There are still 74 results labeled as "Hens" for Species. Need to correct that! 36 results that are pract_is_dep!="Y" (therefore relevant to the market factor list)
	
	
	gen cat_access = 0
	replace cat_access = 1 if strpos(Pract_Category, "utdoor")
	gen cat_confin = 0
	replace cat_confin = 1 if strpos(Pract_Category, "onfinement")
	gen cat_enrich = 0
	replace cat_enrich = 1 if strpos(Pract_Category, "nrichment")
	gen cat_mutilat = 0
	replace cat_mutilat = 1 if strpos(Pract_Category, "utilation")
	gen cat_indoor_env = 0
	replace cat_indoor_env = 1 if strpos(Pract_Category, "ndoor")
	gen CABI = 0
	replace CABI = 1 if strpos(search_engine, "cab")
	gen EconLit = 0
	replace EconLit = 1 if strpos(search_engine, "el")
	gen WoS = 0
	replace WoS = 1 if strpos(search_engine, "wos")
******************************************************************************
* Make sure that "density" and "lighting" practices are in "Indoor Env" practice category
******************************************************************************
	tab Pract_Category if strpos(Practice, "density")
	// Apparently there are obs categorized into Confinement (13), Enrichment (31), and Indoor Env (14)
	replace Pract_Category = "Indoor Env" if strpos(Practice, "density")
	
	
// 	save "${datadir}\clean_data\final\final_data", replace
//	This one ^ is what we used for the AAEA presentation (before poll_SP_TW check and before reassigning all density practices to Indoor Env)

// 	save "${datadir}\clean_data\final\final_data2", replace
// This one ^ is what we used for the ASPCA report and first Nature draft
	
	* Drop Dep Vars that are practices and not producer outcomes (found when reviewing market factor list in next subsection)
	drop if strpos(Dep_Var, "dairies using") | strpos(Dep_Var, "Smaller space required per pig for eating, drinking, defecation, sleeping") | strpos(Dep_Var, "soaker use") | strpos(Dep_Var, "stocking rate") | strpos(Dep_Var, "administration of antimicrobial drugs") 
	// dropped 8 observations
	
	* Drop Practices that Daisy (ASPCA) says do not belong in any Practice Category 
	drop if strpos(Practice, "number of staff")  |  strpos(Practice, "Validus label") |  strpos(Practice, "herd average dry days") |  strpos(Practice, "herd size") | strpos(Practice, "later weaning") | strpos(Practice, "weaning weight") | strpos(Practice, "soakings") | strpos(Practice, "Milking twice a day (versus less)") | strpos(Practice, "trimming") | strpos(Practice, "automat") | strpos(Practice, "milk parlor platform rotation speed") | strpos(Practice, "winter housing of cows individually within 2 months of calving")	
	// dropped 40 observations (results)
		
		
	* Change some Pract_Category categorizations so that they align with Daisy's edits 
	replace Pract_Category = "Indoor Env" if strpos(Practice, "ross-ventilated") | strpos(Practice, "compost bedded pack barn") | strpos(Practice, "four-row free-stall barns relative to three-row free-stall barns") | strpos(Practice, "four- and six-row free-stall barns relative to two- and three-row free-stall barns") | strpos(Practice, "four-row free-stall barns relative to six-row free-stall barns") | strpos(Practice, "parallel parlor") | strpos(Practice, "free-stall barn with mattress relative to free-stall barn with sand") | strpos(Practice, "free stall with sand (relative to free stall with mattress)") | strpos(Practice, "freestall herd with sand stall relative to freestall herd with mattress stall") | strpos(Practice, "freestall herd with sand stall relative to freestall herd with mattress stall") | strpos(Practice, "Use of large pens to accommodate 100 or more pigs relative to small pens with 25-30 pigs") | strpos(Practice, "Herringbone parlor (compared with stall)") | strpos(Practice, "utomat")
	// made 31 changes

	
	replace Practice = Indep_Var if strpos(Indep_Var, "layer hen housing treatment")
	// Somehow this Practice was "lower stocking density and more amenities" for all these independent variables as if that was the only difference. THerefore, they were classified as INdoor Environment when they should be Confinement. That's annoying.
	
	replace Pract_Category = "Confinement" if strpos(Practice, "layer hen housing treatment") | strpos(Practice, "free stall relative to tie stall") | strpos(Practice, "aviary (vs cage)") | strpos(Practice, "enriched colony (vs cage)")
	// made 31 changes (yes, weird that it's 31 twice)
	
	* Other little edits
	replace Pract_Category = "Confinement" if Practice == "cage free"
	replace Pract_Category = "Outdoor Access" if Practice == "pasture"
	drop if strpos(Practice, "Certified for Animal Welbeing") // Meaningless label by Food Marketing Institute
	drop if strpos(Practice, "Amish") 
	
	drop if strpos(Pract_Category, "Organic")
	
	* Make sure that key variables are consistent
	tab pract_good_for_AW
	drop if pract_good_for_AW == "?"
	
	tab Dep_good_for_producer //make sure there are no "Y?"
	drop if strpos(Dep_good_for_producer, "check") | strpos(Dep_good_for_producer, "?")
	
	tab Relationship	
	replace Relationship = "none" if Relationship =="zero"
	replace Relationship = "pos" if strpos(Relationship, "pos")
	replace Relationship = "neg" if strpos(Relationship, "neg")
	replace Relationship = "none" if strpos(Relationship, "none") | strpos(Relationship, "equal")
	drop if Relationship == "?"
		
	tab significant 
	replace significant = "?" if strpos(significant, "NA")
	replace significant = "Y" if strpos(significant, "Y") | strpos(significant, "y")
	replace significant = "N" if strpos(significant, "N") | strpos(significant, "n")
	replace significant = "NA" if strpos(significant, "?")
	
	* Make string variables properly capitalized
	foreach var of varlist title Species Pract_Category Practice market_factor Dep_Var Indep_Var Data_Source sample_subject {
		replace `var' = strproper(`var')
	}
	
	replace authors = "Bartlett, PC; Miller, GY; Lance, SE; Heider, LE" if strpos(authors, "BARTLETT, PC; MILLER, GY; LANCE, SE; HEIDER, LE")
	replace authors = "Mathews, BW; Sollenberger, LE; Staples, CR" if strpos(authors, "MATHEWS, BW; SOLLENBERGER, LE; STAPLES, CR")
	replace authors = "Mohammed, HO; Carpenter, TE"  if strpos(authors, "MOHAMMED, HO; CARPENTER, TE")
	
	* Consolidate market factors that are sub-categories
	replace market_factor = "price" if market_factor == "demand"
	replace market_factor = "productivity" if market_factor == "technical efficiency"
	
	replace mf_Price = 1 if mf_Demand==1
	replace mf_Productivity=1 if mf_TechEff ==1		 
	
	* Export to excel to double-check categorizations
	order authors title abstract Species Dep_Var Dep_good_for_producer market_factor Indep_Var exogenous_factor Relationship significant pract_good_for_AW pract_is_dep_var Pract_Category
	export excel using "D:\Projects\ASPCA\data\clean_data\final_data3.xlsx", firstrow(variables) replace
	
	
	
	save "${datadir}\clean_data\final\final_data3", replace	

