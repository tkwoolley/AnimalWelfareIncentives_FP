* Project:	Humane Practice Adoption
* Author:	Trevor Woolley
* Date:		9/7/23
* Purpose:	Begin simple categorization of articles: location (USA/not), farm as subject, journal field, species mentioned, ex-ante factor mentioned
******************************************************************************
global homedir "C:\Users\trevor_woolley\Documents\ASPCA"
global datadir "C:\Users\trevor_woolley\Documents\ASPCA\data"
global figdir "C:\Users\trevor_woolley\Documents\ASPCA\figures"

ssc install filelist
******************************************************************************
* Pull in data
use "${datadir}\clean_data\all_nodups.dta", clear

// variable "journal" is now "publication" and not all papers are journal articles anymore

******************************************************************************
* Flag publication type	
*****************************************************************************
	gen pub_type = documenttype
	replace pub_type = "other" if regexm(documenttype, "Bulletin|Letter|Miscellaneous|Note|Preprint|Editorial")
	replace pub_type = "WP, Diss, or Thesis" if regexm(documenttype, "Working|Dissertation|Thesis")
	replace pub_type = "Book or Chapter" if regexm(documenttype, "Book")
	replace pub_type = "Proceedings" if regexm(documenttype, "Proceeding|proceeding")
	// Only half of the non-abstract papers in WOS have a documenttype but almost all of the abstract papers have one
	
	tab pub_type

******************************************************************************
* Generate dummy variables for the presence of farm animal words in abstract	
*****************************************************************************
	gen about_pigs = 0
	foreach x in Pig pig Hog hog Pork pork Sow sow Swine swine Barrow barrow Boar boar Gilt gilt {
		replace about_pigs = 1 if strpos(abstract, "`x'") | strpos(title, "`x'") | strpos(simpletitle, "`x'")
	}
	gen about_cows = 0
	foreach x in Dairy dairy Beef beef Cow cow Cattle cattle Calf calf Milk milk Bovine bovine Heifer heifer Steer steer Bull bull Leather leather {
		replace about_cows = 1 if strpos(abstract, "`x'") | strpos(title, "`x'") | strpos(simpletitle, "`x'")
	}
	gen about_dairy = 0
	foreach x in Dairy dairy Milk milk {
		replace about_dairy = 1 if strpos(abstract, "`x'") | strpos(title, "`x'") | strpos(simpletitle, "`x'")
	}
	gen about_beef = 0
	foreach x in Beef beef {
		replace about_beef = 1 if strpos(abstract, "`x'") | strpos(title, "`x'") | strpos(simpletitle, "`x'")
	}
	gen about_hens = 0
	foreach x in Hen hen Chicken chicken Chick chick Layer layer Broiler broiler Poultry poultry Egg egg Pullet pullet Cockerel cockerel Rooster rooster {
		replace about_hens = 1 if strpos(abstract, "`x'") | strpos(title, "`x'") | strpos(simpletitle, "`x'")
	}
	gen about_layers = 0
	foreach x in Layer layer Egg egg {
		replace about_layers = 1 if strpos(abstract, "`x'") | strpos(title, "`x'") | strpos(simpletitle, "`x'")
	}
	gen about_broilers = 0
	foreach x in Broiler broiler {
		replace about_broilers = 1 if strpos(abstract, "`x'") | strpos(title, "`x'") | strpos(simpletitle, "`x'")
	}
	gen about_fish = 0
	foreach x in Fish fish Trout trout Salmon salmon Tuna tuna {
		replace about_fish = 1 if strpos(abstract, "`x'") | strpos(title, "`x'") | strpos(simpletitle, "`x'")
	}
	gen about_turkey = 0
	foreach x in Turkey turkey {
		replace about_turkey = 1 if strpos(abstract, "`x'") | strpos(title, "`x'") | strpos(simpletitle, "`x'")
	}
	
	gen about_misc_animal = 0
	foreach x in Breed breed Dam dam Flock flock Herd herd Livestock livestock Polled polled Sire sire Litter litter Animal animal Aviary aviary {
		replace about_misc_animal = 1 if strpos(abstract, "`x'") | strpos(title, "`x'") | strpos(simpletitle, "`x'")
	}
	
	gen drop_nonPCH = 0
	replace drop_nonPCH = 1 if !about_pigs & !about_cows & !about_hens & !about_misc_animal | about_fish | about_turkey
	tab drop_nonPCH
	
	* Generate single variable for species
	gen species = ""
	replace species = "Pigs" if about_pigs == 1
	replace species = "Cows" if about_cows == 1
	replace species = "Hens" if about_hens == 1
	replace species = "Hens & Pigs" if about_hens == 1 & about_pigs == 1
	replace species = "Cows & Hens" if about_hens == 1 & about_cows == 1
	replace species = "Cows & Pigs" if about_cows == 1 & about_pigs == 1
	replace species = "Cows & Hens & Pigs" if about_cows == 1 & about_hens == 1 & about_pigs == 1

	
******************************************************************************
* Flag whether study uses farmers (or producers) as unit of observation
******************************************************************************	
	gen about_farm = 0
	foreach x in Farm farm Barn barn {
		replace about_farm = 1 if strpos(abstract, "`x'") | strpos(title, "`x'") | strpos(simpletitle, "`x'")
	}
	gen about_producer = 0
	foreach x in Producer producer {
		replace about_producer = 1 if strpos(abstract, "`x'") | strpos(title, "`x'") | strpos(simpletitle, "`x'")
	}
	gen about_operation = 0
	foreach x in Operat operat {
		replace about_operation = 1 if strpos(abstract, "`x'") | strpos(title, "`x'") | strpos(simpletitle, "`x'")
	}
	gen about_contractor = 0
	foreach x in Contractor contractor {
		replace about_contractor = 1 if strpos(abstract, "`x'") | strpos(title, "`x'") | strpos(simpletitle, "`x'")
	}
	
	gen drop_nonFarm = 0
	replace drop_nonFarm = 1 if !about_farm & !about_producer & !about_operation & !about_contractor
	
	tab drop_nonFarm
	
******************************************************************************
* Flag relevance to USA
******************************************************************************
	global usstates "States US U.S USA U.S.A USA America Alabama Alaska Arizona Arkansas California Colorado Connecticut Delaware Florida Georgia Hawaii Idaho Illinois Indiana Iowa Kansas Kentucky Louisiana Maine Maryland Massachusetts Michigan Minnesota Mississippi Missouri Montana Nebraska Nevada Hampshire Jersey Mexico York North Carolina Dakota Ohio Oklahoma Oregon Pennsylvania Rhode Island Carolina Dakota Tennessee Texas Utah Vermont Virginia Washington Wisconsin Wyoming u.s. usa u.s.a alabama alaska arizona arkansas california colorado connecticut delaware florida georgia hawaii idaho illinois indiana iowa kansas kentucky louisiana maine maryland massachusetts michigan minnesota mississippi missouri montana nebraska nevada hampshire jersey york carolina dakota ohio oklahoma oregon pennsylvania rhode carolina dakota tennessee texas utah vermont virginia washington virginia wisconsin wyoming"
	
	gen abstract_USA = 0
	gen geolocation_USA =0 // only for CAB
	gen publication_USA = 0
	gen title_USA = 0
	gen publish_USA = 0 // only for WOS
	gen countryofpub_USA = 0 // only for CAB
	foreach us in $usstates {
		replace abstract_USA = 1 if strpos(abstract, " `us' ")
		replace geolocation_USA = 1 if strpos(geographicallocations, "`us'")
		replace publication_USA = 1 if strpos(publication, "`us'")
		replace title_USA = 1 if strpos(title, "`us'") | strpos(simpletitle, "`us'")
		replace publish_USA = 1 if strpos(publisheraddress, "`us'")
		replace countryofpub_USA = 1 if strpos(countryofpublication, "`us'")
	}
	
	gen about_USA = 0
	replace about_USA = 1 if abstract_USA==1 | geolocation_USA==1 | title_USA==1
	
	* Generate dummies that flag relevance to a country other than the United States
	global uncountries "Euro EU E.U. Africa Asia Afghan Albania Algeria Andorra Angola Antigua Barbuda Argentina Armenia Australia Austria Azerbaijan Bahamas Bahrain Bangladesh Barbados Belarus Belgi Belize Benin Bhutan Bolivia Bosnia Herzegovina Botswana Brazil Brunei Bulgaria Burkina Burundi Cambodia Cameroon Canadi African Chad Chile China Colombia Comoros Congo Costa Rica Cote d'Ivoire Croatia Cuba Cyprus Czechia Congo Denmark Danish Djibouti Dominica Dominican Dutch Ecuador Egypt Salvador Guinea Eritrea Estonia Eswatini Ethiopia Fiji Finland France French Gabon Gambia German Ghana Greece Greek Grenada Guatemala Guinea Guinea-Bissau Guyana Haiti Honduras Hungar Iceland India Indonesia Iran Iraq Ireland Irish Israel Italy Italian Jamaica Japan Jordan Kazakhstan Kenya Kiribati Kuwait Kyrgyzstan Laos Latvia Lebanon Lesotho Liberia Libya Liechtenstein Lithuania Luxembourg Madagascar Malawi Malaysia Maldives Mali Malta Marshall Mauritania Mauritius Mexico Mexican Micronesia Monaco Mongolia Montenegro Morocco Mozambique Myanmar Namibia Nauru Nepal Netherlands Zealand Nicaragua Niger Nigeria Korea Macedonia Norw Oman Pakistan Palau Palestine Panama Papua Guinea Paraguay Peru Philippines Poland Portugal Portuguese Qatar  Moldova Romania Russia Rwanda Lucia Vincent Grenadines Samoa Marino Scotland Scottish Saudi Arabia Senegal Serbia Seychelles Sierra Leone Scandanav Singapore Slovakia Slovenia Solomon Somalia  Korea  Sudan Spain Spanish Lanka Suriname Sweden Switzerland Syria Tajikistan Tanzania Thailand Taiwan Timor-Leste Togo Tonga Trinidad Tobago Tunisia Turkey Turkmenistan Tuvalu Uganda Ukrain Arab Emirates Kingdom England UK U.K. Scotland Ireland Uruguay Uzbekistan Vanuatu Vatican Venezuela Vietnam Yemen Zambia Zimbabwe Czech Latin Berliner Polish euro eu e.u. africa asia afghan albania algeria andorra angola antigua barbuda argentina armenia australia austria azerbaijan bahamas bahrain bangladesh barbados belarus belgi belize benin bhutan bolivia bosnia herzegovina botswana brazil brunei bulgaria burkina burundi cambodia cameroon canadi african chad chile china colombia comoros congo costa rica cote d'ivoire croatia cuba cyprus czechia congo denmark danish djibouti dominica dominican dutch ecuador egypt salvador guinea eritrea estonia eswatini ethiopia fiji finland france french gabon gambia german ghana greece greek grenada guatemala guinea guinea-bissau guyana haiti honduras hungar iceland india indonesia iran iraq ireland irish israel italy italian jamaica japan jordan kazakhstan kenya kiribati kuwait kyrgyzstan laos latvia lebanon lesotho liberia libya liechtenstein lithuania luxembourg madagascar malawi malaysia maldives mali malta marshall mauritania mauritius mexico mexican micronesia monaco mongolia montenegro morocco mozambique myanmar namibia nauru nepal netherlands zealand nicaragua niger nigeria korea macedonia norw oman pakistan palau palestine panama papua guinea paraguay peru philippines poland portuguese qatar moldova romania russia rwanda lucia vincent grenadines samoa marino scotland scottish saudi arabia senegal serbia seychelles sierra leone scandanav singapore slovakia slovenia solomon somalia korea sudan spain spanish lanka suriname sweden switzerland syria tajikistan tanzania thailand taiwan timor-leste togo tonga trinidad tobago tunisia turkey turkmenistan tuvalu uganda ukrain arab emirates kingdom england uk u.k. scotland ireland uruguay uzbekistan vanuatu vatican venezuela vietnam yemen zambia zimbabwe czech latin berliner polish"

	
	gen abstract_notUSA = 0
	gen geolocation_notUSA =0 // only for CAB
	gen publication_notUSA = 0
	gen title_notUSA = 0
	gen publish_notUSA = 0 // only for WOS
	gen countryofpub_notUSA = 0 // only for CAB
	foreach x in $uncountries {
		replace abstract_notUSA = 1 if strpos(abstract, "`x'")
		replace geolocation_notUSA = 1 if strpos(geographicallocations, "`x'")
		replace publication_notUSA = 1 if strpos(publication, "`x'")
		replace title_notUSA = 1 if strpos(title, "`x'") | strpos(simpletitle, "`x'")
		replace publish_notUSA = 1 if strpos(publisheraddress, "`x'")
		replace countryofpub_notUSA = 1 if strpos(countryofpublication, "`x'")
	}

	
	gen nonUSA_flag = 0
	replace nonUSA_flag = 1 if publication_notUSA==1 | title_notUSA==1 |abstract_notUSA==1 | geolocation_USA==1 // How many are specified as being in a non-USA country and not specified as being in USA 
	
	tab about_USA nonUSA_flag
	
	* Generate indicator of which articles to drop (based on country)
	gen drop_nonUSA = 0
	replace drop_nonUSA = 1 if about_USA == 0 & nonUSA_flag == 1
	
******************************************************************************
* Categorize subject of publication (econ, bio, agriculture, medicine, etc)
******************************************************************************
	gen id = _n
	
	* Assign to every publication a count to determine its prevalence
	bysort publication: egen pub_count = count(id)
	sort pub_count publication
	order id publication pub_count title authors abstract
	
	* Most common publications are
	tab publication if pub_count >50
	
	* Flag different words
	gen pub_econ = 0
	foreach x in Econ econ Financ financ Manag Product Eurochoices Choices Policy Polit Behavior Trade {
		replace pub_econ = 1 if strpos(publication, "`x'")
	}
	gen pub_ag = 0
	foreach x in Agr culture Poultry Dairy Nutrition Crop Tillage Food One Feed Livestock Efsa Rural Ruminant Mljekarstvo Hort Buffalo Pig Lohmann Plant Legume Farm Pantnagar Reproduction Cattle Afbm Grassland Fish Fourrages Zuchtungskunde Geflugel Botan Husband Breed Bovin Meat Forag Broiler Housing Mastitis Swine Hen Dairy Cow Hog Pork Weed Seed Milk {
		replace pub_ag = 1 if strpos(publication, "`x'")
	}
	gen pub_geo = 0 
	foreach x in Geo Soil Catena Element Pedosphere Land Crystal {
		replace pub_geo = 1 if strpos(publication, "`x'")
	}
	gen pub_bio = 0
	foreach x in Bio bio Life organ Process Peerj Organ Organis FungiGenes Genet Animal Zoo Ornith Insect Bird Entomolog Etholog Membrane Gene {
		replace pub_bio = 1 if strpos(publication, "`x'")
	}
	gen pub_enviro = 0
	foreach x in Enviro Waste Ecol ecol Ecos ecos Renew Green Sustain Clean Energ Resourc Water Desalination Atmosphere Tropic Nematology Conserv Forest Hydrol Ecograph Climat Pollution Air Ocean Atmospher Compost {
		replace pub_enviro = 1 if strpos(publication, "`x'")
	}
	gen pub_med = 0
	foreach x in Health Med Vet vet Antibio antibio Pathogen Diseas Theriogenology Epidem Infect Pathology Parasit Razi Virus Microb Hygien Pharma pharma patholog Toxi Allerg Acarology Nutrient Endoc Dental Immun Cancer Tierarztliche Tieraerztliche Magyar {
		replace pub_med = 1 if strpos(publication, "`x'")
	}
	gen pub_engin = 0
	foreach x in Engin Asabe Asae Material {
		replace pub_engin = 1 if strpos(publication, "`x'")
	}
	gen pub_chem = 0
	foreach x in Chem chem Talanta Molecul Microchem {
		replace pub_chem = 1 if strpos(publication, "`x'")
	}
	gen pub_neuro = 0
	foreach x in Neuro {
		replace pub_neuro = 1 if strpos(publication, "`x'")
	}
	
	count if !pub_econ & !pub_ag & !pub_geo & !pub_bio & !pub_enviro & !pub_med & !pub_engin & !pub_chem & !pub_neuro & documenttype == "Journal article"
	// only 681 pub_article obs without a topic label. I'll take it. Most of them are not English journals
	
	foreach j in pub_econ pub_ag pub_geo pub_bio pub_enviro pub_med pub_engin pub_chem pub_neuro {
		tab `j'
	}
	
	* Create variable for pub_suject out of dummies
	// There is a little overlap between subject categories. In these cases, the latter "replace" takes precedent
	gen pub_subject = "Misc"
	replace pub_subject = "Biology" if pub_bio == 1
	replace pub_subject = "Agriculture" if pub_ag == 1
	replace pub_subject = "Medical" if pub_med == 1
	replace pub_subject = "Environment" if pub_enviro == 1
	replace pub_subject = "Geology" if pub_geo == 1
	replace pub_subject = "Engineering" if pub_engin == 1
	replace pub_subject = "Chemistry" if pub_chem == 1
	replace pub_subject = "Economics" if pub_econ == 1
	
	* Generate subject category for anything not yet captured
	gen pub_misc = 0
	replace pub_misc = 1 if pub_subject == "Misc"

******************************************************************************
* Categorize by original search term category
******************************************************************************
	gen term_category = ""
	replace term_category = "Mutilation" if regexm(search_terms, "dock|beak|tail|horn|disbud|teeth") >0
	replace term_category = "Outdoor Access" if regexm(search_terms, "access|organic|paddock|allin|grassfed|Grassfed|Humane|humane|Care|care|Welfare|welfare|better|Better|CH|Food|food|free_range|gap|GAP|One_Health|one_health|pasture") >0
	replace term_category = "Confinement" if regexm(search_terms, "floor|cool|hous|space|vent|aviary|curtain|hutch|corral|lot|parlor|stall|tether|crate|farrow|gestat|shade|cage|shelter") > 0
	replace term_category = "Enrichment" if regexm(search_terms, "light|nest|perch|takeoff|separat|period|wash|wean|proof|enrich|shackle|quality") > 0
	
	* Make dummies
	gen term_access = 0
	replace term_access = 1 if term_category == "Outdoor Access"
	gen term_confin = 0
	replace term_confin = 1 if term_category == "Confinement"
	gen term_enrich = 0
	replace term_enrich = 1 if term_category == "Enrichment"
	gen term_mutilat = 0
	replace term_mutilat = 1 if term_category == "Mutilation"
	
******************************************************************************
* Categorize by ex-ante factor (potential motivator/barrier) mentioned
******************************************************************************
	global about_adoption "Transition transition Adopt adopt Certif certif Convention convention Method method Practic practic Label label Factor factor Install install Implement implement Innovat innovat Barrier barrier Motivat motivat Incent incent Switch switch Solution solution"
	
	global factor_flag_econ "Cost|cost|Price|price|Uncertainty|uncertainty|Market|market|Credit|credit|Market power|market power|Collusion|collusion|Vertical integration|vertical integration|Contract|contract|Innovation|innovation|Margin|margin|Upkeep|upkeep|Fixed cost|fixed cost|Capital|capital|Consumer|consumer|Demand|demand|Suppl|suppl|Production|production|Profit|profit|Afford|afford|Risk|risk|Scal|scal|Utilit|utilit|Maximiz|maximiz"
	
	global factor_flag_social  "Status quo|status quo|Awareness|awareness|Availability|availability|Attitude|attitude|Perception|perception|Option|option|Local|local|Rural|rural|Urban|urban|Altruis|altruis}Network|network|Extention|extention"
	
	global factor_flag_geog "Farm size|farm size|per hectare|per acre|Hectare|hectare|Acre|acre|Credit|credit|Climat|climat|Temperat|temperat|Humidity|humidity|Irrigation|irrigation|Geograph|geograph|Elevation|elevation|Altitud|altitud|Latitud|latitud|Weather|weather|Heat|heat|Hot|hot|Warm|warm|Cold|cold|Dens|dens|Grass|grass"
	
	global factor_flag_med "Biosecur|biosecur|Diseas|diseas|Antibiot|antibiot|Prebiot|prebiot|Mortal|mortal|Death|death|Died|died|Deadly|deadly|Sick|sick|Immun|immun"
	
	global factor_flag_regul "BLM|Bureau of Land Management|Policy|policy|Law|law|Rul|rul|Lobby|lobby|Regulat|regulat|FDA|Food and Drug|USDA|Department of Ag|Dept. of Ag"

	gen abstract_adoption = 0
	foreach x in $about_adoption {
		replace abstract_adoption = 1 if strpos(abstract, "`x'")
	}
	gen title_adoption = 0
	foreach x in $about_adoption {
		replace title_adoption = 1 if strpos(title, "`x'") | strpos(simpletitle, "`x'")
	}
	tab abstract_adoption title_adoption
	
	gen drop_nonAdopt = 0
	replace drop_nonAdopt = 1 if !abstract_adoption & !title_adoption
	replace drop_nonAdopt = 1 if !title_adoption & abstract ==""
	
	// br if abstract_adoption & !regexm(abstract,"Transition|transition|Adopt|adopt|Certif|certif|Convention|convention|Label|label")
	
	gen abstract_econ = regexm(abstract, "$factor_flag_econ")
	gen abstract_social = regexm(abstract, "$factor_flag_social")
	gen abstract_geog = regexm(abstract, "$factor_flag_geog")
	gen abstract_med = regexm(abstract, "$factor_flag_med")
	gen abstract_regul = regexm(abstract, "$factor_flag_regul")
	
	foreach x in econ social geo med regul {
		tab abstract_`x'
	}
	
	count if !abstract_adoption & !abstract_econ & !abstract_social & !abstract_geo & !abstract_regul
	
******************************************************************************
* Flag quantitative research
*****************************************************************************
	global quant_flag "Effect effect Times times Percent percent More more Less less Fraction fraction Indicat indicat Result result Quanti quanti Likelihood likelihood Probability probability Magnitude magnitude Measur measure Correlat correlat Findings findings"
	
	gen abstract_quant = 0
	foreach x in $quant_flag {
		replace abstract_quant = 1 if strpos(abstract, "`x'")
	}
	
	tab abstract_quant
	
******************************************************************************
* Flag those without abstracts
*****************************************************************************
	gen miss_abst = 0
	replace miss_abst = 1 if abstract==""

	// For some reason, there used to be a drop id and gen id =_n here and that was messing up the id consistency
	order id
	save  "${datadir}\clean_data\all_categorized.dta", replace
	
	
******************************************************************************
* Many many non-abstract papers will get cut. Where do they get cut?
*****************************************************************************
	tab miss_abst if drop_nonPCH==1
	tab miss_abst if drop_nonUSA==1
	tab miss_abst if drop_nonAdopt==1
	tab miss_abst if drop_nonFarm==1
	
	tab drop_nonPCH if miss_abst==1
	tab drop_nonUSA if miss_abst==1
	tab drop_nonAdopt if miss_abst==1
	tab drop_nonFarm if miss_abst==1
	
	// They definitely are getting dropped at nonAdopt and nonFarm. Like 80% of non-abstract papers don't meet either criteria. And this makes sense, I believe, since these kinds of words aren't mentioned as often in titles as in abstracts
	
******************************************************************************
* Make Excel sheets of title, abstract, publication, authors that are dropped
*****************************************************************************	
	drop if drop_nonPCH==1 | drop_nonUSA==1
	order id title publication authors abstract doi drop_nonPCH drop_nonUSA nonUSA_flag pub_subject term_category species
	
// 	preserve
// 		drop if drop_nonFarm
// 		export excel using "${datadir}\double_check\only_nonAdopt.xls" if  drop_nonAdopt, firstrow(variables) replace
// 	restore
//	
// 	preserve
// 		drop if drop_nonAdopt
// 		export excel using "${datadir}\double_check\only_nonFarm.xls" if  drop_nonFarm, firstrow(variables) replace
// 		export excel using "${datadir}\double_check\currently_kept.xls" if  drop_nonFarm ==0, firstrow(variables) replace
// 	restore
	
	* Make data for LDA (Python) categorization
	keep id title publication authors abstract doi drop_nonAdopt drop_nonFarm miss_abst search_engine pub_subject term_category species
	
	preserve

// 	export excel using "${datadir}\double_check\LDA_currently_kept.xls", firstrow(variables) replace
	export excel using "${jupdir}\LDA_Abstracts.xls" if !miss_abst, firstrow(variables) replace
	export excel using "${jupdir}\LDA_NoAbstract.xls" if miss_abst, firstrow(variables) replace
	restore
	
	