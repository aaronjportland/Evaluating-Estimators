*========================================================================= 
* Matching_code_08a_entropy_balancing_weights.do 
* 
* Entropy Balancing -- Weight Estimation 
* (Covariate list follows PSM's Code 04a convention, since entropy 
*  balancing does not need CEM's dimensionality pruning) 
* 
* Input:   Matching/Output/Matching_output_code_03_sample.dta 
* Output:  Matching/Output/entropy_weighted_sample.dta 
* 
* Author:  Aaron Joseph 
*========================================================================= 
clear all 
set more off 
cd "/Users/aaronjoseph/Downloads/Capstone/Felipe" 
 
cap which ebalance 
if _rc { 
    di as error "ebalance not installed. Run: ssc install ebalance" 
    exit 199 
} 
 
global D     treatment_assignment_binary 
 
* Continuous / binary covariates (per PSM Code 04a) 
global Xcont respondent_age_2018 respondent_gender_2018 /// 
    business_practices_sum_2018 years_functioning_2018 /// 
    competition_density_full_zipco total_services_2015_2018 /// 
    number_employees_RAIS_2016 sse_2018_only 
 
* Categorical fixed effects (per PSM Code 04a; sector9 excluded -- 
* zero variation across groups, as noted in original script) 
global Xcat reg_office2 reg_office3 reg_office4 reg_office5 reg_office6 /// 
    sector2 sector3 sector4 sector5 sector6 sector7 sector8 sector10 
 
global out_match "Matching/Output" 
 
use "$out_match/Matching_output_code_03_sample.dta", clear 
di "Sample loaded. N = " _N 
tab $D 
 
* Check for missingness before running ebalance -- anything found here 
* needs a _miss indicator + zero-fill, following the DML convention, 
* since ebalance drops observations with missing covariates silently. 
misstable summarize $Xcont $Xcat 
 
local missnames 
foreach var of varlist $Xcont $Xcat { 
    qui count if missing(`var') 
    if r(N) > 0 { 
        local missname = substr("`var'", 1, 27) + "_miss" 
        capture drop `missname' 
        gen `missname' = missing(`var') 
        replace `var' = 0 if missing(`var') 
        local missnames `missnames' `missname' 
        di "NOTE: `var' had r(N) missing values; `missname' created." 
    } 
} 
 
global Xall $Xcont $Xcat `missnames' 
 
* ebalance targets means by default; targets(2) adds variance for 
* the continuous covariates. Categorical dummies typically only need 
* mean-matching (targets(1)), so they are entered separately. 
ebalance $D $Xcont `missnames', targets(2) generate(webal) 
 
di "Entropy weights generated (continuous covariates, mean+variance)." 
summarize webal if $D == 0, detail 
 
save "$out_match/entropy_weighted_sample.dta", replace 
