* Project:	Humane Practice Adoption
* Author:	Trevor Woolley
* Date:		9/8/23
* Purpose:	Create bar graphs to describe the market factors that are studied in the literature--significant vs. insignificant results (and not by incentive vs disincentive)
******************************************************************************
global homedir "D:\Projects\ASPCA"
global datadir "D:\Projects\ASPCA\data"
global figdir "D:\Projects\ASPCA\figures"

ssc install filelist
ssc install dataex
net install grc1leg, from( http://www.stata.com/users/vwiggins/)
******************************************************************************
* Pull in data
	use "${datadir}\clean_data\final\final_data2", clear	
******************************************************************************

**** Duplicate observations that have two market factors. One gets the one factor and the other gets the other *****************************************
	gen multi_factors = mf_TechEff + mf_AnHealth + mf_Demand + mf_Life + mf_FixedC + mf_OperationC + mf_Price + mf_Quality + mf_Productivity + mf_Sales + mf_Profit
	
	expand 2 if multi_factors == 2 
	
	bysort id Dep_Var Indep_Var Practice : gen n = _n
	bysort id Dep_Var Indep_Var Practice : gen N = _N

	tab market_factor if N==2
	tab market_factor if n==2
	replace market_factor = "quality/productivity" if strpos(market_factor, "quality") & strpos(market_factor, "production")
	replace market_factor = "quality" if strpos(market_factor, "quality") & N == 2 & n == 1
	replace market_factor = "animal health" if strpos(market_factor, "health") & N == 2 & n == 1
	replace market_factor = "productivity" if strpos(market_factor, "producti") & N == 2 & n == 2
	replace market_factor = "operation cost" if strpos(market_factor, "operation cost") & N == 2 & n == 2
	
	tab market_factor if N==2
	tab market_factor if n==1 & N==2
	tab market_factor if n==2
	// Still need to do for the shared animal wellbeing ones to extract the second market factor (or maybe I can just remove that part of the string)
	
	* Remove "animal wellbeing" and any "/"
	replace market_factor = subinstr(market_factor, "/","",.)
	
	tab market_factor
	
	* Consolidate market factors that are sub-categories
	replace market_factor = "price" if market_factor == "demand"
	replace market_factor = "productivity" if market_factor == "technical efficiency"
	
********* Drop results that are not significant or no direction ****************
	gen sig = 0
	replace sig = 1 if strpos(significant, "Y")
	
	gen insig = 0
	replace insig = 1 if strpos(significant, "N")
	
	codebook id if pract_is_dep_var !="Y"
	// 57 unique papers. 310 results
	// The poll + SP + TW only gave us 2 new papers and 10 new results.
	
	drop if pract_is_dep_var =="Y" 
	// Of all the "exogenous_factor" results, only three papers were not consumer preference studies (therefore not easily framable in our study about producer decisions). One studied the prevalence of pasture access under different dairy systems (Parasites and parasite management practices of organic and conventional dairy herds in Minnesota); one studies available pasture access per cow across US regions (Thirty years of organic dairy in the United States: the influences of farms, the market and the organic regulation); and one studies the drivers of cage free practice adoption (Capital Budgeting Analysis of a Vertically Integrated Egg Firm: Conventional and Cage-Free Egg Production). Only the first two were statistical.
	// I think the best thing to do might be to just show these results directly (perhaps reformatted). Table 1 from Sorge et al 2015 and Table 3, 4, & 6 and Fig 3 from Dimitri and Nehring 2022.
	
********************************************************************************
*************** Collapse data (Result id Species level) ************************
********************************************************************************

	// If not collapsing by id first, skip this section
preserve	
	collapse (mean) sig insig, by(market_factor Species id)
	
	count if sig >0 & sig <1
	// 24 paper-factors have mixed results. Some results point one way and other point another way. I'll round them up and down to 1. So if a paper had 2 motivator results and 1 barrier for animal health, that paper is counted as 1 for motivator and 0 for barrier. If there is one for each, then the paper does not count the factor as motivator or barrier. But, papers are still able to be assigned to multiple factors. 
	replace sig = 0 if sig <=.5
	replace sig = 1 if sig >.5 & sig <1
	replace insig = 0 if insig <=.5
	replace insig = 1 if insig >.5 & insig <1

****************** Collapse data (Result Species level) ***********************	
	// If not collapsing by id first (if you just want results, not by papers), you can jump straight here
	
	collapse (sum) sig insig, by(market_factor Species)
	
//  	replace insig = - insig
	foreach s in "Layer" "Broiler" "Dairy Cow" "Pig" {
		if "`s'" == "Dairy Cow" {
			local z = "Cow"
		}
		else local z = "`s'"
		
		gen total_factor_`z' = sig + insig if Species == "`s'"
		gen frac_factor_`z' = sig / total_factor_`z' if Species == "`s'"
	}
	
	* No obs for pigs: profit --> drop
	drop if market_factor == "profit" & Species =="Pig"
	
	* No obs for cows: technical efficiency, ? --> drop
	drop if market_factor == "?" & Species =="Dairy Cow"
	drop if market_factor == "technical efficiency" & Species =="Dairy Cow"
	
	* No obs for layer: profit
	drop if market_factor == "profit" & Species =="Layer"
	
************* Save data separately at results and paper levels *****************
// 	save "${datadir}\clean_data\final\finalsample_sigVinsig_collapsed_results3", replace
	save "${datadir}\clean_data\final\finalsample_sigVinsig_collapsed_papers3", replace
	// 3 means that demand market factor was added to price and technological efficiency into productivity 
restore
********************************************************************************

foreach lvl in "Results" "Papers" {
	if "`lvl'" == "Results" {
		local title = "Significant and Insignificant Results"
		local labels = "0(20)140"
		local ranges = "0 140"
		
		use "${datadir}\clean_data\final\finalsample_sigVinsig_collapsed_results3", clear
	}
	else if "`lvl'" == "Papers" {
		local title = "Is Median Result per Paper Sig. or Insig.?"
		local labels = "0(5)20"
		local ranges = "0 20"
		
		use "${datadir}\clean_data\final\finalsample_sigVinsig_collapsed_papers3", clear
	}
	
	* Make graph for each species
	foreach s in "Layer" "Broiler" "Dairy Cow" "Pig" {
		if "`s'" == "Dairy Cow" {
			local z = "Cow"
		}
		else {
			local z = "`s'"
		}
		
		graph hbar (asis) sig insig if Species=="`s'", over(market_factor, ///
		sort(total_factor_`z') descending) ///
		stack ///
		ytitle("# of `lvl'") ///
		title("`s' Farms", span) ///
		ylabel(`labels') ///
		yscale(range(`ranges')) ///
		legend( rows(1) label(1 "Significant") label(2 "Insignificant")) ///
		bar(1, color(gold)) ///
		bar(2, color(gray)) ///
		graphregion(color(white)) ///
		name(`lvl'_`z', replace)
		
		graph save `lvl'_`z', replace
	
// 		graph export "${figdir}\bar_marketfactor_motivator_finalsample_`z'_results2.png", replace
	}
// 	graph combine papers_Layer.gph papers_Broiler.gph papers_Cow.gph papers_Pig.gph, 
	
	grc1leg `lvl'_Layer `lvl'_Cow `lvl'_Broiler `lvl'_Pig, ///
		title("") ///
		graphregion(color(white)) ///
		iscale(.6) ///
		imargin(1 1 1 1 1) ///
		legendfrom(`lvl'_Layer) pos(bottom)
		
		graph export "${figdir}\bar_marketfactor_sigVinisg_finalsample_combine_`lvl'3b.eps", replace
	
	// I tried to add the fraction of each factor that is an incentive but could not get blabel or dot to work
	
****************** Collapse data (all species combined) ***********************	
	collapse (sum) sig insig, by(market_factor)
	
	gen total_factor = sig + insig
	gen frac_factor = sig / total_factor

	// If doing this for result level, change the ytitle to # of results, title, and file name. If on same y scal: ylabel(-50(25)100) yscale(range(-50 100)).
	graph hbar (asis) sig insig, over(market_factor, ///
	sort(total_factor) descending) ///
	stack ///
	title("`title' (All Species)", span) ///
	ytitle("# of `lvl'") ///
	legend( rows(1) label(1 "Significant") label(2 "Insignificant")) ///
	bar(1, color(gold)) ///
	bar(2, color(gray)) ///
	graphregion(color(white)) ///
	name(`lvl', replace)
	
	graph save `lvl', replace

// 	graph export "${figdir}\bar_marketfactor_motivator_finalsample_papers2.png", replace
}	

	grc1leg	Results Papers, ///
		title("") ///
		graphregion(color(white)) ///
		altshrink ///
		legendfrom(Papers) pos(bottom)
		
	graph export "${figdir}\bar_marketfactor_sigVinsig_finalsample_comnbine3b.eps", replace	
	// "_combine.png" is where both graphs have same y scale. "_combine2.png" is where they are on different scales (to see better detail onn the paper graph)
	// "_combine3.png" is where the demand market factor is merged into price and technological efficiency into productivity
				
		