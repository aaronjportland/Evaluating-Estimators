********************************************************************************
* Date: 07/10/2023
* Author: Gabriela Monteiro Avelino
*
*	Code 03: Creating the sample for the matching (replacing experimental
* 			controls with the comparison group) and merging with RAIS 2015-2017
*
*===============================================================================
*	Part 0: Settings
*===============================================================================

	clear all
	
* setting the work directory

	cd "/Users/aaronjoseph/Downloads/Capstone/Felipe"
	
*===============================================================================
*	Part 1: Merging with RAIS data from 2015 to 2017
*===============================================================================	

* importing the dataset with more RAIS information

	import excel "Matching/Output/firms_matching_RAIS_2015_2017.xlsx", firstrow clear
	
	drop treatment_assignment matching_comparison_group
	
* merging with the full database
	
	merge 1:1 firm_id using "Matching/Output/Matching_output_code_01_comparison_group.dta"
	
*-------------------------------------------------------------------------------
*** eliminating existing RAIS 2015 information that is incomplete --------------
*-------------------------------------------------------------------------------
	
/* there are two variables in the database that came from RAIS 2015, but they have
many more cases of missing information than what I found when I looked into RAIS
2015 myself. Probably because this information was collected by merging only 
SSE 2015 with RAIS. Since my information is more complete (I merged RAIS with the
full 2015-2018 SSE population), I will use the variable that I collected myself. */

	tab number_employees_RAIS_2015 number_of_employees_2015, missing
	
	drop number_of_employees_2015 zero_employees_2015
	
*===============================================================================
*	Part 2: Creating the sample (dropping experimental controls)
*===============================================================================

* dropping the experimental controls

	drop if treatment_assignment == 0
	
* creating the binary treatment variable

	g treatment_assignment_binary = .

	replace	treatment_assignment_binary = 0 if treatment_assignment == .
			
	recode treatment_assignment_binary (.=1)

*===============================================================================
*	Part 3: Saving the product of the code
*===============================================================================	

	save "Matching/Output/Matching_output_code_03_sample.dta", replace
	
*===============================================================================
*	Part 4: Simple comparison between treated and controls
*===============================================================================	
	
* there is a positive and statistically significant selection bias
	
	regress business_practices_sum_2019 treatment_assignment_binary, robust
	
* saving the results
	
	translate @Results "Matching/Output/output_code_03_simple_comparison.txt", replace
	