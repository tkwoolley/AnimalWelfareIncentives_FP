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
* 				Round 1: Analyze all abstracts
******************************************************************************

* Pull in data for 30 topics (seed: 42)
// import delimited "${jupdir}\lda_output_30topic_best37.csv", clear 
import delimited "${jupdir}\lda_output_30topic_seed42_round1.csv", clear 
// Dropping the inclusion of USA publications dropped 2,400 abstracts. Now there are 5,848 abstracts

	* Check correlations between all topics
	correlate topic_*
	matrix C = r(C)

	* Drop topic score
	drop topic_*_score
	
	* Distribution of topic percentage (e.g. topic_0)
	foreach x in topic_* {
			sum `x', d
		}
		
	// For topic percentages (e.g. topic_0), a score > .6 (and sometimes >.8) will generally put the paper in the 99th percentile of similarity. 
	// For topic scores (e.g. topic_0_score), a score >.1 will generally put the paper in the 99th percentile of similarity

	
	* Gen thresholds for propensity scores 99th percentile for a topic
	foreach x in topic_0 topic_1 topic_2 topic_3 topic_4 topic_5 topic_6 topic_7 topic_8 topic_9 topic_10 topic_11 topic_12 topic_13 topic_14 topic_15 topic_16 topic_17 topic_18 topic_19 topic_20 topic_21 topic_22 topic_23 topic_24 topic_25 topic_26 topic_27 topic_28 topic_29 {
		sum `x',d
		gen `x'_p99 = 0
		replace `x'_p99 =1 if `x' >= r(p99)
		gen `x'_p95 = 0
		replace `x'_p95 =1 if `x' >= r(p95)
		gen `x'_p90 = 0
		replace `x'_p90=1 if `x' >= r(p90)
	}
	
	* Creat list of abstracts for seemingly irrelevant topics
// 	foreach v in topic_0 topic_4 topic_5 topic_8 topic_10 topic_14 topic_17 topic_18 topic_20 topic_24 {
	foreach v in topic_0 topic_1 topic_2 topic_3 topic_4 topic_5 topic_6 topic_7 topic_8 topic_9 topic_10 topic_11 topic_12 topic_13 topic_14 topic_15 topic_16 topic_17 topic_18 topic_19 topic_20 topic_21 topic_22 topic_23 topic_24 topic_25 topic_26 topic_27 topic_28 topic_29 {
		foreach x in 95 {
			preserve
				keep if `v'_p`x' 
				keep id abstract `v' `v'_p95 `v'_p99
				order id abstract `v' `v'_p95 `v'_p99
				export excel using "${datadir}\double_check\round_1\abstracts_`v'_p`x'.xls", firstrow(variables) replace
			restore
		}
	}
	
// 	rename topic_*_p95 topic_*_p95_old
// 	keep id abstract topic_*_p95_old
// 	save "${datadir}\double_check\old\abstracts_all_p95", replace
	save "${datadir}\double_check\round_1\abstracts_all_p95", replace


*****************************************************************************
*	No need to re-run this section
// We double-checked 65 of each of the p95 abstracts for the seemingly irrelevant topics
// Note that in seed37, Topic 20 included "new zealand" as a topic phrase so I went back and adjusted the non USA exclusion criteria to exclude publisher being in USA
*****************************************************************************
// 	merge 1:1 id using "${datadir}\double_check\old\abstracts_all_p95"
//	
// 	reg topic_0_p95_old topic_*_p95 // new topic_5 matchs old topic_0_p95_old
// 	reg topic_17_p95_old topic_*_p95 // new topic_18 matchs old topic_17_p95_old
// 	reg topic_24_p95_old topic_*_p95 // new topic_5 and topic_6 match old topic_24_p95_old
//	
// I then confirmed that 65 random abstracts from topic_5_p95, topic_6_p95, and topic_18_p95 were not relevant
*****************************************************************************
	use "${datadir}\double_check\round_1\abstracts_all_p95", clear
	
	* Flag EconLit articles to drop them now and add in later (among merged bc I wish I would've removed them in 2_categorize_data)
	preserve
		 import excel "${jupdir}\LDA_Abstracts.xls", sheet("Sheet1") firstrow clear // Same group of papers, but some have different ids
		save "${jupdir}\LDA_Abstracts", replace
	restore
	merge 1:1 id using "${jupdir}\LDA_Abstracts", force
	drop if _m==2
	drop _m
	
	* Which topics have econlit?
	gen econlit = 0 if search_engine!=""
	replace econlit = 1 if search_engine == "EconLit"

	reg econlit topic_0_p95 topic_1_p95 topic_2_p95 topic_3_p95 topic_4_p95 topic_5_p95 topic_6_p95 topic_7_p95 topic_8_p95 topic_9_p95 topic_10_p95 topic_11_p95 topic_12_p95 topic_13_p95 topic_14_p95 topic_15_p95 topic_16_p95 topic_17_p95 topic_18_p95 topic_19_p95 topic_20_p95 topic_21_p95 topic_22_p95 topic_23_p95 topic_24_p95 topic_25_p95 topic_26_p95 topic_27_p95 topic_28_p95 topic_29_p95
	// Only topics 10 and 12 are predictors of econlit
	
	* Drop First Round of excluded abstracts
	drop if topic_5_p95 ==1 | topic_6_p95 ==1 | topic_16_p95 | topic_18_p95 | topic_22_p95 | topic_28_p95

*****************************************************************************
	* Need to be selective with 4,8,11,14,19,20,23 (the "iffy" topics)
*****************************************************************************
	* Topics we definitely want to keep: 
	** Those that have been checked: 2,3,7,9,10,12,13,24,26, 27, 29
	** Those that have not been checked: 0,1,15,17,21,25
	
	* Import checked excel sheets for iffy topics, merge with checked "keeper" topics
	foreach x in 4 8 11 14 19 20 23 2 3 7 9 10 12 13 24 26 27 29 {
		preserve
			import excel "${datadir}\double_check\round_1\checked\abstracts_topic_`x'_p95_TW.xls", sheet("Sheet1") firstrow clear
			rename keep keep_`x'
			save "${datadir}\double_check\round_1\checked\stata\abstracts_topic_`x'_p95_TW", replace
		restore
	}
	foreach x in 0 1 15 17 21 25 {
		preserve
			import excel "${datadir}\double_check\round_1\abstracts_topic_`x'_p95.xls", sheet("Sheet1") firstrow clear
			save "${datadir}\double_check\round_1\checked\stata\abstracts_topic_`x'_p95", replace
		restore
	}
	
	foreach x in 4 8 11 14 19 20 23 2 3 7 9 10 12 13 24 26 27 29 {
		merge 1:1 id using "${datadir}\double_check\round_1\checked\stata\abstracts_topic_`x'_p95_TW"
		drop _m
	}	
	foreach x in 0 1 15 17 21 25 {
		merge 1:1 id using "${datadir}\double_check\round_1\checked\stata\abstracts_topic_`x'_p95"
		drop _m
	}	
	
	foreach x in 4 8 11 14 19 20 23 {
		disp "********* This is Topic `x' ***************"
		sum keep_`x'
		reg keep_`x' topic_2_p95 topic_3_p95 topic_7_p95 topic_9_p95 topic_10_p95 topic_12_p95 topic_13_p95 topic_24_p95 topic_26_p95 topic_27_p95 topic_29_p95 topic_0_p95 topic_1_p95 topic_15_p95 topic_17_p95 topic_21_p95 topic_25_p95 
	}
*****************************************************************************
	* Regression results indicate that
	** Keep 4 is predicted by topic_2_p95, topic_27_p95, topic_29_p95, topic_15_p95 
	** Keep 8 is not predicted by any topic p95
	** Keep 11 is not predicted by any topic p95
	** Keep 14 is predicted by topic_1_p95
	** Keep 19 is predicted by topic_3_p95 and a little by topic_2_p95, topic_0_p95, topic_1_p95, topic_15_p95
	** Keep 20 is predicted by topic_0_p95
	** Keep 23 is predicted by topic_24_p95
	
	// Implies that most important topics are possibly 0, 1, 2, 3, 15, 24, 27, 29
*****************************************************************************
	
	* Drop articles in iffy topics that are NOT ALSO in these wanted topics that predicted inclusion
	// Always keep topics 10, 12 bc of predictability of econ topics
	drop if topic_4_p95 ==1 & !topic_2_p95 & !topic_27_p95 & !topic_29_p95 & !topic_15_p95 & !topic_10_p95 & !topic_12_p95
	drop if topic_8_p95 ==1 & !topic_10_p95 & !topic_12_p95
	drop if topic_11_p95 ==1 & !topic_10_p95 & !topic_12_p95
	drop if topic_14_p95 ==1 & !topic_10_p95 & !topic_12_p95 & !topic_1_p95
	drop if topic_19_p95 ==1 & !topic_10_p95 & !topic_12_p95 & !topic_3_p95 & !topic_2_p95 & !topic_0_p95 & !topic_1_p95 & !topic_15_p95
	drop if topic_20_p95 ==1 & !topic_10_p95 & !topic_12_p95 & !topic_0_p95
	drop if topic_23_p95 ==1 & !topic_10_p95 & !topic_12_p95 & !topic_24_p95
	
// 	drop if search_engine == "EconLit"
	// This drops 182 of the 275 EconLit articles. We'll just add them back in after the LDA iteration process
	// Use EconLit to validate process
	
	* Drop any abstracts that we manually decided should not be kept
	foreach x in 4 8 11 14 19 20 23 2 3 7 9 10 12 13 24 26 27 29 {
		drop if keep_`x' == 0
	}
	
	keep id title publication authors abstract doi search_engine
	
	export excel using "${jupdir}\LDA_Abstracts_round2.xls", firstrow(variables) replace	// Now have 3,476 abstracts for round 2
	
	