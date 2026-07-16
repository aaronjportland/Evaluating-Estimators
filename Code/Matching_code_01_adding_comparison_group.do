********************************************************************************
* Matching_code_01_adding_comparison_group.do
* Date: 07/10/2023
* Author: Gabriela Monteiro Avelino
*
*	Code 01: Adding the comparison group for the non-experimental evaluation of the 
*				2018 experiment (Matching)
*
*===============================================================================
*	Part 0: Settings
*===============================================================================

* setting the work directory

	cd "/Users/aaronjoseph/Downloads/Capstone/Felipe"
	
* importing the experimental sample

	use "Matching/Data/output_code_05_sample.dta", clear

*===============================================================================
*	Part 1: Identifying treatment assignment
*===============================================================================		
	
	keep firm_id treatment_assignment
	
	merge 1:1 firm_id using "Matching/Data/output_code_04_full_population_sse_2015_2018.dta"
	
	drop _merge
	
*===============================================================================
*	Part 2: Selecting the population that will be used in the matching
*===============================================================================	
	
	keep if	appears_in_RAIS_2016 == 1 & /// 
			number_employees_RAIS_2016 > 0 & ///
			number_employees_RAIS_2016 <= 10 & /// 
			business_practices_sum_2018 <= 22 & ///
			treated_impact_evaluation_2017 != 1
	
	g 				matching_comparison_group = .
	label variable	matching_comparison_group "Comparison group for matching"

	replace	matching_comparison_group = 1 if merge_survey_WBG_2018 == 1
			
	recode matching_comparison_group (.=0)

	label define matching_comparison_group ///
					1 "Comparison group for matching" ///
					0 "Firms in the experimental sample"
					
	label values matching_comparison_group matching_comparison_group

*===============================================================================
*	Part 3: Adjusting variables to make coefficients interpretable
*===============================================================================	

* recoding gender

	recode respondent_gender_2018 (2=0)
	
	label values respondent_gender_2018 .
	
	label drop respondent_gender_2018
	
	label define respondent_gender_2018 ///
					1 "Female" ///
					0 "Male"
					
	label values respondent_gender_2018 respondent_gender_2018

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
	
* creating new city variable

	gen firm_city_2018_clean = ustrupper(ustrregexra ///
											(ustrnormalize(firm_city_2018, "nfd"), ///
																"/p{Mark}", ""))
																
	destring firm_city_2018_clean, replace
	
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
	
* answering the WBG survey

	recode merge_survey_WBG_2018 (1=0) (3=1)
	
	label define merge_survey_WBG_2018_new ///
			0 "Firms in SSE 2018 who did not answer WBG survey" ///
			1 "Firms who are in SSE 2018 and answered the WBG survey"
			
	label values merge_survey_WBG_2018 merge_survey_WBG_2018_new

* Sebrae services take-up

	recode  merge_sebrae_services_2015_2018 (1=0) (3=1)
	
	label define merge_sebrae_services_new ///
			0 "Firms in SSE 2018 who did not get a service from Sebrae between 2015 and 2018" ///
			1 "Firms in SSE 2018 who got a service from Sebrae between 2015 and 2018"
	
	label values merge_sebrae_services_2015_2018 merge_sebrae_services_new

/* total use of Sebrae services between 2015 and 2018 has missing values,
but actually it is not missing, it's zero. */

* replacing missing information for 0

	recode total_services_2015_2018 (.=0)
	
* recoding firm size

	recode size_2018 (2=0)
	
* firm is only found in SSE 2018
	
	g sse_2018_only = 1 if merge_SSE_editions == 4
	
	recode sse_2018_only (.=0)
	
*===============================================================================
*	Part 4: Saving the product of the code
*===============================================================================	

	save "Matching/Output/Matching_output_code_01_comparison_group.dta", replace
