 

*========================================================================= 
* Matching_code_06_cem_analysis.do  (aligned with Code 04b conventions) 
* 
* Coarsened Exact Matching (CEM) Analysis 
* 
* Purpose: Estimate the effect of treatment_assignment_binary on 
*          business_practices_sum_2019, matching experimental treated 
*          firms against a RAIS/SSE-based comparison pool via CEM. 
* 
* Input:   Matching/Output/Matching_output_code_03_sample.dta 
* Output:  Matching/Output/cem_balance.xlsx 
*          Matching/Output/cem_itt.ster 
*          Matching/Output/output_code_06_cem.txt (log) 
* 
* Author:  Aaron Joseph 
* Date: 
*========================================================================= 
 
*------------------------------------------------------------------------- 
* Part 0: Settings 
*------------------------------------------------------------------------- 
clear all 
set more off 
set seed 123 
 
cd "/Users/aaronjoseph/Downloads/Capstone/Felipe" 
 
cap which cem 
if _rc { 
    di as error "cem is not installed. Run: ssc install cem" 
    exit 199 
} 
cap which iebaltab 
if _rc { 
    di as error "iebaltab is not installed. Run: ssc install iebaltab" 
    exit 199 
} 
 
global out_match "Matching/Output" 
cap mkdir "$out_match" 
 
log using "$out_match/output_code_06_cem.txt", text replace 
 
*------------------------------------------------------------------------- 
* Part 1: Globals 
*------------------------------------------------------------------------- 
global Y_main business_practices_sum_2019 
global D       treatment_assignment_binary 
 
* Full candidate covariate pool (as in Code 04b, before pruning) 
global Xcand respondent_age_2018 respondent_gender_2018 /// 
    business_practices_sum_2018 years_functioning_2018 /// 
    competition_density_full_zipco total_services_2015_2018 /// 
    respondent_owner_2018 number_employees_RAIS_2016 sse_2018_only 
 
* Final covariates retained in matching (per Code 04b: those that 
* strongly predicted treatment) 
global Xcem respondent_gender_2018 business_practices_sum_2018 /// 
    total_services_2015_2018 number_employees_RAIS_2016 
 
*------------------------------------------------------------------------- 
* Part 2: Load data 
*------------------------------------------------------------------------- 
use "$out_match/Matching_output_code_03_sample.dta", clear 
di "Matching sample loaded. N = " _N 
tab $D 
 
*------------------------------------------------------------------------- 
* Part 3: Pre-matching balance check (full candidate pool) 
*------------------------------------------------------------------------- 
di "--- Pre-matching balance: candidate covariates ---" 
iebaltab $Xcand, grpvar($D) save("$out_match/cem_balance_prematch.xlsx") /// 
    replace vce(robust) rowvarlabels 
 
*------------------------------------------------------------------------- 
* Part 4: Run CEM (automatic coarsening, per Code 04b convention) 
*------------------------------------------------------------------------- 
di "--- Running CEM ---" 
 
cem $Xcem, treatment($D) 
 
* cem creates cem_matched, cem_weights, cem_strata 
di "N matched: " 
count if cem_matched == 1 
di "N dropped: " 
count if cem_matched == 0 
 
*------------------------------------------------------------------------- 
* Part 5: Post-matching balance check 
*------------------------------------------------------------------------- 
di "--- Post-matching balance: matched sample ---" 
iebaltab $Xcand if cem_matched == 1 [aw = cem_weights], grpvar($D) /// 
    save("$out_match/cem_balance_postmatch.xlsx") replace vce(robust) rowvarlabels 
 
*------------------------------------------------------------------------- 
* Part 6: Treatment effect estimation (per Code 04b) 
*------------------------------------------------------------------------- 
di "--- CEM-weighted treatment effect ---" 
 
regress $Y_main $D [iweight = cem_weights], robust 
 
estimates store cem_itt 
estimates save "$out_match/cem_itt.ster", replace 
 
*------------------------------------------------------------------------- 
* Part 7: Summary 
*------------------------------------------------------------------------- 
di "CEM analysis complete. Matched N: " 
count if cem_matched == 1 
di "Estimates saved to $out_match/cem_itt.ster" 
di "Balance tables saved to $out_match/cem_balance_prematch.xlsx and cem_balance_postmatch.xlsx" 
 
log close 
