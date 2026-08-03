*============================================================================= 
* Matching_code_08_setup.do 
* Purpose: one-time session setup -- adopath, package checks, shared globals. 
* Run this once per Stata session (the master driver does this automatically; 
* only run it manually if you're working stage-by-stage in an open session). 
*===================================================================== 
* PIPELINE OVERVIEW (read once — applies to codes 09 through 14) 
*===================================================================== 
* All seven stage scripts (09 diff-in-means, 10 PSM, 11 CEM, 12 CEM+DiD, 
* 13 LASSO+CEM, 14 Entropy Balancing, 15 Doubly Robust) follow the same shape: 
*   1. Load the matching sample (or build it, for 12). 
*   2. Pre-matching / pre-weighting balance check (iebaltab + joint_balance_test). 
*   3. Apply the method's matching or weighting procedure. 
*   4. Estimate the treatment effect on the matched/weighted sample. 
*   5. Rank covariates by importance (rank_vars_by_importance). 
*   6. Upsert the headline result into Matching_output_effect_comparison.csv 
*      (upsert_effect_row replaces any existing row for the same Model 
*      label, so re-running a stage updates its row, not duplicates it). 
* 
* All six scripts read $out_match and $csv_path from this setup file — 
* run it once per session, or via the master driver. 
* 
* Individual file headers below state ONLY what differs from this 
* skeleton (distinctive inputs, outputs, method-specific notes). 
*===================================================================== 
clear all 
set more off 
cd "/Users/aaronjoseph/Downloads/Capstone/Felipe" 
 
adopath ++ "Matching/Code/ado" 
 
*----------------------------------------------------------------------------- 
* Package checks -- run once, not once-per-script. 
*----------------------------------------------------------------------------- 
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
 
*----------------------------------------------------------------------------- 
* Shared globals -- set once. Every stage script below reads these rather 
* than redefining them. 
*----------------------------------------------------------------------------- 
global out_match "Matching/Output" 
cap mkdir "$out_match" 
 
global Y_main  business_practices_sum_2019 
global Y_base  business_practices_sum_2018 
global D       treatment_assignment_binary 
 
global Xcand   respondent_age_2018 respondent_gender_2018 /// 
               business_practices_sum_2018 years_functioning_2018 /// 
               competition_density_full_zipco total_services_2015_2018 /// 
               respondent_owner_2018 number_employees_RAIS_2016 sse_2018_only 
 
global Xpscore respondent_gender_2018 business_practices_sum_2018 /// 
               number_employees_RAIS_2016 
 
global Xcem    respondent_gender_2018 business_practices_sum_2018 /// 
               number_employees_RAIS_2016 
 
global csv_path "$out_match/Matching_output_effect_comparison.csv" 
 
di as result "Setup complete. Packages checked, adopath set, globals defined." 
