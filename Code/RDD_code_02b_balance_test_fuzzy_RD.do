********************************************************************************
* Date: 07/07/2023
* Author: Gabriela Monteiro Avelino
*
*	Code 02b: Balance test for the fuzzy RD estimation
*
*===============================================================================
*	Part 0: Settings
*===============================================================================

* setting the work directory

	cd "/Users/aaronjoseph/Downloads/Capstone/Felipe"	
	
* importing the RDD sample

	use "RDD/Output/RDD_output_code_01b_fuzzy_RD_sample.dta", clear
	
*===============================================================================
*	Part 1: Checking for differential attrition
*===============================================================================

	iebaltab 	attrition_outcome_sse_19, /// 
			grpvar(instrument_fuzzy_RD) ///       
			vce(robust) ///
			grplabels("0 Control @ 1 Treatment") ///
			rowlabel  ///
			("attrition_outcome_sse_19 Attrition in SSE 2019") ///
		 savexlsx("RDD/Output/RDD_output_code_02b_differential_attrition_fuzzy_RD") ///    
		 replace onerow ftest nonote	
	
*===============================================================================
*	Part 2: Balance test
*===============================================================================
 
*-------------------------------------------------------------------------------
*** balance test for the full sample -------------------------------------------
*-------------------------------------------------------------------------------
 
* ssc install ietoolkit

	iebaltab 	Q1_respondent_educ_level_2018 ///
			Q2_respondent_busin_experi_2018 ///
			Q13_respondent_risk_averse_2018 ///
			business_practices_sum_2018 ///
			respondent_type_2018 ///
			respondent_gender_2018 ///
			years_functioning_2018 ///
			competition_density_full_zipco ///
			total_services_2015_2018 ///
			Q3_task_distribution_2018_dum ///
			respondent_age_2018, ///
			grpvar(instrument_fuzzy_RD) ///       
			vce(robust) ///
			grplabels("0 Control @ 1 Treatment") ///
			rowlabel  ///
			("respondent_age_2018 Respondent's age @ respondent_type_2018 Respondent's type @ business_practices_sum_2018 # of advanced business practices @ years_functioning_2018 Years Functioning @ respondent_gender_2018 Respondent's gender @ competition_density_full_zipco Density of competition @ Q1_respondent_educ_level_2018 Respondent's years of education @ Q2_respondent_busin_experi_2018 Respondent's years of business experience @ Q13_respondent_risk_averse_2018 Respondent's risk aversion @ total_services_2015_2018 Sebrae services take-up from 2015 to 2018 @ Q3_task_distribution_2018_dum Owner is solely responsible for managerial tasks") ///
		 savexlsx("RDD/Output/RDD_output_code_02b_balance_test_fuzzy_RD_full_sample") ///    
		 replace onerow ftest nonote
		 
*-------------------------------------------------------------------------------
*** balance test for a narrow RD bandwidth (9 to 12 employees) -----------------
*-------------------------------------------------------------------------------

	drop if number_employees_RAIS_2016 == 8 | number_employees_RAIS_2016 == 13

	iebaltab 	Q1_respondent_educ_level_2018 ///
			Q2_respondent_busin_experi_2018 ///
			Q13_respondent_risk_averse_2018 ///
			business_practices_sum_2018 ///
			respondent_type_2018 ///
			respondent_gender_2018 ///
			years_functioning_2018 ///
			competition_density_full_zipco ///
			total_services_2015_2018 ///
			Q3_task_distribution_2018_dum ///
			respondent_age_2018, ///
			grpvar(instrument_fuzzy_RD) ///       
			vce(robust) ///
			grplabels("0 Control @ 1 Treatment") ///
			rowlabel  ///
			("respondent_age_2018 Respondent's age @ respondent_type_2018 Respondent's type @ business_practices_sum_2018 # of advanced business practices @ years_functioning_2018 Years Functioning @ respondent_gender_2018 Respondent's gender @ competition_density_full_zipco Density of competition @ Q1_respondent_educ_level_2018 Respondent's years of education @ Q2_respondent_busin_experi_2018 Respondent's years of business experience @ Q13_respondent_risk_averse_2018 Respondent's risk aversion @ total_services_2015_2018 Sebrae services take-up from 2015 to 2018 @ Q3_task_distribution_2018_dum Owner is solely responsible for managerial tasks") ///
		 savexlsx("RDD/Output/RDD_output_code_02b_balance_test_fuzzy_RD_narrow_bandwidth") ///    
		 replace onerow ftest nonote
		 
*-------------------------------------------------------------------------------
*** balance test for a narrower RD bandwidth (10 to 11 employees) --------------
*-------------------------------------------------------------------------------

	keep if number_employees_RAIS_2016 == 10 | number_employees_RAIS_2016 == 11

	iebaltab 	Q1_respondent_educ_level_2018 ///
			Q2_respondent_busin_experi_2018 ///
			Q13_respondent_risk_averse_2018 ///
			business_practices_sum_2018 ///
			respondent_type_2018 ///
			respondent_gender_2018 ///
			years_functioning_2018 ///
			competition_density_full_zipco ///
			total_services_2015_2018 ///
			Q3_task_distribution_2018_dum ///
			respondent_age_2018, ///
			grpvar(instrument_fuzzy_RD) ///       
			vce(robust) ///
			grplabels("0 Control @ 1 Treatment") ///
			rowlabel  ///
			("respondent_age_2018 Respondent's age @ respondent_type_2018 Respondent's type @ business_practices_sum_2018 # of advanced business practices @ years_functioning_2018 Years Functioning @ respondent_gender_2018 Respondent's gender @ competition_density_full_zipco Density of competition @ Q1_respondent_educ_level_2018 Respondent's years of education @ Q2_respondent_busin_experi_2018 Respondent's years of business experience @ Q13_respondent_risk_averse_2018 Respondent's risk aversion @ total_services_2015_2018 Sebrae services take-up from 2015 to 2018 @ Q3_task_distribution_2018_dum Owner is solely responsible for managerial tasks") ///
		 savexlsx("RDD/Output/RDD_output_code_02b_balance_test_fuzzy_RD_narrower_bandwidth") ///    
		 replace onerow ftest nonote

*-------------------------------------------------------------------------------
*** balance test for the subset of sample which we observe (after attrition) ---
*-------------------------------------------------------------------------------
		 
	use "RDD/Output/RDD_output_code_01b_fuzzy_RD_sample.dta", clear
		 
	keep if attrition_outcome_sse_19 == 0

	iebaltab 	Q1_respondent_educ_level_2018 ///
			Q2_respondent_busin_experi_2018 ///
			Q13_respondent_risk_averse_2018 ///
			business_practices_sum_2018 ///
			respondent_type_2018 ///
			respondent_gender_2018 ///
			years_functioning_2018 ///
			competition_density_full_zipco ///
			total_services_2015_2018 ///
			Q3_task_distribution_2018_dum ///
			respondent_age_2018, ///
			grpvar(instrument_fuzzy_RD) ///       
			vce(robust) ///
			grplabels("0 Control @ 1 Treatment") ///
			rowlabel  ///
			("respondent_age_2018 Respondent's age @ respondent_type_2018 Respondent's type @ business_practices_sum_2018 # of advanced business practices @ years_functioning_2018 Years Functioning @ respondent_gender_2018 Respondent's gender @ competition_density_full_zipco Density of competition @ Q1_respondent_educ_level_2018 Respondent's years of education @ Q2_respondent_busin_experi_2018 Respondent's years of business experience @ Q13_respondent_risk_averse_2018 Respondent's risk aversion @ total_services_2015_2018 Sebrae services take-up from 2015 to 2018 @ Q3_task_distribution_2018_dum Owner is solely responsible for managerial tasks") ///
		 savexlsx("RDD/Output/RDD_output_code_02b_balance_test_fuzzy_RD_after_attrition") ///    
		 replace onerow ftest nonote 
