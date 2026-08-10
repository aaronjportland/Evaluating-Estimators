
 *============================================================================== 
* Matching_code_10_psmatch2_specsweep.do 
* Date: 08/07/2026 
* Author: Aaron Joseph 
* 
* Purpose: Run psmatch2 under several matching specifications, estimate the 
* effect for each, and select the spec with the best post-match balance 
* (lowest mean absolute SMD) as the headline result. 
* 
* Input:  Matching/Output/Matching_output_code_03_sample.dta 
* Output: Matching/Output/psm_balance_prematch.xlsx, psm_balance_postmatch.xlsx 
*         Matching/Output/psm_pscore_common_support.png 
*         Matching/Output/psm_specification_comparison.csv 
*         Matching/Output/Matching_output_effect_comparison.csv (appended) 
*         Matching/Output/output_code_10_psm.txt (log) 
* 
* Main steps: 
*   1. Load the matching sample and check pre-matching balance. 
*   2. Define the candidate psmatch2 specifications. 
*   3. Run each specification and record its balance/estimate. 
*   4. Select the winning specification by lowest mean |SMD|. 
*   5. Produce post-match balance table and overlap graph for the winner. 
*   6. Upsert the winning result into the shared comparison CSV. 
*============================================================================== 
 
clear all 
set more off 
set seed 123 
cd "/Users/aaronjoseph/Downloads/Capstone/Felipe" 
 
global out_match "Matching/Output" 
cap mkdir "$out_match" 
cap log close 
log using "$out_match/output_code_10_psm.txt", text replace 
 
global Y_main business_practices_sum_2019 
global D treatment_assignment_binary 
global Xcand respondent_age_2018 respondent_gender_2018 business_practices_sum_2018 /// 
    years_functioning_2018 competition_density_full_zipco total_services_2015_2018 /// 
    respondent_owner_2018 number_employees_RAIS_2016 sse_2018_only 
global Xpscore respondent_gender_2018 business_practices_sum_2018 number_employees_RAIS_2016 
 
// Step 1: Load the matching sample and check pre-matching balance. 
use "$out_match/Matching_output_code_03_sample.dta", clear 
di "N = " _N 
tab $D 
 
iebaltab $Xcand, grpvar($D) savexlsx("$out_match/psm_balance_prematch.xlsx") /// 
    replace vce(robust) rowvarlabels 
 
// Step 2: Define the candidate psmatch2 specifications. 
local labels default_nn1 nn1_noreplace nn3 nn5 nn1_caliper radius kernel llr 
local opts1 neighbor(1) common 
local opts2 neighbor(1) noreplacement common 
local opts3 neighbor(3) common 
local opts4 neighbor(5) common 
local opts5 neighbor(1) caliper(0.01) common 
local opts6 radius caliper(0.05) common 
local opts7 kernel kerneltype(normal) bwidth(0.06) common 
local opts8 llr bwidth(0.06) common 
local nspecs : word count `labels' 
 
* Computes mean absolute standardized mean difference (SMD) across 
* $Xcand for the matched/weighted sample currently in memory. 
capture program drop compute_mean_abs_smd 
program define compute_mean_abs_smd, rclass 
    args varlist wtvar touse 
    local sum_abs_smd = 0 
    local n_ok = 0 
    foreach v of local varlist { 
        quietly summarize `v' if $D==1 & `touse' [aw=`wtvar'] 
        local mT = r(mean) 
        local sT = r(sd) 
        quietly summarize `v' if $D==0 & `touse' [aw=`wtvar'] 
        local mC = r(mean) 
        local sC = r(sd) 
        local pooled_sd = sqrt((`sT'^2 + `sC'^2)/2) 
        if `pooled_sd' > 0 & !missing(`mT') & !missing(`mC') { 
            local smd = abs((`mT' - `mC') / `pooled_sd') 
            local sum_abs_smd = `sum_abs_smd' + `smd' 
            local n_ok = `n_ok' + 1 
        } 
    } 
    if `n_ok' > 0 return scalar mean_abs_smd = `sum_abs_smd' / `n_ok' 
    else return scalar mean_abs_smd = . 
end 
 
tempname results 
tempfile psm_results_raw 
postfile `results' int spec_num str20 spec_label long n_matched long n_dropped /// 
    double att double se double p double mean_abs_smd using "`psm_results_raw'", replace 
 
* One tempfile per spec's matched dataset, saved only when the spec succeeds. 
forvalues i = 1/`nspecs' { 
    tempfile spec`i'_file 
} 
 
// Step 3: Run each specification and record its balance/estimate. 
forvalues i = 1/`nspecs' { 
    local lbl : word `i' of `labels' 
    local thisopt `opts`i'' 
    di "=== Spec `i': `lbl' -- `thisopt' ===" 
 
    use "$out_match/Matching_output_code_03_sample.dta", clear 
    cap noisily psmatch2 $D $Xpscore, `thisopt' logit 
 
    if _rc { 
        di as error "Spec `lbl' failed, rc=`=_rc'" 
        post `results' (`i') ("`lbl'") (.) (.) (.) (.) (.) (.) 
        continue 
    } 
 
    rename _pscore pscore 
    rename _weight psm_weight 
    gen byte psm_matched = !missing(psm_weight) 
 
    quietly count if psm_matched == 1 
    local nm = r(N) 
    quietly count if psm_matched == 0 
    local nd = r(N) 
 
    local smd = . 
    if `nm' > 0 { 
        compute_mean_abs_smd "$Xcand" psm_weight "psm_matched==1" 
        local smd = r(mean_abs_smd) 
    } 
 
    cap noisily regress $Y_main $D [iweight=psm_weight] if psm_matched==1, robust 
 
    if _rc { 
        post `results' (`i') ("`lbl'") (`nm') (`nd') (.) (.) (.) (`smd') 
    } 
    else { 
        local b = _b[$D] 
        local s = _se[$D] 
        local p = 2*ttail(e(df_r), abs(`b'/`s')) 
        post `results' (`i') ("`lbl'") (`nm') (`nd') (`b') (`s') (`p') (`smd') 
        * Save this spec's matched dataset only if it's a valid candidate. 
        save `spec`i'_file', replace 
    } 
 
} 
postclose `results' 
 
use "`psm_results_raw'", clear 
export delimited using "$out_match/psm_specification_comparison.csv", replace 
 
// Step 4: Select the winning specification by lowest mean |SMD|. 
use "`psm_results_raw'", clear 
drop if missing(att) | missing(se) | missing(p) | missing(mean_abs_smd) 
if _N == 0 { 
    di as error "No spec produced a valid estimate + balance metric. Aborting." 
    exit 459 
} 
sort mean_abs_smd spec_num 
local best_spec_num = spec_num[1] 
local best_spec_label = spec_label[1] 
local best_att = att[1] 
local best_se = se[1] 
local best_p = p[1] 
local best_nm = n_matched[1] 
local best_nd = n_dropped[1] 
local best_smd = mean_abs_smd[1] 
 
di "=== WINNING SPEC: `best_spec_label' (spec `best_spec_num'), mean|SMD| = `best_smd' ===" 
 
// Step 5: Produce post-match balance table and overlap graph for the winner. 
use `spec`best_spec_num'_file', clear 
joint_balance_test "$Xcand" "psm_weight" "psm_matched==1" "PSM (best: `best_spec_label')" 
local jf_p = r(f_p) 
local jmv_p = r(mvtest_p) 
 
iebaltab $Xcand if psm_matched==1 [aw=psm_weight], grpvar($D) /// 
    savexlsx("$out_match/psm_balance_postmatch.xlsx") replace vce(robust) rowvarlabels 
 
twoway (histogram pscore if $D==1, bin(30) color(blue%40)) /// 
    (histogram pscore if $D==0, bin(30) color(red%40)), /// 
    legend(order(1 "Treated" 2 "Control")) title("Propensity Score Overlap (`best_spec_label')") /// 
    xtitle("Propensity score") ytitle("Density") 
graph export "$out_match/psm_pscore_common_support.png", replace width(1200) 
 
regress $Y_main $D [iweight=psm_weight] if psm_matched==1, robust 
 
rank_vars_by_importance $Y_main "$Xpscore" "psm_matched==1" 
local vars_used = r(ordered_vars) 
local this_label "PSM (best: `best_spec_label')" 
 
// Step 6: Upsert the winning result into the shared comparison CSV. 
upsert_effect_row, csvpath(`"$csv_path"') model(`"`this_label'"') method(`"psmatch2"') /// 
    beta(`best_att') se(`best_se') pval(`best_p') n1(`best_nm') n2(`best_nd') /// 
    varsused(`"`vars_used'"') dropcond(`"strpos(Model, "PSM (") == 1"') /// 
    jointfp(`jf_p')
 
di "Done. See $out_match/psm_specification_comparison.csv for all specs." 
di "Winning spec: `best_spec_label' (mean|SMD| = `best_smd')" 
di "Winning spec result written to $out_match/Matching_output_effect_comparison.csv" 
log close 

 
