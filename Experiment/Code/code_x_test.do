********************************************************************************
* Date: 10/06/2023
* Author: Gabriela Monteiro Avelino
*
*	Code 04: Merging databases to create the population of firms for sampling
*
*===============================================================================
*	Part 0: Settings
*===============================================================================

clear all

* setting the work directory

	cd "/Users/aaronjoseph/Downloads/Capstone/Felipe"
	
use "Matching/Output/Matching_output_code_03_sample.dta", clear 
  

drop number_of_employees_2017 

  
* Remove any leftover merge indicators from a prior run 

capture drop merge_rais_2017 

capture drop merge_rais_2018 

capture drop merge_rais_2019 

  

foreach year of numlist 2017/2019 { 

    merge 1:1 firm_id using "Experiment/Output/output_code_01g_rais_`year'.dta", gen(merge_rais_`year') 

    drop if (merge_rais_`year' == 2) 

} 

  
use "dataset1.dta", clear
compress
save "dataset1_compressed.dta", replace

save "test_new_rais.dta", replace 

 