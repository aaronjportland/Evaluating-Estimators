********************************************************************************
* Date: 07/10/2023
* Author: Gabriela Monteiro Avelino
*
*	Code 05a: Propensity score matching using LASSO and only RAIS 2016
*
*===============================================================================
*	Part 0: Settings
*===============================================================================
	
	clear all
	
* setting the work directory

	cd "/Users/aaronjoseph/Downloads/Capstone/Felipe"
	
* importing the sample

	use "Matching/Output/Matching_output_code_03_sample.dta", clear
	
set seed 12345
*===============================================================================
*	Part 1: Performing propensity score matching with LASSO
*===============================================================================	

tabulate sebrae_regional_office_2018, generate(reg_office)
tabulate sebrae_strategic_business_sector, generate(sector)

	local covariates respondent_age_2018 respondent_gender_2018 ///
							business_practices_sum_2018 years_functioning_2018 ///
							competition_density_full_zipco total_services_2015_2018 ///
							respondent_owner_2018 number_employees_RAIS_2016 sse_2018_only ///
							 reg_office2 reg_office3 reg_office4 reg_office5 reg_office6 ///
							 sector2 sector3 sector4 sector5 sector6 sector7 sector8 sector10
							
* which variables have predictive power?
	
	xi: lasso logit treatment_assignment_binary `covariates'			
	
	lassocoef, display(coef)
	
* LASSO picks up 22 of 22 variables
	
*-------------------------------------------------------------------------------
*** generating propensity scores -----------------------------------------------
*-------------------------------------------------------------------------------

	predict ps
	
	twoway (kdensity ps if treatment_assignment_binary==1) (kdensity ps if treatment_assignment_binary==0), legend(label(1 "treated") label(2 "controls"))

*-------------------------------------------------------------------------------
*** propensity score matching --------------------------------------------------
*-------------------------------------------------------------------------------		

*ssc install psmatch2

	gen logitscore = logit(ps)

	sum logitscore /*Std Dev is 1, so use caliper 0.2 */

	local cal = r(sd)*0.2

	disp `cal'

	psmatch2 treatment_assignment_binary, pscore(logitscore) cal(`cal') noreplacement
	
*-------------------------------------------------------------------------------
*** Balance check --------------------------------------------------
*-------------------------------------------------------------------------------	
psgraph

* Balance check: standardized bias before/after matching
pstest `covariates', ///
       both graph

	keep if _weight == 1
	
* Balance check
	iebaltab `covariates', groupvar(treatment_assignment_binary) ///
	savexlsx("Matching/Output/output_code_05a_balance_check_LASSO_pscore.xlsx") ///
	grplabels("0 Control @ 1 Treatment") ///
	ftest ///
	replace

	regress business_practices_sum_2019 treatment_assignment_binary, robust
	
*===============================================================================
*	Part 2: Saving the results
*===============================================================================
	
	*translate @Results "Matching/Output/output_code_05a_LASSO_propensity_score_matching_RAIS_2016.txt", replace
	
		* Store it in memory
estimates store lpsm_itt

* Save it to disk
estimates save "Matching/Output/output_code_05a_LASSO_propensity_score_matching_RAIS_2016.ster", replace
