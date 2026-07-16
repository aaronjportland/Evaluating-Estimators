********************************************************************************
* Date: 07/08/2025
* Author: Felipe Oliveira
*
* Code 07: Nearest Neighbor Matching (Euclidean) with teffects nnmatch
********************************************************************************

*===============================================================================
* Part 0: Setup
*===============================================================================

	clear all
	set more off
	
* Set working directory
	cd "/Users/aaronjoseph/Downloads/Capstone/Felipe"

* Load sample data
	use "Matching/Output/Matching_output_code_03_sample.dta", clear

*===============================================================================
* Part 1: Create dummy variables for categorical variables
*===============================================================================

	tabulate sebrae_regional_office_2018, generate(reg_office)
	tabulate sebrae_strategic_business_sector, generate(sector)

// * Exclude base categories
// 	ds reg_office*
// 	local reg_dummies: list varlist - reg_office1
//
// 	ds sector*
// 	local sector_dummies: list varlist - sector1

* List covariates
	local covariates respondent_age_2018 respondent_gender_2018 ///
		business_practices_sum_2018 years_functioning_2018 ///
		competition_density_full_zipco total_services_2015_2018 ///
		 number_employees_RAIS_2016 /// removed respondent_owner_2018 because it is 0 between treatment and control
		sse_2018_only ///
		 reg_office2 reg_office3 reg_office4 reg_office5 reg_office6 ///
		 sector2 sector3 sector4 sector5 sector6 sector7 sector8 sector9 sector10

*===============================================================================
* Part 2: Run nearest neighbor matching with teffects
*===============================================================================

	* Estimate ATT using 1-to-1 nearest neighbor matching (Euclidean)
	label variable treatment_assignment_binary "treatment_assignment_binary"
	teffects nnmatch (business_practices_sum_2019 `covariates') (treatment_assignment_binary), ///
		metric(euclidean) nneighbor(1) ///
		atet generate(match)
		
	tebalance summarize `covariates'
	
	* Extract the weights assigned by teffects nnmatch
	

*===============================================================================
* Part 3: Save results
*===============================================================================

	* Optional: Save matched sample weights
	//predict nn_weight
save "Matching/Output/output_code_07_teffects_nnmatch_RAIS_2016.dta", replace

	* Store it in memory
estimates store euclidean_itt

* Save it to disk
estimates save "Matching/Output/output_code_07_teffects_nnmatch_RAIS_2016.ster", replace


********************************************************************************
* Balance Tests
********************************************************************************
** Rebuilding matched dataset
gen ob=_n //store the observation numbers for future use
save "Matching/Output/output_code_07_intermediate_fulldata.dta",replace // save the complete data set

keep if treatment_assignment_binary // keep just the treated group
keep match1 // keep just the match1 variable (the observation numbers of their matches)
bysort match1: gen _weight=_N // count how many times each control observation is a match
by match1: keep if _n==1 // keep just one row per control observation
ren match1 ob //rename for merging purposes

quietly merge 1:m ob using "Matching/Output/output_code_07_intermediate_fulldata.dta" // merge back into the full data
replace _weight=1 if treatment_assignment_binary // set weight to 1 for treated observations
	
** BALANCE TESTS
iebaltab `covariates' [fweight=_weight], groupvar(treatment_assignment_binary) ///
savexlsx("Matching/Output/output_code_07_balance_test_nn.xlsx") ///
grplabels("0 Control @ 1 Treatment") ///
ftest ///
replace
