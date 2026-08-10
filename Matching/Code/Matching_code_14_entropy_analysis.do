*============================================================================== 
* Matching_code_14_entropy_analysis.do 
* Date: 08/07/2026 
* Author: Aaron Joseph 
* 
* Purpose: Estimate the effect of treatment on business_practices_sum_2019 
* using Entropy Balancing. Unlike CEM/PSM, entropy balancing reweights the 
* control group to match the treated group's covariate moments exactly, 
* without discarding observations. 
* 
* Input:  Matching/Output/Matching_output_code_03_sample.dta 
* Output: Matching/Output/entropy_weighted_sample.dta 
*         Matching/Output/entropy_balance.xlsx 
*         Matching/Output/entropy_balance_untargeted_check.xlsx 
*         Matching/Output/entropy_itt.ster 
*         Matching/Output/Matching_output_effect_comparison.csv (appended) 
*         Matching/Output/output_code_14_entropy.txt (log) 
* 
* Main steps: 
*   1. Load the sample and define the covariate groups to balance. 
*   2. Generate missing-indicators for targeted covariates. 
*   3. Estimate entropy-balancing weights. 
*   4. Run weight diagnostics and save the weighted sample. 
*   5. Check post-weighting balance. 
*   6. Estimate the weighted treatment effect (naive SE). 
*   7. Bootstrap the full procedure for a valid SE. 
*   8. Rank covariates by importance and upsert the result. 
*============================================================================== 
 
clear all 
set more off 
set seed 123 
cd "/Users/aaronjoseph/Downloads/Capstone/Felipe" 
 
global out_match "Matching/Output" 
cap mkdir "$out_match" 
cap log close 
log using "$out_match/output_code_14_entropy.txt", text replace 
 
// Step 1: Load the sample and define the covariate groups to balance. 
global Y_main business_practices_sum_2019 
global D treatment_assignment_binary 
 
* Continuous covariates with meaningful variance -- balanced on mean + variance. 
global Xcont_var respondent_age_2018 years_functioning_2018 /// 
    competition_density_full_zipco total_services_2015_2018 /// 
    number_employees_RAIS_2016 
 
* Binary covariates -- mean-only balancing. 
global Xcont_bin respondent_gender_2018 business_practices_sum_2018 sse_2018_only 
 
* Categorical fixed effects -- mean-only balancing. 
global Xcat reg_office2 reg_office3 reg_office4 reg_office5 reg_office6 /// 
    sector2 sector3 sector4 sector5 sector6 sector7 sector8 sector10 
 
* Full candidate pool for balance reporting and importance ranking. 
* respondent_owner_2018 is diagnostic only -- not an ebalance constraint. 
global Xcand respondent_age_2018 respondent_gender_2018 /// 
    business_practices_sum_2018 years_functioning_2018 /// 
    competition_density_full_zipco total_services_2015_2018 /// 
    respondent_owner_2018 number_employees_RAIS_2016 sse_2018_only 
 
global Xtargeted $Xcont_var $Xcont_bin $Xcat 
 
use "$out_match/Matching_output_code_03_sample.dta", clear 
di "Sample loaded. N = " _N 
tab $D 
 
tabulate sebrae_regional_office_2018, generate(reg_office) 
tabulate sebrae_strategic_business_sector, generate(sector) 
cap drop sector9 
 
// Step 2: Generate missing-indicators for targeted covariates. 
* Check for missingness -- ebalance drops observations with missing 
* covariates silently, so missing indicators are created first. 
misstable summarize $Xtargeted respondent_owner_2018 
local missnames 
foreach var of varlist $Xtargeted respondent_owner_2018 { 
    qui count if missing(`var') 
    if r(N) > 0 { 
        local missname = substr("`var'", 1, 27) + "_miss" 
        capture drop `missname' 
        gen `missname' = missing(`var') 
        replace `var' = 0 if missing(`var') 
        local missnames `missnames' `missname' 
        di "NOTE: `var' had `r(N)' missing values; `missname' created." 
    } 
} 
 
// Step 3: Estimate entropy-balancing weights. 
ebalance $D $Xcont_bin $Xcat `missnames' ($Xcont_var), generate(webal) 
 
di "Entropy weights generated:" 
di " - Mean + variance balanced: $Xcont_var" 
di " - Mean-only balanced: $Xcont_bin $Xcat `missnames'" 
summarize webal if $D == 0, detail 
 
// Step 4: Run weight diagnostics and save the weighted sample. 
quietly summarize webal if $D == 0 
local w_mean = r(mean) 
quietly summarize webal if $D == 0, detail 
local w_max = r(max) 
local max_mean_ratio = `w_max' / `w_mean' 
quietly sum webal if $D == 0 
local sum_w = r(sum) 
quietly gen double webal_sq = webal^2 if $D == 0 
quietly sum webal_sq if $D == 0 
local sum_w2 = r(sum) 
local kish_n = (`sum_w'^2) / `sum_w2' 
drop webal_sq 
 
di "--- Control-group weight diagnostics ---" 
di " Max/mean weight ratio: `max_mean_ratio'" 
di " Kish effective sample size (controls): `kish_n'" 
 
save "$out_match/entropy_weighted_sample.dta", replace 
 
// Step 5: Check post-weighting balance. 
use "$out_match/entropy_weighted_sample.dta", clear 
 
di "--- Post-weighting balance: targeted covariates ---" 
iebaltab $Xtargeted [aw = webal], grpvar($D) /// 
    savexlsx("$out_match/entropy_balance.xlsx") replace vce(robust) rowvarlabels 
 
di "--- Post-weighting balance: respondent_owner_2018 (not targeted -- diagnostic only) ---" 
iebaltab respondent_owner_2018 [aw = webal], grpvar($D) /// 
    savexlsx("$out_match/entropy_balance_untargeted_check.xlsx") replace vce(robust) rowvarlabels 
 
joint_balance_test "$Xtargeted" "webal" "1" "Entropy Balancing" 
local jf_p = r(f_p) 
local jmv_p = r(mvtest_p) 
 
// Step 6: Estimate the weighted treatment effect (naive SE). 
regress $Y_main $D [pweight = webal], robust 
estimates store entropy_itt 
estimates save "$out_match/entropy_itt.ster", replace 
 
local beta = _b[$D] 
local se_naive = _se[$D] 
local n1 = e(N) 
 
* Entropy balancing drops no observations -- reported as 0 by construction. 
local n_dropped = 0 

// Step 7: Bootstrap the full procedure for a valid SE. 
* Pass missnames as a global so the bootstrap program can access it -- 
* Stata programs do not inherit locals from the calling scope. 
 

global entropy_missnames `missnames' 
 
capture program drop entropy_boot_step 
program define entropy_boot_step, rclass 
    cap noisily ebalance $D $Xcont_bin $Xcat $entropy_missnames ($Xcont_var), generate(webal_boot) 
    if _rc { 
        return scalar beta = . 
        exit 
    } 
    cap noisily regress $Y_main $D [pweight=webal_boot] 
    if _rc { 
        return scalar beta = . 
    } 
    else { 
        return scalar beta = _b[$D] 
    } 
    cap drop webal_boot 
end 
 
di "--- Bootstrapping full entropy-balancing procedure for valid SE ---" 
bootstrap beta=r(beta), reps(200) seed(123): entropy_boot_step 

* Clean up the temporary global after bootstrapping. 
global entropy_missnames
 
local beta_boot = _b[beta] 
local se_boot = _se[beta] 
local p_boot = 2*ttail(e(N)-1, abs(`beta_boot'/`se_boot')) 
 
di "Naive (weights-as-fixed) SE: `se_naive'" 
di "Bootstrap SE (accounts for weight-estimation uncertainty): `se_boot'" 
 
// Step 8: Rank covariates by importance and upsert the result. 
rank_vars_by_importance $Y_main "$Xtargeted" "1" 
local vars_used = r(ordered_vars) 
 
local csv_path "$out_match/Matching_output_effect_comparison.csv" 
local this_label "Entropy Balancing" 
 
upsert_effect_row, csvpath(`"`csv_path'"') model(`"`this_label'"') method(`"ebalance"') /// 
    beta(`beta') se(`se_boot') pval(`p_boot') n1(`n1') n2(`n_dropped') /// 
    varsused(`"`vars_used'"') dropcond(`"Model == "`this_label'""') /// 
    jointfp(`jf_p')
 
di "" 
di "========================================================================" 
di " Entropy balancing analysis complete." 
di " N (weighted estimation sample) = `n1'" 
di " Beta = `beta'" 
di " Naive SE = `se_naive' | Bootstrap SE = `se_boot' | Bootstrap p = `p_boot'" 
di " Max/mean control weight ratio = `max_mean_ratio'" 
di " Kish effective N (controls) = `kish_n'" 
di " Result written to $out_match/Matching_output_effect_comparison.csv" 
di "========================================================================" 
log close 

 
