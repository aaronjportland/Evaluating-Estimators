* ============================================================================== 
* Matching_code_08_setup.do 
* Date: 08/07/2026 
* Author: Aaron Joseph 
* 
* Purpose: one-time session setup -- adopath, package checks, shared globals. 
* Run this once per Stata session (the master driver does this automatically; 
* only run it manually if you're working stage-by-stage in an open session). 
* 
* PIPELINE OVERVIEW (applies to codes 09 through 15): all eight stage scripts 
* (09 diff-in-means, 10 PSM, 11 CEM, 12 CEM+DiD, 13 LASSO+CEM, 14 Entropy 
* Balancing, 15 Doubly Robust) load the matching sample, run a pre-matching 
* balance check, apply the method, estimate the effect, rank covariates by 
* importance, and upsert the headline result into the shared comparison CSV. 
* 
* Main steps: 
*   1. Set the working directory and adopath. 
*   2. Check for and install required packages. 
*   3. Define shared globals used by every downstream stage script. 
*============================================================================== 
 
// Step 1: Set the working directory and adopath. 
clear all 
set more off 
cd "/Users/aaronjoseph/Downloads/Capstone/Felipe" 
adopath ++ "Matching/Code/ado" 
 
// Step 2: Check for and install required packages. 
foreach pkg in cem iebaltab ebalance mvtest { 
    cap which `pkg' 
    if _rc { 
        di as text "Installing `pkg'..." 
        ssc install `pkg', replace 
    } 
} 
cap which reghdfe 
if _rc { 
    di as text "Installing reghdfe..." 
    ssc install reghdfe, replace 
    ssc install ftools, replace 
} 
 
// Step 3: Define shared globals used by every downstream stage script. 
global out_match "Matching/Output" 
cap mkdir "$out_match" 
 
global Y_main business_practices_sum_2019 
global Y_base business_practices_sum_2018 
global D treatment_assignment_binary 
 
global Xcand respondent_age_2018 respondent_gender_2018 /// 
    business_practices_sum_2018 years_functioning_2018 /// 
    competition_density_full_zipco total_services_2015_2018 /// 
    respondent_owner_2018 number_employees_RAIS_2016 sse_2018_only 
 
global Xpscore respondent_gender_2018 business_practices_sum_2018 /// 
    number_employees_RAIS_2016 
 
global Xcem respondent_gender_2018 business_practices_sum_2018 /// 
    number_employees_RAIS_2016 
 
global csv_path "$out_match/Matching_output_effect_comparison.csv" 
 
di as result "Setup complete. Packages checked, adopath set, globals defined." 

 

 

 