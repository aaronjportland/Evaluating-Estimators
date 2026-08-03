* Date: 07/10/2025
* Author: Felipe Oliveira
*
*	Code 04b: Coarsened Exact Matching (CEM)
*
*===============================================================================
*	Part 0: Settings
*===============================================================================

	clear all

* setting the work directory

	cd "/Users/aaronjoseph/Downloads/Capstone/Felipe"

* importing the sample

	use "Matching/Output/Matching_output_code_03_sample.dta", clear

*===============================================================================
*	Part 1: Performing Coarsened Exact Matching
*===============================================================================

* list of covariates (put your full list here)
local covs respondent_age_2018 respondent_gender_2018 ///
    business_practices_sum_2018 years_functioning_2018 ///
    competition_density_full_zipco total_services_2015_2018 ///
    respondent_owner_2018 number_employees_RAIS_2016 ///
    sse_2018_only
	
regress treatment_assignment_binary `covs', robust


tabulate sebrae_regional_office_2018, generate(reg_office)
tabulate sebrae_strategic_business_sector, generate(sector)


* The 'cem' command automatically coarsens the variables and performs matching.
* You need to specify the treatment variable and the covariates to be matched.
* I removed the variables that did not strongly predict treatment

	cem respondent_gender_2018 ///
    business_practices_sum_2018 ///
    total_services_2015_2018 ///
    number_employees_RAIS_2016, ///
	treatment(treatment_assignment_binary)

	//reg_office1 reg_office2 reg_office3 reg_office4 reg_office5 reg_office6 ///
	//sector1 sector2 sector3 sector4 sector5 sector6 sector7 sector8 sector9 sector10, ///

*===============================================================================
*	Balance Checks
*===============================================================================

keep if cem_matched == 1

* 2) Post-match (weighted by cem_weights) standardized differences and graph
	iebaltab respondent_gender_2018 ///
    business_practices_sum_2018 ///
    total_services_2015_2018 ///
    number_employees_RAIS_2016, ///
	groupvar(treatment_assignment_binary) ///
	savexlsx("Matching/Output/output_code_06_balance_test_cem.xlsx") ///
	grplabels("0 Control @ 1 Treatment") ///
	ftest ///
	replace

	

* Now, run the regression on the matched sample to estimate the treatment effect.
* 'cem' adds a weight variable `_cem_weights` that must be used in the regression.

	regress business_practices_sum_2019 treatment_assignment_binary [iweight=cem_weights], robust

*===============================================================================
*	Part 2: Saving the results
*===============================================================================

	//translate @Results "Matching/Output/output_code_04b_coarsened_exact_matching.txt", replace
	
	* Store it in memory
estimates store cem_itt

* Save it to disk
estimates save "Matching/Output/output_code_06_coarsened_exact_matching.ster", replace
