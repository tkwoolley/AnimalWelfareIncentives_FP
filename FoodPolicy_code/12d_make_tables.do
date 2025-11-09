* Project:	Humane Practice Adoption
* Author:	Trevor Woolley
* Date:		03/28/24
* Purpose:	Produce tables
******************************************************************************
global homedir "D:\Projects\ASPCA"
global datadir "D:\Projects\ASPCA\data"
global figdir "D:\Projects\ASPCA\figures"

ssc install filelist
******************************************************************************
* Pull in final data
******************************************************************************
use "${datadir}\clean_data\final\final_data", clear

******************************************************************************
* Make motivator/barrier tables
******************************************************************************

* Version 1: Nothing fancy. Just lists all the motivator/barriers for each species practice

// columns: species, practice, market motivators , external motivators, market barriers, external barriers
// If only one paper per motivator/barrier, I'd like to put an astrisk next to it to indicate significance
// Might actually be easiest to just organize the data in the way I want the table to look, export to excel, and adjust it there. The weird part about this is that I will have to reshape wide but

order id Species Practice motivator barrier
sort Species Practice motivator barrier
br if strpos(home_run, "1") & pract_good !=""

* Version 2: If possible to make few enough categories of motivator/barriers (price, productivity, quality, etc.), then I'd like those to be the columns and species/practice to be the rows.

******************************************************************************
* Make table documenting insignificant findings (what has at least been tried)
******************************************************************************


