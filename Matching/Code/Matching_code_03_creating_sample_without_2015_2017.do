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

* importing the matching dataset
	
	use "Matching/Output/Matching_output_code_01_comparison_group.dta"
	
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
	
	//translate @Results "Matching/Output/output_code_03_simple_comparison.txt", replace
	