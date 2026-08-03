*========================================================================= 
* Date: 27/08/2023 
* Author: Gabriela Monteiro Avelino 
* Code 03b: Placebo test for the fuzzy RD estimation 
*========================================================================= 
 
*========================================================================= 
* Part 0: Settings 
*========================================================================= 

* setting the work directory 

	cd "/Users/aaronjoseph/Downloads/Capstone/Felipe" 
 
* importing the RDD sample 
	use "RDD/Output/RDD_output_code_01b_fuzzy_RD_sample.dta", clear 
 
*========================================================================= 
* Part 1: Placebo test for the full sample (11 variables) 
*========================================================================= 
 
* creating a list of covariates 
	vl create covariates_placebo = (respondent_age_2018 respondent_gender_2018 /// 
		business_practices_sum_2018 years_functioning_2018 competition_density_full_zipco /// 
		total_services_2015_2018 Q3_task_distribution_2018_dum respondent_owner_2018 /// 
		respond_high_school_comp_2018 respond_busin_experi_2018_dum4 /// 
		respondent_risk_averse_dum) 
 
* looping over the covariates 
	local k = 1 
	foreach var of varlist $covariates_placebo { 
		xi:reg `var' i.instrument_fuzzy_RD*number_employees_recentered 
		estimates store var`k' 
 
		local k = `k' + 1 
} 
 
* save spreadsheet and append sheets file 
	xml_tab var*, sheet(full_sample) cnames("Respondent's age" "" "Respondent's gender" "" /// 
		"Business practices score in 2018 (sum)" "" "Firm's age" "" "Density of competition" "" /// 
		"Take-up of Sebrae services" "" "Owner does not share managerial tasks" "" /// 
		"Respondent is the owner" "" "Respondent completed high school" "" /// 
		"Respondent has over 10 years of experience" "" /// 
		"Respondent is risk averse" "") /// 
		save("RDD/Output/RDD_output_code_03b_fuzzy_RD_placebo_test.xls") replace 
 
*------------------------------------------------------------------------- 
*** controlling for respondent's type 
*------------------------------------------------------------------------- 

	clear all 
 
* re-run lines 13 and 17 

	cd "/Users/aaronjoseph/Downloads/Capstone/Felipe" 
	
	use "RDD/Output/RDD_output_code_01b_fuzzy_RD_sample.dta", clear 
 
* creating a list of covariates 

	vl create covariates_placebo_control = (respondent_age_2018 respondent_gender_2018 /// 
		Q3_task_distribution_2018_dum /// 
		respond_high_school_comp_2018 respond_busin_experi_2018_dum4 /// 
		respondent_risk_averse_dum) 
 
* looping over the covariates 

	local k = 1 
	foreach var of varlist $covariates_placebo_control { 
		xi:reg `var' i.instrument_fuzzy_RD*number_employees_recentered respondent_owner_2018 
		estimates store var`k' 
 
		local k = `k' + 1 
	} 
 
* save spreadsheet and append sheets file 

	xml_tab var*, sheet(full_sample_with_control) cnames("Respondent's age" "" /// 
		"Respondent's gender" "" "Owner does not share managerial tasks" "" /// 
		"Respondent completed high school" "" /// 
		"Respondent has over 10 years of experience" "" /// 
		"Respondent is risk averse" "") /// 
		save("RDD/Output/RDD_output_code_03b_fuzzy_RD_placebo_test.xls") append 
 
*========================================================================= 
* Part 2: Placebo test for the sample after attrition (11 variables) 
*========================================================================= 

	clear all 
 
* re-run lines 13 and 17 

	cd "/Users/aaronjoseph/Downloads/Capstone/Felipe" 
	use "RDD/Output/RDD_output_code_01b_fuzzy_RD_sample.dta", clear 
 
* creating a list of covariates 

	vl create covariates_placebo = (respondent_age_2018 respondent_gender_2018 /// 
		business_practices_sum_2018 years_functioning_2018 competition_density_full_zipco /// 
		total_services_2015_2018 Q3_task_distribution_2018_dum respondent_owner_2018 /// 
		respond_high_school_comp_2018 respond_busin_experi_2018_dum4 /// 
		respondent_risk_averse_dum) 
 
	keep if attrition_outcome_sse_19 == 0 
 
* looping over the covariates 

	local k = 1 
	foreach var of varlist $covariates_placebo { 
		xi:reg `var' i.instrument_fuzzy_RD*number_employees_recentered 
		estimates store var`k' 
 
		local k = `k' + 1 
	} 
 
* save spreadsheet and append sheets file 

	xml_tab var*, sheet(after_attrition) cnames("Respondent's age" "" "Respondent's gender" "" /// 
		"Business practices score in 2018 (sum)" "" "Firm's age" "" "Density of competition" "" /// 
		"Take-up of Sebrae services" "" "Owner does not share managerial tasks" "" /// 
		"Respondent is the owner" "" "Respondent completed high school" "" /// 
		"Respondent has over 10 years of experience" "" /// 
		"Respondent is risk averse" "") /// 
		save("RDD/Output/RDD_output_code_03b_fuzzy_RD_placebo_test.xls") append 
 
*------------------------------------------------------------------------- 
*** controlling for respondent's type 
*------------------------------------------------------------------------- 

	clear all 
 
* re-run lines 13, 17 and 101 

	cd "/Users/aaronjoseph/Downloads/Capstone/Felipe" 
 
	use "RDD/Output/RDD_output_code_01b_fuzzy_RD_sample.dta", clear 
 
	keep if attrition_outcome_sse_19 == 0 
 
* creating a list of covariates 

	vl create covariates_placebo_control = (respondent_age_2018 respondent_gender_2018 /// 
		Q3_task_distribution_2018_dum /// 
		respond_high_school_comp_2018 respond_busin_experi_2018_dum4 /// 
		respondent_risk_averse_dum) 
 
* looping over the covariates 

	local k = 1 
	foreach var of varlist $covariates_placebo_control { 
		xi:reg `var' i.instrument_fuzzy_RD*number_employees_recentered respondent_owner_2018 
		estimates store var`k' 
 
		local k = `k' + 1 
	} 
 
* save spreadsheet and append sheets file

	xml_tab var*, sheet(after_attrition_with_control) cnames("Respondent's age" "" ///
				"Respondent's gender" "" "Owner does not share managerial tasks" "" ///
				"Respondent completed high school" "" ///
				"Respondent has over 10 years of experience" "" ///
				"Respondent is risk averse" "") ///
	save("RDD/Output/RDD_output_code_03b_fuzzy_RD_placebo_test.xls") append
