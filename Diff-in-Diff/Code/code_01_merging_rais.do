********************************************************************************
* Date: 08/15/2025
* Author: Felipe Oliveira
*
*	Code 04: Merging RAIS data into main dataset
*
*===============================================================================
*	Part 0: Settings
*===============================================================================

* clear all
cd "/Users/aaronjoseph/Downloads/Capstone/Felipe"

* Load the main Sebrae sample
use "Matching/Output/Matching_output_code_03_sample.dta", clear
drop number_of_employees_2017 number_employees_RAIS_2016 number_of_employees_2015

* Save just the firm IDs from the Sebrae sample for subsetting
tempfile sample_ids
keep firm_id
duplicates drop
save `sample_ids'

* Loop over the years and merge more efficiently. Keeping 2016 out because it's already in the SSE data
foreach year of numlist 2015 2017 2018 2019 {
    
    * Restrict the using dataset before merge
    use "Experiment/Output/output_code_01g_rais_`year'.dta", clear
    merge 1:1 firm_id using `sample_ids'
    keep if _merge == 3   // keep only matched firm_ids
    drop _merge
    tempfile rais_`year'
    save `rais_`year''
    
    * Merge into the main dataset
    use "Matching/Output/Matching_output_code_03_sample.dta", clear
    merge 1:1 firm_id using `rais_`year'', gen(merge_rais_`year')
	save "Matching/Output/Matching_output_code_03_sample.dta", replace
}

* Final save
save "Diff-in-Diff/Output/output_code_01_diff_sample.dta", replace
