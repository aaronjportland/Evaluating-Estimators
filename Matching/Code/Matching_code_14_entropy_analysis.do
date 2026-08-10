*============================================================================== 
* Matching_code_14_entropy_analysis.do 
* Date: 08/07/2026 | Author: Aaron Joseph 
* 
* Entropy balancing: reweights the control group to match treated covariate 
* moments exactly. Bootstraps the full procedure for a valid SE. 
* Output: entropy_weighted_sample.dta, entropy_balance.xlsx, 
*         entropy_balance_untargeted_check.xlsx, entropy_itt.ster, 
*         Matching_output_effect_comparison.csv (appended) 
*============================================================================== 
clear all 
set more off 
set seed 123 
cd "/Users/aaronjoseph/Downloads/Capstone/Felipe" 
 
global out_match "Matching/Output" 
cap mkdir "$out_match" 
cap log close 
log using "$out_match/output_code_14_entropy.txt", text replace 
 
// Step 1: Load sample and define covariate groups. 
global Y_main business_practices_sum_2019 
global D      treatment_assignment_binary 
 
// Continuous covariates: balanced on mean + variance. 
global Xcont_var respondent_age_2018 years_functioning_2018              /// 
                 competition_density_full_zipco total_services_2015_2018 /// 
                 number_employees_RAIS_2016 
 
// Binary covariates: mean-only balancing. 
global Xcont_bin respondent_gender_2018 business_practices_sum_2018 sse_2018_only 
 
// Categorical FEs: mean-only balancing. 
global Xcat  reg_office2 reg_office3 reg_office4 reg_office5 reg_office6 /// 
             sector2 sector3 sector4 sector5 sector6 sector7 sector8 sector10 
 
// Full candidate pool for balance reporting and importance ranking. 
// respondent_owner_2018 is diagnostic only -- not an ebalance constraint. 
global Xcand respondent_age_2018 respondent_gender_2018             /// 
             business_practices_sum_2018 years_functioning_2018     /// 
             competition_density_full_zipco total_services_2015_2018 /// 
             respondent_owner_2018 number_employees_RAIS_2016 sse_2018_only 
 
global Xtargeted $Xcont_var $Xcont_bin $Xcat 
 
use "$out_match/Matching_output_code_03_sample.dta", clear 
di "Sample loaded. N = " _N 
tab $D 
 
tabulate sebrae_regional_office_2018,      generate(reg_office) 
tabulate sebrae_strategic_business_sector, generate(sector) 
cap drop sector9 
 
// Step 2: Generate missing-indicators for targeted covariates. 
// ebalance silently drops observations with missing covariates. 
misstable summarize $Xtargeted respondent_owner_2018 
local missnames 
foreach var of varlist $Xtargeted respondent_owner_2018 { 
    quietly count if missing(`var') 
    if r(N) > 0 { 
        local missname = substr("`var'", 1, 27) + "_miss" 
        cap drop `missname' 
        gen `missname' = missing(`var') 
        replace `var' = 0 if missing(`var') 
        local missnames `missnames' `missname' 
        di "NOTE: `var' had `r(N)' missing values; `missname' created." 
    } 
} 
 
// Step 3: Estimate entropy-balancing weights. 
ebalance $D $Xcont_bin $Xcat `missnames' ($Xcont_var), generate(webal) 
summarize webal if $D == 0, detail 
 
// Step 4: Weight diagnostics and save weighted sample. 
quietly summarize webal if $D == 0, detail 
local w_mean        = r(mean) 
local w_max         = r(max) 
local max_mean_ratio = `w_max' / `w_mean' 
quietly gen double webal_sq = webal^2 if $D == 0 
quietly summarize webal_sq if $D == 0 
local kish_n = cond(r(sum) == 0, ., (`w_mean' * r(N))^2 / r(sum)) 
drop webal_sq 
 
di "Max/mean weight ratio: `max_mean_ratio'  |  Kish effective N (controls): `kish_n'" 
save "$out_match/entropy_weighted_sample.dta", replace 
 
// Step 5: Post-weighting balance. 
use "$out_match/entropy_weighted_sample.dta", clear 
iebaltab $Xtargeted [aw=webal], grpvar($D) /// 
    savexlsx("$out_match/entropy_balance.xlsx") replace vce(robust) rowvarlabels 
iebaltab respondent_owner_2018 [aw=webal], grpvar($D) /// 
    savexlsx("$out_match/entropy_balance_untargeted_check.xlsx") replace vce(robust) rowvarlabels 
joint_balance_test "$Xtargeted" "webal" "1" "Entropy Balancing" 
local jf_p  = r(f_p) 
local jmv_p = r(mvtest_p) 
 
// Step 6: Weighted treatment effect (naive SE). 
regress $Y_main $D [pweight=webal], robust 
estimates store entropy_itt 
estimates save "$out_match/entropy_itt.ster", replace 
local beta    = _b[$D] 
local se_naive = _se[$D] 
local n1      = e(N) 
local n_dropped = 0   // entropy balancing drops no observations 
 
// Step 7: Bootstrap the full procedure for a valid SE. 
// missnames passed via global so the bootstrap program can access it. 
global entropy_missnames `missnames' 
 
capture program drop entropy_boot_step 
program define entropy_boot_step, rclass 
    cap noisily ebalance $D $Xcont_bin $Xcat $entropy_missnames ($Xcont_var), generate(webal_boot) 
    if _rc { 
		return scalar beta = .; exit 
	} 
    cap noisily regress $Y_main $D [pweight=webal_boot] 
    return scalar beta = cond(_rc, ., _b[$D]) 
    cap drop webal_boot 
end 
 
bootstrap beta=r(beta), reps(200) seed(123): entropy_boot_step 
global entropy_missnames   // clean up 
 
local beta_boot = _b[beta] 
local se_boot   = _se[beta] 
local p_boot    = 2 * ttail(e(N) - 1, abs(`beta_boot' / `se_boot')) 
di "Naive SE: `se_naive'  |  Bootstrap SE: `se_boot'" 
 
// Step 8: Rank covariates and upsert result. 
rank_vars_by_importance $Y_main "$Xtargeted" "1" 
local vars_used  = r(ordered_vars) 
local this_label "Entropy Balancing" 
 
upsert_effect_row, csvpath("$csv_path") model("`this_label'") method("ebalance") /// 
    beta(`beta') se(`se_boot') pval(`p_boot') n1(`n1') n2(`n_dropped')            /// 
    varsused("`vars_used'") dropcond(`"Model == "`this_label'""')                  /// 
    jointfp(`jf_p') 
 
di "Entropy balancing complete. N=`n1' | Beta=`beta' | Bootstrap SE=`se_boot'" 
log close 
