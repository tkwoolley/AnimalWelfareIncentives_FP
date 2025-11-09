* Project:	Humane Practice Adoption
* Author:	Trevor Woolley
* Date:		9/8/23
* Purpose:	Create bar graphs to describe the market factors that are incentives and disincentives to adopting humane practices. THESE graphs are done separately for each practice category, whereas those (for market factors) in 5_bar_graphs_finalsample are not separated by practice category.
******************************************************************************
global homedir "D:\Projects\ASPCA"
global datadir "D:\Projects\ASPCA\data"
global figdir "D:\Projects\ASPCA\figures"

ssc install filelist
ssc install dataex
net install grc1leg, from( http://www.stata.com/users/vwiggins/)
graph set window fontface "Times New Roman"
graph set eps fontface "Times New Roman"
******************************************************************************
* Pull in data
	use "${datadir}\clean_data\final\final_data4", clear
	// graphs using final_data3 have suffix 4.eps
******************************************************************************

**** Assign only market_factor == "Animal Health" to the 10 results that are "Animal Health" slash something else
// Odd that final_data4 has fewer observations assigned to two or more market factors.  
	
	replace market_factor = "Animal Health" if strpos(market_factor, "Animal Health")
	
	drop if strpos(market_factor, "Environment")
	drop if strpos(Pract_Cat, "Organic")
	drop if strpos(Alt_Category, "Weaning") // 18 results (1 paper) dropped
	
	// I like the idea of separating out "Stocking Density" from "Indoor Environment" bc, at least for cows, it is often outdoor. 
	
	replace Alt_Category = Pract_Cat if Alt_Category != "Density"
	
********* Drop results that are not significant or no direction ****************
	drop if motivator_dum ==0 & barrier_dum == 0 //82 obs dropped
	keep if strpos(significant, "Y") //197 obs dropped
	
	codebook id if pract_is_dep_var !="Y"
	// 53 unique papers. 362 results. (Down from 101 unique papers and 794 results, among which 661 results have a sign amongst 89 unique papers in final_data.)
	// The poll + SP + TW only gave us 2 new papers and 10 new results.
	
	drop if pract_is_dep_var =="Y"  //101 obs dropped
	// Of all the "exogenous_factor" results, only three papers were not consumer preference studies (therefore not easily framable in our study about producer decisions). One studied the prevalence of pasture access under different dairy systems (Parasites and parasite management practices of organic and conventional dairy herds in Minnesota); one studies available pasture access per cow across US regions (Thirty years of organic dairy in the United States: the influences of farms, the market and the organic regulation); and one studies the drivers of cage free practice adoption (Capital Budgeting Analysis of a Vertically Integrated Egg Firm: Conventional and Cage-Free Egg Production). Only the first two were statistical.
	// I think the best thing to do might be to just show these results directly (perhaps reformatted). Table 1 from Sorge et al 2015 and Table 3, 4, & 6 and Fig 3 from Dimitri and Nehring 2022.
	
*******************************************************************************
*************** Collapse data (Result id Species/Industry level) *******************************************************************************

	// If not collapsing by id (paper) first, skip this section
preserve	
	collapse (mean) motivator_dum barrier_dum, by(market_factor Species id)
	
	count if motivator_dum >0 & motivator_dum <1
	// 24 paper-factors have mixed results. Some results point one way and other point another way. I'll round them up and down to 1. So if a paper had 2 motivator results and 1 barrier for animal health, that paper is counted as 1 for motivator and 0 for barrier. If there is one for each, then the paper does not count the factor as motivator or barrier. But, papers are still able to be assigned to multiple factors. 
	replace motivator_dum = 0 if motivator_dum <=.5
	replace motivator_dum = 1 if motivator_dum >.5 & motivator_dum <1
	replace barrier_dum = 0 if barrier_dum <=.5
	replace barrier_dum = 1 if barrier_dum >.5 & barrier_dum <1

****************** Collapse data (Result-Species level) ***********************	
	// If not collapsing by id first (if you just want results, not by papers), you can jump straight here
	
	collapse (sum) motivator_dum barrier_dum, by(market_factor Species)
	
	replace barrier_dum = - barrier_dum
	foreach s in "Layer" "Broiler" "Dairy Cow" "Hog" {
		if "`s'" == "Dairy Cow" {
			local z = "Cow"
			local s2 = "Dairy Cow"
		}
		else if "`s'" == "Hog" {
			local z = "Hog"
			local s2 = "Pig"
		}
		else {
			local z = "`s'"
			local s2 = "`s'"
		}
		
		gen total_factor_`z' = motivator_dum + barrier_dum if Species == "`s2'"
		gen frac_factor_`z' = motivator_dum / total_factor_`z' if Species == "`s2'"
	}
	
	* No obs for hogs: profit --> drop
	drop if market_factor == "profit" & Species =="Hog"
	
	* No obs for cows: technical efficiency, ? --> drop
	drop if market_factor == "?" & Species =="Dairy Cow"
	drop if market_factor == "technical efficiency" & Species =="Dairy Cow"
	
	* No obs for layer: profit
	drop if market_factor == "profit" & Species =="Layer"
	
	* Capitalize market factors
	replace market_factor = "Animal health" if market_factor == "animal health"
	replace market_factor = "Productivity" if market_factor == "productivity"
	replace market_factor = "Price" if market_factor == "price"
	replace market_factor = "Quality" if market_factor == "quality"
	replace market_factor = "Profit" if market_factor == "profit"
	replace market_factor = "Fixed cost" if market_factor == "fixed cost"
	replace market_factor = "Farmer QOL" if market_factor == "farmer QOL"
	replace market_factor = "Sales" if market_factor == "sales"
	replace market_factor = "Operation cost" if market_factor == "operation cost"
	
************* Save data separately at results and paper levels *****************
// 	save "${datadir}\clean_data\final\finalsample_sig_collapsed_results4", replace
	save "${datadir}\clean_data\final\finalsample_sig_collapsed_papers4", replace
restore
	// 3 means that I consolodated "demand" market factor into price and technical efficiency into productivity
	// 4 means that I did some manually editing to make the categories more consistent (in addition to 3)
********************************************************************************

preserve
foreach lvl in "Results" "Papers" {
	if "`lvl'" == "Results" {
		local title = "Significant Results"
		local labels = "-20(10)40"
		local ranges = "-25 40"
		
		use "${datadir}\clean_data\final\finalsample_sig_collapsed_results4", clear
	}
	else if "`lvl'" == "Papers" {
		local title = "Median Sig. Result per Paper"
		local labels = "-4(2)10"
		local ranges = "-4 10"
		
		use "${datadir}\clean_data\final\finalsample_sig_collapsed_papers4", clear
	}
	
	* Make graph for each species
	foreach s in "Layer" "Broiler" "Dairy Cow" "Hog" {
		if "`s'" == "Dairy Cow" {
			local z = "Cow"
			local s2 = "Dairy Cow"
		}
		else if "`s'" == "Hog" {
			local z = "Hog"
			local s2 = "Pig"
		}
		else {
			local z = "`s'"
			local s2 = "`s'"
		}
		
		graph hbar (asis) motivator_dum barrier_dum if strpos(Species, "`s2'"), over(market_factor, ///
		sort(total_factor_`z') descending) ///
		stack ///
		ytitle("# of `lvl'") ///
		title("`s' Farms", span) ///
		ylabel(`labels') ///
		yscale(range(`ranges')) ///
		legend( rows(1) label(1 "Incentive") label(2 "Disincentive")) ///
		graphregion(color(white)) ///
		name(`lvl'_`z', replace)
		
		graph save `lvl'_`z', replace
	
// 		graph export "${figdir}\bar_marketfactor_motivator_finalsample_`z'_results2.png", replace
	}
// 	graph combine papers_Layer.gph papers_Broiler.gph papers_Cow.gph papers_Hog.gph, 
	
	grc1leg `lvl'_Layer `lvl'_Cow `lvl'_Broiler `lvl'_Hog, ///
		title("") ///
		graphregion(color(white)) ///
		iscale(.6) ///
		imargin(1 1 1 1 1) ///
		legendfrom(`lvl'_Layer) pos(bottom)
		
		graph export "${figdir}\bar_marketfactor_motivator_finalsample_combine_`lvl'4.eps", replace
	
	// I tried to add the fraction of each factor that is an incentive but could not get blabel or dot to work
	
****************** Collapse data (all species combined) ***********************	
	collapse (sum) motivator_dum barrier_dum, by(market_factor)
	
	gen total_factor = motivator_dum + barrier_dum
	gen frac_factor = motivator_dum / total_factor

	// If doing this for result level, change the ytitle to # of results, title, and file name. If on same y scal: ylabel(-50(25)100) yscale(range(-50 100)).
	graph hbar (asis) motivator_dum barrier_dum, over(market_factor, ///
	sort(total_factor) descending) ///
	stack ///
	title("`title'", span) ///
	ytitle("# of `lvl'") ///
	legend( rows(1) label(1 "Incentive") label(2 "Disincentive")) ///
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
		
	graph export "${figdir}\bar_marketfactor_motivator_finalsample_comnbine4.eps", replace	
	// "_combine.png" is where both graphs have same y scale. "_combine2.png" is where they are on different scales (to see better detail onn the paper graph)
restore				
		
*******************************************************************************	
********************************************************************************

* Now repeat but for all five practice categories

********************************************************************************
********************************************************************************



********** Collapse data (Result id Species pract category level) **************
	// If not collapsing by id first (if you want result-level obs), skip this section
preserve	
	collapse (mean) motivator_dum barrier_dum, by(market_factor Species Pract_Cat id)
	
	count if motivator_dum >0 & motivator_dum <1
	// 24 paper-factors have mixed results. Some results point one way and other point another way. I'll round them up and down to 1. So if a paper had 2 motivator results and 1 barrier for animal health, that paper is counted as 1 for motivator and 0 for barrier. If there is one for each, then the paper does not count the factor as motivator or barrier. But, papers are still able to be assigned to multiple factors. 
	replace motivator_dum = 0 if motivator_dum <=.5
	replace motivator_dum = 1 if motivator_dum >.5 & motivator_dum <1
	replace barrier_dum = 0 if barrier_dum <=.5
	replace barrier_dum = 1 if barrier_dum >.5 & barrier_dum <1

****************** Collapse data (Result Species level) ***********************	
	// If not collapsing by id first (if you just want results, not by papers), you can jump straight here
	
	collapse (sum) motivator_dum barrier_dum, by(market_factor Species Pract_Cat)
	
	replace barrier_dum = - barrier_dum
	foreach s in "Layer" "Broiler" "Dairy Cow" "Hog" {
		if "`s'" == "Dairy Cow" {
			local z = "Cow"
			local s2 = "Dairy Cow"
		}
		else if "`s'" == "Hog" {
			local z = "Hog"
			local s2 = "Pig"
		}
		else {
			local z = "`s'"
			local s2 = "`s'"
		}
		
		gen total_factor_`z' = motivator_dum + barrier_dum if Species == "`s2'"
		gen frac_factor_`z' = motivator_dum / total_factor_`z' if Species == "`s2'"
	}
	
	* Fill in the gaps. There should be an observation for every market factor x Species x Pract_Cat even if that means motivator == 0
	// Still working on this v
	
	** No obs for hogs: profit --> drop
// 	replace motivator_dum = 0 if market_factor == "profit" & Species =="Hog"
// 	replace barrier_dum = 0 if market_factor == "profit" & Species =="Hog"
	
// 	expand 2 if market_factor == "profit" & Species =="Hog"
	
	* No obs for cows: technical efficiency, ? --> drop
	drop if market_factor == "?" & Species =="Dairy Cow"
	drop if market_factor == "technical efficiency" & Species =="Dairy Cow"

	
	* Capitalize market factors
	replace market_factor = "Animal health" if market_factor == "animal health"
	replace market_factor = "Productivity" if market_factor == "productivity"
	replace market_factor = "Price" if market_factor == "price"
	replace market_factor = "Quality" if market_factor == "quality"
	replace market_factor = "Profit" if market_factor == "profit"
	replace market_factor = "Fixed cost" if market_factor == "fixed cost"
	replace market_factor = "Farmer QOL" if market_factor == "farmer QOL"
	replace market_factor = "Revenue" if market_factor == "revenue"
	replace market_factor = "Operation cost" if market_factor == "operation cost"
	
************* Save data separately at results and paper levels *****************
// 	save "${datadir}\clean_data\final\finalsample_sig_collapsed_cat_results4", replace
	save "${datadir}\clean_data\final\finalsample_sig_collapsed_cat_papers4", replace

restore
********************************************************************************
// The following code gets super complicated only bc some practice categories are missing for some species. Seems like I really should create market factors and practice categories for every species and just make the count 0.

foreach industry in "Cow" "Broiler" "Layer" "Hog" {
foreach cat in "Confinement" "Indoor Env"  "Enrichment" "Outdoor Access"  "Mutilation"  {
	if "`cat'" == "Confinement" {
		local c = "`cat'"
		local cat_title = "Less `cat'"
		global species "Layers Dairy"
	}
	if "`cat'" == "Mutilation" {
		local c = "`cat'"
		local cat_title = "Reducing `cat'"
	}	
	else if "`cat'" == "Outdoor Access" {
		local c = "Outdoor"
		local cat_title = "`cat'"
	}	
	else if "`cat'" == "Indoor Env" {
		local c = "Indoor"
		local cat_title = "Better `cat'"
	}
	else {
		local c = "`cat'"
		local cat_title = "`cat'"
	}
	
	if "`cat'" == "Confinement" {
		foreach lvl in "Results" "Papers" {
			if "`lvl'" == "Results" {
				local title = "Significant Results"
				local labels = "-5(5)10"
				local ranges = "-5 10"
				
				use "${datadir}\clean_data\final\finalsample_sig_collapsed_cat_results4", clear
			}
			else if "`lvl'" == "Papers" {
				local title = "Median Sig. Result Per Paper"
				local labels = "-2(2)4"
				local ranges = "-2 5"
				
				use "${datadir}\clean_data\final\finalsample_sig_collapsed_cat_papers4", clear
			}
			
			* Make graph for each species
			foreach s in "Layer" "Dairy Cow" "Hog" {
				if "`s'" == "Dairy Cow" {
					local z = "Cow"
					local s2 = "`s'"
				}
				else if "`s'" == "Hog" {
					local z = "Hog"
					local s2 = "Pig"
				}
				else {
					local z = "`s'"
					local s2 = "`s'"
				}
				
				graph hbar (asis) motivator_dum barrier_dum if strpos(Species, "`s2'") & Pract_Category == "`cat'", over(market_factor, ///
				sort(total_factor_`z') descending) ///
				stack ///
				ytitle("# of `lvl'") ///
				title("`s' Farms", span) ///
				ylabel(`labels') ///
				yscale(range(`ranges')) ///
				legend( rows(1) label(1 "Incentive") label(2 "Disincentive")) ///
				graphregion(color(white)) ///
				name(`lvl'_`z'_`c', replace)
				
				graph save `lvl'_`z'_`c', replace
			
		// 		graph export "${figdir}\bar_marketfactor_motivator_finalsample_`z'_results.png", replace
			}
		// 	graph combine papers_Layer.gph papers_Broiler.gph papers_Cow.gph papers_Hog.gph, 
			
			grc1leg `lvl'_Layer_`cat' `lvl'_Cow_`cat' `lvl'_Hog_`cat', ///
				title("(Dis-)Incentives for `cat_title'", ///
				span) subtitle("`title' (1990-2023)") ///
				graphregion(color(white)) ///
				iscale(.6) ///
				imargin(1 1 1 1 1) ///
				legendfrom(`lvl'_Layer_`cat') pos(bottom)
				
				graph export "${figdir}\bar_marketfactor_motivator_finalsample_combine_`c'_`lvl'4.png", replace
		}
	}	
	else if "`cat'" == "Enrichment" {
		foreach lvl in "Results" "Papers" {
			if "`lvl'" == "Results" {
				local title = "Significant Results"
				local labels = "-10(10)30"
				local ranges = "-15 30"
				
				use "${datadir}\clean_data\final\finalsample_sig_collapsed_cat_results4", clear
			}
			else if "`lvl'" == "Papers" {
				local title = "Median Sig. Result Per Paper"
				local labels = "-2(2)4"
				local ranges = "-2 5"
				
				use "${datadir}\clean_data\final\finalsample_sig_collapsed_cat_papers4", clear
			}
			
			* Make graph for each species
			foreach s in "Layer" "Dairy Cow" "Broiler" {
				if "`s'" == "Dairy Cow" {
					local z = "Cow"
					local s2 = "Dairy Cow"
				}
				else if "`s'" == "Hog" {
					local z = "Hog"
					local s2 = "Pig"
				}
				else {
					local z = "`s'"
					local s2 = "`s'"
				}
				
				graph hbar (asis) motivator_dum barrier_dum if strpos(Species, "`s2'") & Pract_Category == "`cat'", over(market_factor, ///
				sort(total_factor_`z') descending) ///
				stack ///
				ytitle("# of `lvl'") ///
				title("`s' Farms", span) ///
				ylabel(`labels') ///
				yscale(range(`ranges')) ///
				legend( rows(1) label(1 "Incentive") label(2 "Disincentive")) ///
				graphregion(color(white)) ///
				name(`lvl'_`z'_`c', replace)
				
				graph save `lvl'_`z'_`c', replace
			
		// 		graph export "${figdir}\bar_marketfactor_motivator_finalsample_`z'_results.png", replace
			}
		// 	graph combine papers_Layer.gph papers_Broiler.gph papers_Cow.gph papers_Hog.gph, 
			
			grc1leg `lvl'_Layer_`c' `lvl'_Cow_`c' `lvl'_Broiler_`c', ///
				title("(Dis-)Incentives for `cat_title'", ///
				span) subtitle("`title' (1991-2023)") ///
				graphregion(color(white)) ///
				iscale(.6) ///
				imargin(1 1 1 1 1) ///
				legendfrom(`lvl'_Layer_`c') pos(bottom)
				
				graph export "${figdir}\bar_marketfactor_motivator_finalsample_combine_`c'_`lvl'4.png", replace
		}
	}	
	else if "`cat'" == "Mutilation" {
		foreach lvl in "Results" "Papers" {
			if "`lvl'" == "Results" {
				local title = "Significant Results"
				local labels = "-10(10)30"
				local ranges = "-15 30"
				
				use "${datadir}\clean_data\final\finalsample_sig_collapsed_cat_results4", clear
			}
			else if "`lvl'" == "Papers" {
				local title = "Median Sig. Result Per Paper"
				local labels = "-4(2)10"
				local ranges = "-4 10"
				
				use "${datadir}\clean_data\final\finalsample_sig_collapsed_cat_papers4", clear
			}
			
			* Make graph for each species
			foreach s in "Dairy Cow" {
				if "`s'" == "Dairy Cow" {
					local z = "Cow"
					local s2 = "Dairy Cow"
				}
				else if "`s'" == "Hog" {
					local z = "Hog"
					local s2 = "Pig"
				}
				else {
					local z = "`s'"
					local s2 = "`s'"
				}
				
				graph hbar (asis) motivator_dum barrier_dum if strpos(Species, "`s2'") & Pract_Category == "`cat'", over(market_factor, ///
				sort(total_factor_`z') descending) ///
				stack ///
				ytitle("# of `lvl'") ///
				title("`s' Farms", span) ///
				ylabel(`labels') ///
				yscale(range(`ranges')) ///
				legend( rows(1) label(1 "Incentive") label(2 "Disincentive")) ///
				graphregion(color(white)) ///
				name(`lvl'_`z'_`c', replace)
				
				graph save `lvl'_`z'_`c', replace
			
		// 		graph export "${figdir}\bar_marketfactor_motivator_finalsample_`z'_results.png", replace
			}
		// 	graph combine papers_Layer.gph papers_Broiler.gph papers_Cow.gph papers_Hog.gph, 
			
			grc1leg `lvl'_Cow_`c', ///
				title("(Dis-)Incentives for `cat_title'", ///
				span) subtitle("`title' (1991-2022)") ///
				graphregion(color(white)) ///
				altshrink ///
				legendfrom(`lvl'_Cow_`cat') pos(bottom)
				
				graph export "${figdir}\bar_marketfactor_motivator_finalsample_combine_`c'_`lvl'4.png", replace
		}
	}	
	else {
		foreach lvl in "Results" "Papers" {
			if "`lvl'" == "Results" {
				local title = "Significant Results"
				local labels = "-20(10)40"
				local ranges = "-25 40"
				
				use "${datadir}\clean_data\final\finalsample_sig_collapsed_cat_results4", clear
			}
			else if "`lvl'" == "Papers" {
				local title = "Median Sig. Result per Paper"
				local labels = "-4(2)10"
				local ranges = "-4 10"
				
				use "${datadir}\clean_data\final\finalsample_sig_collapsed_cat_papers4", clear
			}
			
			* Make graph for each species
			foreach s in "Layer" "Dairy Cow" "Hog" "Broiler" {
				if "`s'" == "Dairy Cow" {
					local z = "Cow"
					local s2 = "`s'"
				}
				else if "`s'" == "Hog" {
					local z = "Hog"
					local s2 = "Pig"
				}
				else {
					local z = "`s'"
					local s2 = "`s'"
				}
				
				graph hbar (asis) motivator_dum barrier_dum if strpos(Species, "`s2'") & Pract_Category == "`cat'", over(market_factor, ///
				sort(total_factor_`z') descending) ///
				stack ///
				ytitle("# of `lvl'") ///
				title("`s' Farms", span) ///
				ylabel(`labels') ///
				yscale(range(`ranges')) ///
				legend( rows(1) label(1 "Incentive") label(2 "Disincentive")) ///
				graphregion(color(white)) ///
				name(`lvl'_`z'_`c', replace)
				
				graph save `lvl'_`z'_`c', replace
			
		// 		graph export "${figdir}\bar_marketfactor_motivator_finalsample_`z'_results.png", replace
			}
		// 	graph combine papers_Layer.gph papers_Broiler.gph papers_Cow.gph papers_Hog.gph, 
			
			grc1leg `lvl'_Layer_`c' `lvl'_Cow_`c' `lvl'_Broiler_`c' `lvl'_Hog_`c', ///
				title("") ///
				graphregion(color(white)) ///
				iscale(.6) ///
				imargin(1 1 1 1 1) ///
				legendfrom(`lvl'_Cow_`c') pos(bottom)
				
				graph export "${figdir}\bar_marketfactor_motivator_finalsample_combine_`c'_`lvl'4.eps", replace
		}
	}
}	
	
}

		// I tried to add the fraction of each factor that is an incentive but could not get blabel or dot to work
		
*******************************************************************************	
* Do same as above but group Practice Categories within each Industry/species
// I want to count "Density" as its own Practice Category since it intersects both Indoor Environment and Outdoor Access (for cows).
// If we want to count "Density" as its own Practice Category, then use Alt_Category. If not, then use "Pract_Cat"

*******************************************************************************	
foreach industry in "Layer" "Cow" "Broiler" "Hog" {
	if "`industry'" == "Cow" {
		local z = "Cow"
		local s2 = "Dairy Cow"
	}
	else if "`industry'" == "Hog" {
		local z = "Hog"
		local s2 = "Pig"
	}
	else {
		local z = "`industry'"
		local s2 = "`industry'"
	}
	
	*---------------------------------------------------------------------
	* DO FOR HOGS	
	if "`industry'" == "Hog" {
		foreach lvl in "Results" "Papers" {
			if "`lvl'" == "Results" {
				local title = "Significant Results"
				local labels = "-2(2)10"
				local ranges = "-2 10"
				
				use "${datadir}\clean_data\final\finalsample_sig_collapsed_cat_results4", clear
			}
			else if "`lvl'" == "Papers" {
				local title = "Median Sig. Result Per Paper"
				local labels = "-1(1)3"
				local ranges = "-1 3"
				
				use "${datadir}\clean_data\final\finalsample_sig_collapsed_cat_papers4", clear
			}
			
			* Make graph for each Practice Cartegory (Alt_Category)	
			foreach cat in "Indoor Env" "Outdoor Access" "Confinement" {
				if "`cat'" == "Confinement" {
					local c = "`cat'"
					local cat_title = "Less `cat'"
					global species "Layers Dairy"
				}
				if "`cat'" == "Mutilation" {
					local c = "`cat'"
					local cat_title = "Reducing `cat'"
				}	
				else if "`cat'" == "Outdoor Access" {
					local c = "Outdoor"
					local cat_title = "`cat'"
				}	
				else if "`cat'" == "Indoor Env" {
					local c = "Indoor"
					local cat_title = "Better `cat'"
				}
				else {
					local c = "`cat'"
					local cat_title = "`cat'"
				}
									
				graph hbar (asis) motivator_dum barrier_dum if strpos(Species, "`s2'") & Pract_Category == "`cat'", over(market_factor, ///
				sort(total_factor_`z') descending) ///
				stack ///
				ytitle("# of `lvl'") ///
				title("`cat_title'", span) ///
				ylabel(`labels') ///
				yscale(range(`ranges')) ///
				legend( rows(2) label(1 "Incentive") label(2 "Disincentive")) ///
				graphregion(color(white)) ///
				name(`lvl'_`z'_`c', replace)
				
				graph save `lvl'_`z'_`c', replace
			}
				
			* Make png with title	
			grc1leg `lvl'_`z'_Indoor `lvl'_`z'_Outdoor `lvl'_`z'_Confinement, ///
				title("(Dis-)Incentives facing `s2' Farms", ///
				span) subtitle("`title' (1991-2022)") ///
				graphregion(color(white)) ///
				iscale(.6) ///
				imargin(1 1 1 1 1) ///
				legendfrom(`lvl'_`z'_Indoor) ///
				row(2) col(2)
				gr_edit legend.xoffset = 55
				gr_edit legend.yoffset = 25
				
				graph export "${figdir}\bar_marketfactor_combine_`industry'_industry_`lvl'4.png", replace
				
				* Make eps without title
				grc1leg `lvl'_`z'_Indoor `lvl'_`z'_Outdoor `lvl'_`z'_Confinement, ///
				title("") ///
				graphregion(color(white)) ///
				iscale(.6) ///
				imargin(1 1 1 1 1) ///
				legendfrom(`lvl'_`z'_Indoor) ///
				row(2) col(2)
				gr_edit legend.xoffset = 55
				gr_edit legend.yoffset = 25
				graph export "${figdir}\bar_marketfactor_combine_`industry'_industry_`lvl'4.eps", replace
		}
	}
	
	*------------------------------------------------------------
	* DO FOR COWS
	if "`industry'" == "Cow" {
		foreach lvl in "Results" "Papers" {
			if "`lvl'" == "Results" {
				local title = "Significant Results"
				local labels = "-5(5)25"
				local ranges = "-5 26"
				
				use "${datadir}\clean_data\final\finalsample_sig_collapsed_cat_results4", clear
			}
			else if "`lvl'" == "Papers" {
				local title = "Median Sig. Result Per Paper"
				local labels = "-2(2)10"
				local ranges = "-2 10"
				
				use "${datadir}\clean_data\final\finalsample_sig_collapsed_cat_papers4", clear
			}
			
			* Make graph for each Practice Cartegory (Alt_Category)	
			foreach cat in "Confinement" "Indoor Env"  "Enrichment" "Outdoor Access"  "Mutilation" {
				if "`cat'" == "Confinement" {
					local c = "`cat'"
					local cat_title = "Less `cat'"
					global species "Layers Dairy"
				}
				if "`cat'" == "Mutilation" {
					local c = "`cat'"
					local cat_title = "Reducing `cat'"
				}	
				else if "`cat'" == "Outdoor Access" {
					local c = "Outdoor"
					local cat_title = "`cat'"
				}	
				else if "`cat'" == "Indoor Env" {
					local c = "Indoor"
					local cat_title = "Better `cat'"
				}
				else {
					local c = "`cat'"
					local cat_title = "`cat'"
				}
									
				graph hbar (asis) motivator_dum barrier_dum if strpos(Species, "`s2'") & Pract_Category == "`cat'", over(market_factor, ///
				sort(total_factor_`z') descending) ///
				stack ///
				ytitle("# of `lvl'") ///
				title("`cat_title'", span) ///
				ylabel(`labels') ///
				yscale(range(`ranges')) ///
				legend( rows(2) label(1 "Incentive") label(2 "Disincentive")) ///
				graphregion(color(white)) ///
				name(`lvl'_`z'_`c', replace)
				
				graph save `lvl'_`z'_`c', replace
			}
				
			* Make png with title	
			grc1leg `lvl'_`z'_Indoor `lvl'_`z'_Outdoor `lvl'_`z'_Confinement `lvl'_`z'_Enrichment `lvl'_`z'_Mutilation, ///
				title("(Dis-)Incentives facing `s2' Farms", ///
				span) subtitle("`title' (1991-2022)") ///
				graphregion(color(white)) ///
				iscale(.6) ///
				imargin(1 1 1 1 1) ///
				legendfrom(`lvl'_`z'_Indoor) ///
				row(2) col(3)
				gr_edit legend.xoffset = 55
				gr_edit legend.yoffset = 25
				
				graph export "${figdir}\bar_marketfactor_combine_`industry'_industry_`lvl'4.png", replace
				
				* Make eps without title
				grc1leg `lvl'_`z'_Indoor `lvl'_`z'_Outdoor `lvl'_`z'_Confinement `lvl'_`z'_Enrichment `lvl'_`z'_Mutilation, ///
				title("") ///
				graphregion(color(white)) ///
				iscale(.6) ///
				imargin(1 1 1 1 1) ///
				legendfrom(`lvl'_`z'_Indoor) ///
				row(2) col(3)
				gr_edit legend.xoffset = 55
				gr_edit legend.yoffset = 25
				
				graph export "${figdir}\bar_marketfactor_combine_`industry'_industry_`lvl'4.eps", replace
		}
	}
	
	*---------------------------------------------------------------------
	* DO FOR BROILERS	
	if "`industry'" == "Broiler" {
		foreach lvl in "Results" "Papers" {
			if "`lvl'" == "Results" {
				local title = "Significant Results"
				local labels = "-10(2)10"
				local ranges = "-10 10"
				
				use "${datadir}\clean_data\final\finalsample_sig_collapsed_cat_results4", clear
			}
			else if "`lvl'" == "Papers" {
				local title = "Median Sig. Result Per Paper"
				local labels = "-2(1)3"
				local ranges = "-2 3"
				
				use "${datadir}\clean_data\final\finalsample_sig_collapsed_cat_papers4", clear
			}
			
			* Make graph for each Practice Cartegory (Alt_Category)	
			foreach cat in "Indoor Env"  "Enrichment" "Outdoor Access" {
				if "`cat'" == "Confinement" {
					local c = "`cat'"
					local cat_title = "Less `cat'"
					global species "Layers Dairy"
				}
				if "`cat'" == "Mutilation" {
					local c = "`cat'"
					local cat_title = "Reducing `cat'"
				}	
				else if "`cat'" == "Outdoor Access" {
					local c = "Outdoor"
					local cat_title = "`cat'"
				}	
				else if "`cat'" == "Indoor Env" {
					local c = "Indoor"
					local cat_title = "Better `cat'"
				}
				else {
					local c = "`cat'"
					local cat_title = "`cat'"
				}
									
				graph hbar (asis) motivator_dum barrier_dum if strpos(Species, "`s2'") & Pract_Category == "`cat'", over(market_factor, ///
				sort(total_factor_`z') descending) ///
				stack ///
				ytitle("# of `lvl'") ///
				title("`cat_title'", span) ///
				ylabel(`labels') ///
				yscale(range(`ranges')) ///
				legend( rows(2) label(1 "Incentive") label(2 "Disincentive")) ///
				graphregion(color(white)) ///
				name(`lvl'_`z'_`c', replace)
				
				graph save `lvl'_`z'_`c', replace
			}
				
			* Make png with title	
			grc1leg `lvl'_`z'_Indoor `lvl'_`z'_Outdoor `lvl'_`z'_Enrichment, ///
				title("(Dis-)Incentives facing `s2' Farms", ///
				span) subtitle("`title' (1991-2022)") ///
				graphregion(color(white)) ///
				iscale(.6) ///
				imargin(1 1 1 1 1) ///
				legendfrom(`lvl'_`z'_Indoor) ///
				row(2) col(2)
				gr_edit legend.xoffset = 55
				gr_edit legend.yoffset = 25
				
				graph export "${figdir}\bar_marketfactor_combine_`industry'_industry_`lvl'4.png", replace
				
				* Make eps without title
				grc1leg `lvl'_`z'_Indoor `lvl'_`z'_Outdoor `lvl'_`z'_Enrichment, ///
				title("") ///
				graphregion(color(white)) ///
				iscale(.6) ///
				imargin(1 1 1 1 1) ///
				legendfrom(`lvl'_`z'_Indoor) ///
				row(2) col(2)
				gr_edit legend.xoffset = 55
				gr_edit legend.yoffset = 25
				graph export "${figdir}\bar_marketfactor_combine_`industry'_industry_`lvl'4.eps", replace
		}
	}
	
	*---------------------------------------------------------------------
	* DO FOR LAYERS	
	if "`industry'" == "Layer" {
		foreach lvl in "Results" "Papers" {
			if "`lvl'" == "Results" {
				local title = "Significant Results"
				local labels = "-10(5)25"
				local ranges = "-11 10"
				
				use "${datadir}\clean_data\final\finalsample_sig_collapsed_cat_results4", clear
			}
			else if "`lvl'" == "Papers" {
				local title = "Median Sig. Result Per Paper"
				local labels = "-2(1)3"
				local ranges = "-2 3"
				
				use "${datadir}\clean_data\final\finalsample_sig_collapsed_cat_papers4", clear
			}
			
			* Make graph for each Practice Cartegory (Alt_Category)	
			foreach cat in "Indoor Env" "Outdoor Access"  "Confinement"  "Enrichment" {
				if "`cat'" == "Confinement" {
					local c = "`cat'"
					local cat_title = "Less `cat'"
					global species "Layers Dairy"
				}
				if "`cat'" == "Mutilation" {
					local c = "`cat'"
					local cat_title = "Reducing `cat'"
				}	
				else if "`cat'" == "Outdoor Access" {
					local c = "Outdoor"
					local cat_title = "`cat'"
				}	
				else if "`cat'" == "Indoor Env" {
					local c = "Indoor"
					local cat_title = "Better `cat'"
				}
				else {
					local c = "`cat'"
					local cat_title = "`cat'"
				}
									
				graph hbar (asis) motivator_dum barrier_dum if strpos(Species, "`s2'") & Pract_Category == "`cat'", over(market_factor, ///
				sort(total_factor_`z') descending) ///
				stack ///
				ytitle("# of `lvl'") ///
				title("`cat_title'", span) ///
				ylabel(`labels') ///
				yscale(range(`ranges')) ///
				legend( rows(1) label(1 "Incentive") label(2 "Disincentive")) ///
				graphregion(color(white)) ///
				name(`lvl'_`z'_`c', replace)
				
				graph save `lvl'_`z'_`c', replace
			}
				
			* Make png with title	
			grc1leg `lvl'_`z'_Indoor `lvl'_`z'_Outdoor `lvl'_`z'_Confinement `lvl'_`z'_Enrichment, ///
				title("(Dis-)Incentives facing `s2' Farms", ///
				span) subtitle("`title' (1991-2022)") ///
				graphregion(color(white)) ///
				iscale(.6) ///
				imargin(1 1 1 1 1) ///
				legendfrom(`lvl'_`z'_Indoor) ///
				row(2) col(2) ///
				pos(bottom)
				
				
				graph export "${figdir}\bar_marketfactor_combine_`industry'_industry_`lvl'4.png", replace
				
				* Make eps without title
				grc1leg `lvl'_`z'_Indoor `lvl'_`z'_Outdoor `lvl'_`z'_Confinement `lvl'_`z'_Enrichment, ///
				title("") ///
				graphregion(color(white)) ///
				iscale(.6) ///
				imargin(1 1 1 1 1) ///
				legendfrom(`lvl'_`z'_Indoor) ///
				row(2) col(2) ///
				pos(bottom)
				
				graph export "${figdir}\bar_marketfactor_combine_`industry'_industry_`lvl'4.eps", replace
		}
	}
	
}	


***********************************************************8
	* Same species-by-category graphs as above but organized with species/industry as outer layer and the 5 practice categories as graphs. (Of course, only dairy cow farms will have the mutilation category)
	* ( "Indoor Env"  "Enrichment" "Confinement" "Outdoor Access"  "Mutilation")
	foreach lvl in "Results" "Papers" {
			
		if "`industry'" == "Cow" {
			grc1leg `lvl'_`industry'_Indoor `lvl'_`industry'_Outdoor `lvl'_`industry'_Enrichment `lvl'_`industry'_Confinement `lvl'_`industry'_Mutilation, ///
			title("") ///
			graphregion(color(white)) ///
			iscale(.6) ///
			imargin(1 1 1 1 1) ///
			legendfrom(`lvl'_`industry'_Indoor) pos(bottom)
			
			graph export "${figdir}\bar_marketfactor_motivator_finalsample_combine_`industry'_`lvl'4.eps", replace
		}
		else if "`industry'" == "Broiler" {
			grc1leg `lvl'_`industry'_Indoor `lvl'_`industry'_Outdoor `lvl'_`industry'_Enrichment , ///
			title("") ///
			graphregion(color(white)) ///
			iscale(.6) ///
			imargin(1 1 1 1 1) ///
			legendfrom(`lvl'_`industry'_Indoor) pos(bottom)
			
			graph export "${figdir}\bar_marketfactor_motivator_finalsample_combine_`industry'_`lvl'4.eps", replace
		}
		else if "`industry'" == "Hog" {
			grc1leg `lvl'_`industry'_Indoor `lvl'_`industry'_Outdoor `lvl'_`industry'_Confinement , ///
			title("") ///
			graphregion(color(white)) ///
			iscale(.6) ///
			imargin(1 1 1 1 1) ///
			legendfrom(`lvl'_`industry'_Indoor) pos(bottom)
			
			graph export "${figdir}\bar_marketfactor_motivator_finalsample_combine_`industry'_`lvl'4.eps", replace
		}
		else if "`industry'" == "Layer" {
			grc1leg `lvl'_`industry'_Indoor `lvl'_`industry'_Outdoor `lvl'_`industry'_Enrichment `lvl'_`industry'_Confinement, ///
			title("") ///
			graphregion(color(white)) ///
			iscale(.6) ///
			imargin(1 1 1 1 1) ///
			legendfrom(`lvl'_`industry'_Indoor) pos(bottom)
			
			graph export "${figdir}\bar_marketfactor_motivator_finalsample_combine_`industry'_`lvl'4.eps", replace
		}
	}	
}

	
****************** Collapse data (all species combined) ***********************	

		//  If on same y scal: ylabel(-50(25)100) yscale(range(-50 100)).
foreach lvl in "Results" "Papers" {
	if "`lvl'" == "Results" {
		local title = "Significant Results (1990-2023)"
		local labels = "-20(10)50"
		local ranges = "-20 50"
		
		use "${datadir}\clean_data\final\finalsample_sig_collapsed_cat_results3", clear
	}
	else if "`lvl'" == "Papers" {
		local title = "Median Sig. Result per Paper (1990-2023)"
		local labels = "-4(2)14"
		local ranges = "-4 14"
		
		use "${datadir}\clean_data\final\finalsample_sig_collapsed_cat_papers3", clear
	}		
	foreach cat in "Indoor Env"  "Enrichment" "Outdoor Access" "Confinement" "Mutilation"  {
		if "`cat'" == "Confinement" {
			local c = "`cat'"
			local cat_title = "Less `cat'"
		}
		else if "`cat'" == "Mutilation" {
			local c = "`cat'"
			local cat_title = "Less `cat'"
		}	
		else if "`cat'" == "Outdoor Access" {
			local c = "Outdoor"
			local cat_title = "`cat'"
		}	
		else if "`cat'" == "Indoor Env" {
			local c = "Indoor"
			local cat_title = "Better `cat'ironment"
		}
		else {
			local c = "`cat'"
			local cat_title = "`cat'"
		}
		
		* Collapse away the species
		collapse (sum) motivator_dum barrier_dum, by(market_factor Pract_Category)
		
		gen total_factor = motivator_dum + barrier_dum
		gen frac_factor = motivator_dum / total_factor
		
		
		graph hbar (asis) motivator_dum barrier_dum if Pract_Category == "`cat'", over(market_factor, ///
		sort(total_factor) descending) ///
		stack ///
		title("`cat_title'", span) ///
		ytitle("# of `lvl'") ///
		ylabel(`labels') ///
		yscale(range(`ranges')) ///
		legend( rows(2) label(1 "Incentive") label(2 "Disincentive")) ///
		graphregion(color(white)) ///
		name(`lvl'_`c', replace)
		
		graph save `lvl'_`c', replace

	// 	graph export "${figdir}\bar_marketfactor_motivator_finalsample_papers.png", replace
	}	

		grc1leg	`lvl'_Indoor `lvl'_Confinement  `lvl'_Mutilation `lvl'_Enrichment `lvl'_Outdoor  , ///
			title("") ///
			graphregion(color(white)) ///
			iscale(.6) ///
			imargin(1 1 1 1 1) ///
			legendfrom(`lvl'_Outdoor) ///
			row(2) col(3)
			gr_edit legend.xoffset = 55
			gr_edit legend.yoffset = 25
			
		graph export "${figdir}\bar_marketfactor_motivator_finalsample_comnbine_cat_`lvl'4.eps", replace	
	}
	
	