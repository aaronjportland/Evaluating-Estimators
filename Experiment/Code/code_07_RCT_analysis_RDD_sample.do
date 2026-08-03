********************************************************************************
* Date: 16/06/2023
* Author: Gabriela Monteiro Avelino
*
*	Code 07: RCT analysis (RDD sample)
*
*===============================================================================
*	Part 0: Settings
*===============================================================================

* setting the work directory

	cd "/Users/aaronjoseph/Downloads/Capstone/Felipe"
	
* importing the full population of firms in SSE 2015-2018

	use "Experiment/Output/output_code_05_sample.dta", clear
	
*===============================================================================
*	Part 1: Restricting sample to the population that will be used in the RDD
*===============================================================================

	keep if	merge_survey_WBG_2018 == 3 & /// 
			appears_in_RAIS_2016 == 1 & /// 
			number_employees_RAIS_2016 >= 8 & ///
			number_employees_RAIS_2016 <= 10 & /// 
			business_practices_sum_2018 <= 22 & ///
			treated_impact_evaluation_2017 != 1
	
*===============================================================================
*	Part 2: Checking for balance between treatment and control
*===============================================================================	

* creating treatment assignment dummy

	g treatment_assignment_dummy = 0 if treatment_assignment == 0
	replace treatment_assignment_dummy = 1 if treatment_assignment_dummy ==.

* identifying missing information

* ssc install nmissing

	nmissing Q1_respondent_educ_level_2018 Q2_respondent_busin_experi_2018 ///
				number_employees_RAIS_2016 years_functioning_2018 respondent_type_2018 ///
				business_practices_sum_2018 respondent_gender_2018 respondent_age_2018 ///
				total_services_2015_2018 competition_density_full_zipco ///
				Q13_respondent_risk_averse_2018
				
	foreach var of any `r(varlist)' {
		
	g `var'_miss = 1 if `var'==. 
	recode `var'_miss (.=0)

	}

* only total use of Sebrae services between 2015 and 2018 has missing values.
	
*-------------------------------------------------------------------------------
*** balance test without variables with missing values -------------------------
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
			number_employees_RAIS_2016 ///
			respondent_age_2018, ///
			covariates(randomization_strata) ///   
			grpvar(treatment_assignment_dummy) ///       
			vce(robust) ///
			grplabels("0 Control @ 1 Treatment") ///
			rowlabel  ///
			("respondent_age_2018 Respondent's age @ respondent_type_2018 Respondent's type @ business_practices_sum_2018 # of advanced business practices @ years_functioning_2018 Years Functioning @ respondent_gender_2018 Respondent's gender @ number_employees_RAIS_2016  # of employees in RAIS 2016 @ competition_density_full_zipco Density of competition @ Q1_respondent_educ_level_2018 Respondent's years of education @ Q2_respondent_busin_experi_2018 Respondent's years of business experience @ Q13_respondent_risk_averse_2018 Respondent's risk aversion") ///
		 savexlsx("Experiment/Output/output_code_07_RDD_sample_balance_test1") ///    
		 replace onerow ftest nonote

*===============================================================================
*	Part 3: Checking for differential attrition
*===============================================================================	

iebaltab 	attrition_outcome_sse_19, ///
			covariates(randomization_strata) ///   
			grpvar(treatment_assignment_dummy) ///       
			vce(robust) ///
			grplabels("0 Control @ 1 Treatment") ///
			rowlabel  ///
			("attrition_outcome_sse_19 Attrition in SSE 2019") ///
		 savexlsx("Experiment/Output/output_code_07_RDD_sample_differential_attrition") ///    
		 replace onerow ftest nonote
		 
*===============================================================================
*	Part 4: Estimating treatment effect (intent-to-treat, full sample)
*===============================================================================	

drop if business_practices_sum_2019 ==.

xi: regress business_practices_sum_2019 treatment_assignment_dummy ///
	i.randomization_strata, robust
	
xi: regress business_practices_sum_2019 i.treatment_assignment ///
	i.randomization_strata, robust
	