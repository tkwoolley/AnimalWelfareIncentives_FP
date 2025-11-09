* Project:	Humane Practice Adoption
* Author:	Trevor Woolley
* Date:		10/13/23
* Purpose:	Analyze the LDA results
******************************************************************************
global homedir "C:\Users\trevor_woolley\Documents\ASPCA"
global datadir "C:\Users\trevor_woolley\Documents\ASPCA\data"
global figdir "C:\Users\trevor_woolley\Documents\ASPCA\figures"
global jupdir "C:\Users\trevor_woolley\Documents\ASPCA\code\Jupyter"

ssc install filelist
ssc install asdoc
******************************************************************************
* 				Round 2: Analyze abstracts
******************************************************************************

* Pull in data for 15 topics (seed: 42)
import delimited "${jupdir}\lda_output_15topic_seed99_round2.csv", clear 

	* Distribution of topic percentage (e.g. topic_0)
	foreach x in topic_* {
		sum `x', d
	}
	
	* Drop topic score
	drop topic_*_score
	
	* Gen thresholds for propensity scores 99th percentile for a topic
	foreach x in topic_0 topic_1 topic_2 topic_3 topic_4 topic_5 topic_6 topic_7 topic_8 topic_9 topic_10 topic_11 topic_12 topic_13 topic_14 {
		sum `x',d
		gen `x'_p99 = 0
		replace `x'_p99 =1 if `x' >= r(p99)
		gen `x'_p95 = 0
		replace `x'_p95 =1 if `x' >= r(p95)
		gen `x'_p90 = 0
		replace `x'_p90=1 if `x' >= r(p90)
	}
	
	* Creat list of abstracts for seemingly irrelevant topics
	foreach v in topic_0 topic_1 topic_2 topic_3 topic_4 topic_5 topic_6 topic_7 topic_8 topic_9 topic_10 topic_11 topic_12 topic_13 topic_14 {
		foreach x in 95 {
			preserve
				keep if `v'_p`x' 
				keep id abstract `v' `v'_p95 `v'_p99
				order id abstract `v' `v'_p95 `v'_p99
				export excel using "${datadir}\double_check\round_2\abstracts_`v'_p`x'.xls", firstrow(variables) replace
			restore
		}
	}
	
	save "${datadir}\double_check\round_2\abstracts_all_p95", replace
	
******************************************************************************
	use "${datadir}\double_check\round_2\abstracts_all_p95", clear
	* See which topics were most likely to include EconLit articles
	merge 1:1 id using "${jupdir}\LDA_Abstracts", force
	drop if _m==2
	drop _m
	
	* Which topics have econlit?
	gen econlit = 0 if search_engine!=""
	replace econlit = 1 if search_engine == "EconLit"

	reg econlit topic_0_p95 topic_1_p95 topic_2_p95 topic_3_p95 topic_4_p95 topic_5_p95 topic_6_p95 topic_7_p95 topic_8_p95 topic_9_p95 topic_10_p95 topic_11_p95 topic_12_p95 topic_13_p95 topic_14_p95
	// No topics were statistically more likely than others to contain econlit abstracts

*****************************************************************************
	* Need to be selective with 10 and 13 (the "iffy" topics)
*****************************************************************************
	
	* Import checked excel sheets for iffy topics, merge with checked "keeper" topics
	foreach x in 0 1 2 3 4 5 6 7 8 {
		preserve
			import excel "${datadir}\double_check\round_2\checked\abstracts_topic_`x'_p95_TW.xls", sheet("Sheet1") firstrow clear
			rename keep keep_`x'
			save "${datadir}\double_check\round_2\checked\stata\abstracts_topic_`x'_p95_TW", replace
		restore
	}
	foreach x in 10 12 13 {
		preserve
			import excel "${datadir}\double_check\round_2\checked\abstracts_topic_`x'_p95_SPTW.xls", sheet("Sheet1") firstrow clear
			if `x' == 10 {
				replace keep = "1" if keep =="?"
				destring keep, replace force
			}
			
			rename keep keep_`x'
			save "${datadir}\double_check\round_2\checked\stata\abstracts_topic_`x'_p95_TW", replace
		restore
	}
	foreach x in 9 11 14 {
		preserve
			import excel "${datadir}\double_check\round_2\unchecked_version\abstracts_topic_`x'_p95.xls", sheet("Sheet1") firstrow clear
			save "${datadir}\double_check\round_2\checked\stata\abstracts_topic_`x'_p95", replace
		restore
	}
	
	* Merge the checked excel sheets
	foreach x in 4 0 1 2 3 4 5 6 7 8 10 12 13 {
		merge 1:1 id using "${datadir}\double_check\round_2\checked\stata\abstracts_topic_`x'_p95_TW"
		drop _m
	}	
	foreach x in 9 11 14 {
		merge 1:1 id using "${datadir}\double_check\round_2\checked\stata\abstracts_topic_`x'_p95"
		drop _m
	}	
	
	* Check the iffy topics
	foreach x in 10 13 {
		disp "********* This is Topic `x' ***************"
		sum keep_`x'
		reg keep_`x' topic_0_p95 topic_1_p95 topic_2_p95 topic_3_p95 topic_4_p95 topic_5_p95 topic_6_p95 topic_7_p95 topic_8_p95 topic_9_p95 topic_11_p95 topic_12_p95 topic_14_p95
	}
	// No relevant topics predict keepers in these topics
	
	* Overlap between iffy topics and not iffy
	foreach x in 10 13 {
		disp "********* This is Topic `x' ***************"
		reg topic_`x'_p95 topic_0_p95 topic_1_p95 topic_2_p95 topic_3_p95 topic_4_p95 topic_5_p95 topic_6_p95 topic_7_p95 topic_8_p95 topic_9_p95 topic_11_p95 topic_12_p95 topic_14_p95
	}
	// Seemingly no particular overlap
	
	* Drop articles in iffy topics that are NOT ALSO in relevant topics 
	drop if (topic_10_p95 ==1 | topic_13_p95 ==1) & keep_10!=1 & keep_13!=1 & !topic_0_p95 & !topic_1_p95 & !topic_2_p95 & !topic_3_p95 & !topic_4_p95 & !topic_5_p95 & !topic_6_p95 & !topic_7_p95 & !topic_8_p95 & !topic_9_p95 & !topic_11_p95 & !topic_12_p95 & !topic_14_p95
	
	* Drop any abstracts that we manually decided should not be kept
	foreach x in 0 1 2 3 4 5 6 7 8 12 {
		drop if keep_`x' == 0
	}
	
	keep id abstract
	
	export excel using "${datadir}\double_check\Abstracts_postRound2.xls", firstrow(variables) replace	// Now have 3,117
	// BTW, this id seems to have been generated in alphabetical order by title. So, if there are ever any merging issues, keep this in mind.
	
	* Convert abstract into str2040 for merge with all abstracts
	import excel "C:\Users\trevor_woolley\Documents\ASPCA\data\double_check\Abstracts_postRound2.xls", sheet("Sheet1") firstrow
	
	rename abstract abstract_2045 
	recast str2045 abstract_2045, force
	duplicates drop abstract_2045, force
	
	save "${datadir}\double_check\Abstracts_postRound2"
	
	use "${jupdir}\LDA_Abstracts", clear
	rename abstract abstract_2045 
	recast str2045 abstract_2045, force
	duplicates drop abstract_2045, force
	
	merge 1:1 abstract_2045 using "${datadir}\double_check\Abstracts_postRound2", force
	drop if _m==2
	drop _m
	
	
