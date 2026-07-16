********************************************************************************
* Date: 07/10/2023
* Author: Gabriela Monteiro Avelino
*
*	Code 04a: Propensity score matching with only RAIS 2016 + Balance Checks
*
*===============================================================================
*	Part 0: Settings
*===============================================================================

    clear all
	
set seed 12345

* setting the work directory

	cd "/Users/aaronjoseph/Downloads/Capstone/Felipe"
	
* importing the sample
	use "Matching/Output/Matching_output_code_03_sample.dta", clear
	
	
*===============================================================================
*	Part 0: Naive regression without matching
*===============================================================================
	
	* there is a positive and statistically significant selection bias
	
	regress business_practices_sum_2019 treatment_assignment_binary, robust
	
	* Store it in memory
	estimates store naive_itt

	* Save it to disk
	estimates save "Matching/Output/output_code_04a_naive_RAIS_2016_itt.ster", replace
*===============================================================================
*	Part 1: Performing propensity score matching
*===============================================================================
* st0026_2 from http://www.stata-journal.com/software/sj5-3

	tabulate sebrae_regional_office_2018, generate(reg_office)
tabulate sebrae_strategic_business_sector, generate(sector)

	local covariates respondent_age_2018 respondent_gender_2018 ///
							business_practices_sum_2018 years_functioning_2018 ///
							competition_density_full_zipco total_services_2015_2018 ///
							number_employees_RAIS_2016 sse_2018_only ///
							 reg_office2 reg_office3 reg_office4 reg_office5 reg_office6 ///
							 sector2 sector3 sector4 sector5 sector6 sector7 sector8 sector10 // sector 9 removed because it is always 0 across treatment and control
							 
							
	
 regress treatment_assignment_binary `covariates' //, robust

	xi: pscore treatment_assignment_binary `covariates', pscore(score)
	
	* Propensity score distribution plot
	twoway (kdensity score if treatment_assignment_binary==1) ///
	       (kdensity score if treatment_assignment_binary==0), ///
	       legend(label(1 "treated") label(2 "controls"))
		   

*-------------------------------------------------------------------------------
*** propensity score matching --------------------------------------------------
*-------------------------------------------------------------------------------
	gen logitscore = logit(score)

	sum logitscore /*Std Dev is 1, so use caliper 0.2 */
	local cal = r(sd)*0.2
	disp `cal'
	


* Run matching
psmatch2 treatment_assignment_binary, ///
    pscore(logitscore) cal(`cal') noreplacement ///
	neighbor(1) ///
    common ///
	

// psgraph
//
// * Balance check: standardized bias before/after matching
// pstest `covariates', both graph

	* Keep only matched sample
	keep if _w==1
	
	iebaltab `covariates', groupvar(treatment_assignment_binary) ///
	savexlsx("Matching/Output/output_code_04a_balance_test_pscore.xlsx") ///
	grplabels("0 Control @ 1 Treatment") ///
	ftest ///
	replace

*===============================================================================
*	Part 1.1: Post-matching descriptive checks
*===============================================================================
// 	* Quick t-tests for equality of means (matched sample)
// 	foreach var in respondent_age_2018 respondent_gender_2018 ///
// 		business_practices_sum_2018 years_functioning_2018 ///
// 		competition_density_full_zipco total_services_2015_2018 ///
// 		respondent_owner_2018 number_employees_RAIS_2016 ///
// 		sse_2018_only {
// 			ttest `var', by(treatment_assignment_binary)
// 	}
//
// 	* Alternative: summarize by treatment status
// 	bysort treatment_assignment_binary: summarize respondent_age_2018 ///
// 		respondent_gender_2018 business_practices_sum_2018 ///
// 		years_functioning_2018 competition_density_full_zipco ///
// 		total_services_2015_2018 respondent_owner_2018 ///
// 		number_employees_RAIS_2016 sse_2018_only

*===============================================================================
*	Part 2: Outcome regression (on matched sample)
*===============================================================================
	regress business_practices_sum_2019 treatment_assignment_binary, robust

	* Store it in memory
	estimates store psmatching_itt

	* Save it to disk
	estimates save "Matching/Output/output_code_04a_propensity_score_matching_RAIS_2016_itt.ster", replace
