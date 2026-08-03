********************************************************************************
* Date: 07/10/2023
* Author: Gabriela Monteiro Avelino
*
*	Code 04b: Propensity score matching with RAIS 2015, 2016 and 2017
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
*	Part 1: Performing propensity score matching
*===============================================================================	
	
	xi: pscore treatment_assignment_binary respondent_age_2018 respondent_gender_2018 ///
							business_practices_sum_2018 years_functioning_2018 ///
							competition_density_full_zipco total_services_2015_2018 ///
							respondent_owner_2018 number_employees_RAIS_2016 /// 
							sse_2018_only i.sebrae_regional_office_2018 ///
							i.sebrae_strategic_business_sector number_employees_RAIS_2015 ///
							number_employees_RAIS_2017, pscore(score)
	
	twoway (kdensity score if treatment_assignment_binary==1) (kdensity score if treatment_assignment_binary==0), legend(label(1 "treated") label(2 "controls"))
	
*-------------------------------------------------------------------------------
*** propensity score matching --------------------------------------------------
*-------------------------------------------------------------------------------
	
	gen logitscore = logit(score)

	sum logitscore /*Std Dev is 1, so use caliper 0.2 */

	local cal = r(sd)*0.2

	disp `cal'

	psmatch2 treatment_assignment_binary, pscore(logitscore) cal(`cal') noreplacement

	keep if _w==1

	regress business_practices_sum_2019 treatment_assignment_binary, robust	
	
*===============================================================================
*	Part 2: Saving the results
*===============================================================================
	
	translate @Results "Matching/Output/output_code_04b_propensity_score_matching_RAIS_2015-17.txt", replace
