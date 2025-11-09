* Project:	Humane Practice Adoption
* Author:	Trevor Woolley
* Date:		9/10/23
* Purpose:	Create time series plots to describe the initial categorization of the data. At this stage, no one has read through any papers to identify whether factors can be categorized as motivators or barriers
******************************************************************************
global homedir "D:\Projects\ASPCA"
global datadir "D:\Projects\ASPCA\data"
global figdir "D:\Projects\ASPCA\figures"

ssc install filelist
graph set window fontface "Times New Roman"
graph set eps fontface "Times New Roman"
******************************************************************************
* Pull in data
	use "${datadir}\double_check\human_abstract_review2\human_review2_all_v2_edited", clear	
	// This is the batch of papers that passed the first manual review (but not necessarily the second one) and which had at least one US-affiliated author see 3d_make_final_abstract_review.do)
	
******************************************************************************	
	* Label journal subject 
******************************************************************************	
	* Merge in less-clean dataset for journal subjects
	merge 1:1 id using "${datadir}\clean_data\all_categorized.dta", force
	
	keep if _merge ==3
	drop _merge
	
	gen pub_other = 0
	replace pub_other = 1 if pub_geo==1 | pub_engin==1 |  pub_chem==1 | pub_misc==1
	// The other thing that is weird is that there are papers assigned to multiple subjects
	
	* Make year consistent
	destring year, replace
	replace pubyear = year if pubyear==.
	
	tempfile data
	save `data'

******************************************************************************	
	* Label "Broilers" and "Layers"
******************************************************************************
	
	* First by merging in the final sample (101 papers) and then by string searching
	use "${datadir}\clean_data\final\final_data2", clear
	rename Species Species2
	duplicates  drop id, force
	
	merge 1:1 id using `data', force
	rename _merge in_final_sample
	replace in_final_sample = 0 if in_final_sample ==2
	replace in_final_sample = 1 if in_final_sample ==3	
	
	replace Species = Species2 if in_final_sample==1
	
	tab Species
	
	* Replace about_[species]
	replace about_cows = 0
	replace about_cows = 1 if Species == "Dairy Cow" | Species == "Cows" | strpos(species,"Cows") | strpos(simpletitle, "milk") | strpos(simpletitle, "cow") | strpos(simpletitle, "cows") | strpos(simpletitle, "dairy") | strpos(simpletitle, "cattle") | strpos(simpletitle, "grazing") | strpos(simpletitle, "lameness")
	replace about_pigs = 0
	replace about_pigs = 1 if Species == "Pig" | Species == "Pigs" | strpos(species,"Pigs") | strpos(simpletitle, "pig")  | strpos(simpletitle, "pigs") |  strpos(simpletitle, "hog") | strpos(simpletitle, "pork") | strpos(simpletitle, "boar") | strpos(simpletitle, "sows") | strpos(simpletitle, "swine") | strpos(simpletitle, "ham") | strpos(simpletitle, "gestation")
	
	* Now string match for "broilers" and "layers"
	replace Species = "Broiler" if (Species == "Hens" | strpos(species,"Hens"))  & (strpos(abstract_2045, "broiler") | strpos(abstract_2045, "broilers") | strpos(abstract_2045, "roiler") | strpos(abstract_2045, "roilers") | strpos(abstract_2045, "poultry") |  strpos(abstract_2045, "Poultry") )
	replace about_broilers = 0
	replace about_broilers = 1 if Species == "Broiler" | strpos(simpletitle, "broiler") | strpos(simpletitle, "broilers") | strpos(simpletitle, "poultry")

	replace Species = "Layer" if Species == "Hens" | (strpos(species, "Hens") & about_broilers == 0)
	//  Only 3 did not also match when including (strpos(abstract_2045, "hen") | strpos(abstract_2045, "Hen") | strpos(abstract_2045, "egg") | strpos(abstract_2045, "Egg")) and I double checked these.
	replace about_layers = 0
	replace about_layers = 1 if Species == "Layer" | strpos(simpletitle, "hen")  | strpos(simpletitle, "eggs") 
	
	count if about_broilers==0 & about_cows==0 & about_layers==0 & about_pigs==0
	

******************************************************************************
* 								Time Series				
******************************************************************************
/* Year trends 
1) species 
2) publication subjects
3) search term categories 
4) factor flags 
*/

	
preserve	
	collapse (sum) about_cows about_pigs about_layers about_broilers pub_ag pub_bio pub_med pub_enviro pub_econ pub_other, by(pubyear)
	
	* 
	
******************************************************************************
* 1) Species
******************************************************************************
	tsset pubyear
	tsline about_cows about_layers about_broilers about_pigs if pubyear <2023, ///
	title("", justification(center)) /// 
	subtitle("") ///
	legend(label(1 "Cows") label(2 "Layers") label(3 "Broilers") label(4 "Hogs") pos(3) col(1)) ///
	graphregion(color(white)) ///
	xlab(1990(4) 2022)
	
	graph export "${figdir}\time_species_399_b.eps", replace
	
// 	twoway (lpoly about_cows pubyear) (lpoly about_layers pubyear) (lpoly about_broilers pubyear) (lpoly about_pigs pubyear) if pubyear <2023, ///
// 	title("", justification(center)) /// 
// 	subtitle("") ///
// 	legend(label(1 "Cows") label(2 "Layers") label(3 "Broilers") label(4 "Pigs") pos(3) col(1)) ///
// 	graphregion(color(white)) ///
// 	xlab(1990(4) 2022)
//	
// 	graph export "${figdir}\time_species_399_smooth.eps", replace
	
	*** Plot cummulative area ***
	gen cummul_1 = about_cows

	local k = 2
	foreach f in about_layers about_pigs about_broilers {
		local j= `k'-1
		gen cummul_`k' = cummul_`j' + `f'
		local k = `k'+1
	}
	
	twoway (area cummul_4 cummul_3 cummul_2 cummul_1 pubyear if pubyear <2023, graphregion(color(white)) ///
	title("") /// 
	legend(label(1 "Broilers") label(2 "Hogs") label(3 "Layers") label(4 "Cows") pos(3) col(1))  ///
	xlab(1990(4) 2022) color(forest_green maroon navy))
	
	graph export "${figdir}\timearea_species_399_b.eps", replace
	
	drop cummul_*
	
******************************************************************************
* 2) Publication Subject
******************************************************************************
	*** Plot separate line trends ***
	tsset pubyear
	tsline pub_ag pub_bio pub_med pub_enviro pub_econ pub_other if pubyear <2023, ///
	title("") /// 
	legend(label(1 "Agriculture") label(2 "Biology") label(3 "Medical") label(4 "Environment") label(5 "Economics") label(6 "Other") pos(3) col(1)) ///
	graphregion(color(white)) ///
	xlab(1990(4) 2022)
	
	graph export "${figdir}\time_pubsubject_399_b.eps", replace

	
	*** Plot cummulative area ***
	gen cummul_1 = pub_ag

	local k = 2
	foreach f in pub_bio pub_med pub_enviro pub_econ pub_other {
		local j= `k'-1
		gen cummul_`k' = cummul_`j' + `f'
		local k = `k'+1
	}
	
	twoway (area cummul_6 cummul_5 cummul_4 cummul_3 cummul_2 cummul_1 pubyear if pubyear <2023, graphregion(color(white)) ///
	title("") /// 
	legend(label(6 "Agriculture") label(5 "Biology") label(4 "Medical") label(3 "Environment") label(2 "Economics") label(1 "Other") pos(3) col(1)) ///
	xlab(1990(4) 2022) color(sienna khaki lavender cranberry teal dkorange forest_green maroon navy))
	
	graph export "${figdir}\timearea_pubsubject_399_b.eps", replace
	
	drop cummul_*
	
restore
