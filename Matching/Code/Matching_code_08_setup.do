*============================================================================== 
* Matching_code_08_setup.do 
* Date: 08/07/2026 | Author: Aaron Joseph 
* 
* One-time session setup: adopath, package checks, shared globals. 
* Run once per session (master driver does this automatically). 
* 
* Pipeline overview (codes 09–15): each stage script loads the matching 
* sample, runs a pre-matching balance check, applies the method, estimates 
* the effect, ranks covariates by importance, and upserts into the shared 
* comparison CSV. 
*============================================================================== 
clear all 
set more off 
cd "/Users/aaronjoseph/Downloads/Capstone/Felipe" 
adopath ++ "Matching/Code/ado" 
 
// Step 1: Check for and install required packages. 
foreach pkg in cem iebaltab ebalance mvtest { 
    cap which `pkg' 
    if _rc { 
		ssc install `pkg', replace 
	} 
}
 
cap which reghdfe 
if _rc { 
    ssc install reghdfe, replace 
    ssc install ftools,  replace 
} 
 
// Step 2: Define shared globals. 
global out_match "Matching/Output" 
cap mkdir "$out_match" 
 
global Y_main business_practices_sum_2019 
global Y_base business_practices_sum_2018 
global D     treatment_assignment_binary 
 
global Xcand  respondent_age_2018 respondent_gender_2018             /// 
              business_practices_sum_2018 years_functioning_2018     /// 
              competition_density_full_zipco total_services_2015_2018 /// 
              respondent_owner_2018 number_employees_RAIS_2016 sse_2018_only 
 
global Xpscore respondent_gender_2018 business_practices_sum_2018 /// 
               number_employees_RAIS_2016 
 
global Xcem    respondent_gender_2018 business_practices_sum_2018 /// 
               number_employees_RAIS_2016 
 
global csv_path "$out_match/Matching_output_effect_comparison.csv" 
 
di as result "Setup complete." 

 
