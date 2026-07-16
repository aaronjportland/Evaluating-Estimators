********************************************************************************
* Date: 12/06/2023
* Author: Gabriela Monteiro Avelino
*
*	Code 01b: Population for the non-experimental evaluation of the 
*				2018 experiment (fuzzy RD)
*
*===============================================================================
*	Part 0: Settings
*===============================================================================

* setting the work directory

	cd "/Users/aaronjoseph/Downloads/Capstone/Felipe"
	
* importing the experimental sample

	use "RDD/Data/output_code_05_sample.dta", clear
	
*===============================================================================
*	Part 1: Identifying treatment assignment
*===============================================================================		
	
	keep firm_id treatment_assignment
	
	merge 1:1 firm_id using "RDD/Data/output_code_04_full_population_sse_2015_2018.dta"
	
	drop _merge
	
*===============================================================================
*	Part 2: Selecting the population that will be used in the fuzzy RD
*===============================================================================	
		
/*
Criteria for being in the RDD sample: 
1) firm is in SSE 2018 and answered WBG survey in 2018;
2) firm appears in RAIS 2016 and is active;
3) firm has between 8 and 13 employees;
4) not having scored 100% (23);
5) not having been treated in the 2017 experiment.
*/	
	
	keep if	merge_survey_WBG_2018 == 3 & /// 
			appears_in_RAIS_2016 == 1 & /// 
			number_employees_RAIS_2016 >= 8 & ///
			number_employees_RAIS_2016 <= 13 & /// 
			business_practices_sum_2018 <= 22 & ///
			treated_impact_evaluation_2017 != 1
	
	tabulate number_employees_RAIS_2016

*===============================================================================
*	Part 3: Creating the instrument (fuzzy RD)
*===============================================================================	

/* 
the running variable is the number of employees and the instrumental variable
for the fuzzy RD is a binary variable with value 1 if the firm has up to 10
employees and 0 otherwise. firms with this instrumental variable equal to zero 
make up the new comparison group.
*/

* creating the treatment assignment dummy

	g treatment_assignment_dummy = 1
	
	replace treatment_assignment_dummy = 0 if treatment_assignment == . | ///
												treatment_assignment == 0

* creating instrumental variable for the fuzzy RD

	g instrument_fuzzy_RD = 0 if treatment_assignment ==.
	
	replace instrument_fuzzy_RD = 1 if instrument_fuzzy_RD != 0
	
*===============================================================================
*	Part 4: Adjusting variables to make coefficients interpretable
*===============================================================================	

* recoding gender

	recode respondent_gender_2018 (2=0)
	
	label values respondent_gender_2018 .
	
	label drop respondent_gender_2018
	
	label define respondent_gender_2018 ///
					1 "Female" ///
					0 "Male"
					
	label values respondent_gender_2018 respondent_gender_2018
	
/* adjusting the "number of employees" variable (i.e., subtracting the cutoff) 
to make the coefficient comparable to the RCT result */
	
	g number_employees_recentered = number_employees_RAIS_2016 - 10

*-------------------------------------------------------------------------------
*** creating dummies -----------------------------------------------------------
*-------------------------------------------------------------------------------

* respondent's type

	tab respondent_type_2018, gen(respondent_type_2018_dum)
	
	rename respondent_type_2018_dum1 respondent_manager_2018
	label variable respondent_manager_2018 "Respondent is the manager"
	
	rename respondent_type_2018_dum2 respondent_owner_2018
	label variable respondent_owner_2018 "Respondent is the owner/partner"
	
	rename respondent_type_2018_dum3 respondent_representative_2018
	label variable respondent_representative_2018 "Respondent is a representative of the firm"
	
* respondent's level of education

	tab Q1_respondent_educ_level_2018, gen(respondent_educ_level_2018_dum)
	
	rename respondent_educ_level_2018_dum1 respond_middle_scho_incomp_2018
	label variable respond_middle_scho_incomp_2018 "Respondent didn't finish middle school (may or may not have finished elementary school)"
	
	rename respondent_educ_level_2018_dum2 respond_middle_school_comp_2018
	label variable respond_middle_school_comp_2018 "Respondent finished middle school"
	
	rename respondent_educ_level_2018_dum3 respond_high_school_incomp_2018
	label variable respond_high_school_incomp_2018 "Respondent didn't finish high school"
	
	rename respondent_educ_level_2018_dum4 respond_high_school_comp_2018
	label variable respond_high_school_comp_2018 "Respondent finished high school"
	
	rename respondent_educ_level_2018_dum5 respond_college_incomp_2018
	label variable respond_college_incomp_2018 "Respondent didn't finish college"
	
	rename respondent_educ_level_2018_dum6 respond_college_comp_2018
	label variable respond_college_comp_2018 "Respondent finished college"
	
	rename respondent_educ_level_2018_dum7 respond_grad_school_incomp_2018
	label variable respond_grad_school_incomp_2018 "Respondent didn't finish graduate school"
	
	rename respondent_educ_level_2018_dum8 respond_grad_school_comp_2018
	label variable respond_grad_school_comp_2018 "Respondent finished graduate school"
	
* respondent's business experience

	tab Q2_respondent_busin_experi_2018, gen(respond_busin_experi_2018_dum)
	
	label variable respond_busin_experi_2018_dum1 "Respondent's business experience: up to 2 years"
	
	label variable respond_busin_experi_2018_dum2 "Respondent's business experience: from 3 to 5 years"
	
	label variable respond_busin_experi_2018_dum3 "Respondent's business experience: from 6 to 10 years"
	
	label variable respond_busin_experi_2018_dum4 "Respondent's business experience: more than 10 years"

* respondent's risk aversion

	g respondent_risk_averse_dum = 0
	
	replace respondent_risk_averse_dum = 1 if Q13_respondent_risk_averse_2018 == 3 | ///
										Q13_respondent_risk_averse_2018 == 4
										
	label define respondent_risk_averse_dum ///
				1 "Not inclined to take risks" ///
				0 "Inclined to take risks"
				
	label values respondent_risk_averse_dum respondent_risk_averse_dum
	
* sharing of managerial tasks within the firm

	g Q3_task_distribution_2018_dum = 0
	replace Q3_task_distribution_2018_dum = 1 if Q3_task_distribution_2018 == 1
	
	label define Q3_task_distribution_2018_dum ///
					1 "Owner is solely responsible for managerial tasks" ///
					0 "Managerial tasks are shared between the owner and employees"
					
	label values Q3_task_distribution_2018_dum Q3_task_distribution_2018_dum
	
*===============================================================================
*	Part 5: Identifying missing information
*===============================================================================

* identifying missing information

* ssc install nmissing

	nmissing Q1_respondent_educ_level_2018 Q2_respondent_busin_experi_2018 ///
				years_functioning_2018 respondent_type_2018 ///
				business_practices_sum_2018 ///
				respondent_gender_2018 respondent_age_2018 ///
				total_services_2015_2018 competition_density_full_zipco ///
				Q13_respondent_risk_averse_2018
				
	foreach var of any `r(varlist)' {
		
	g `var'_miss = 1 if `var'==. 
	recode `var'_miss (.=0)

	}

/* only total use of Sebrae services between 2015 and 2018 has missing values,
but actually it is not missing, it's zero. */

* replacing missing information for 0

	recode total_services_2015_2018 (.=0)
	
*===============================================================================
*	Part 6: Saving the product of this code
*===============================================================================

	save "RDD/Output/RDD_output_code_01b_fuzzy_RD_sample.dta", replace
	