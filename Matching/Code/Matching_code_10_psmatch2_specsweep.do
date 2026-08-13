*============================================================================== 
* Matching_code_10_psmatch2_specsweep.do 
* Date: 08/07/2026 | Author: Aaron Joseph 
* 
* Runs psmatch2 under several specifications; selects the winner by lowest 
* mean |SMD|. 
* Output: psm_balance_prematch/postmatch.xlsx, psm_pscore_common_support.png, 
*         psm_specification_comparison.csv, 
*         Matching_output_effect_comparison.csv (appended) 
*============================================================================== 
clear all 
set more off 
set seed 123 
cd "/Users/aaronjoseph/Downloads/Capstone/Felipe" 
 
global out_match "Matching/Output" 
cap mkdir "$out_match" 
cap log close 
log using "$out_match/output_code_10_psm.txt", text replace 
 
global Y_main   business_practices_sum_2019 
global D        treatment_assignment_binary 
global Xcand    respondent_age_2018 respondent_gender_2018 business_practices_sum_2018 /// 
                years_functioning_2018 competition_density_full_zipco               /// 
                total_services_2015_2018 respondent_owner_2018                       /// 
                number_employees_RAIS_2016 sse_2018_only 
global Xpscore  respondent_gender_2018 business_practices_sum_2018 number_employees_RAIS_2016 
 
// Step 1: Load sample and pre-matching balance. 
use "$out_match/Matching_output_code_03_sample.dta", clear 
di "N = " _N 
tab $D 
iebaltab $Xcand, grpvar($D) savexlsx("$out_match/psm_balance_prematch.xlsx") /// 
    replace vce(robust) rowvarlabels 
 
// Step 2: Define candidate psmatch2 specifications. 
local labels  default_nn1 nn1_noreplace nn3 nn5 nn1_caliper radius kernel llr 
local opts1   neighbor(1) common 
local opts2   neighbor(1) noreplacement common 
local opts3   neighbor(3) common 
local opts4   neighbor(5) common 
local opts5   neighbor(1) caliper(0.01) common 
local opts6   radius caliper(0.01) common 
local opts7   kernel kerneltype(normal) bwidth(0.06) common 
local opts8   llr bwidth(0.06) common 
local nspecs : word count `labels' 
 
// Helper: mean absolute SMD across $Xcand on the matched/weighted sample. 
capture program drop compute_mean_abs_smd 
program define compute_mean_abs_smd, rclass 
    args varlist wtvar touse 
    local sum = 0 
    local n   = 0 
    foreach v of local varlist { 
        quietly summarize `v' if $D==1 & `touse' [aw=`wtvar'] 
        local mT = r(mean) 
        local sT = r(sd) 
        quietly summarize `v' if $D==0 & `touse' [aw=`wtvar'] 
        local mC = r(mean) 
        local sC = r(sd) 
        local sd_pool = sqrt((`sT'^2 + `sC'^2) / 2) 
        if `sd_pool' > 0 & !missing(`mT') & !missing(`mC') { 
            local sum = `sum' + abs((`mT' - `mC') / `sd_pool') 
            local n   = `n' + 1 
        } 
    } 
    return scalar mean_abs_smd = cond(`n' > 0, `sum' / `n', .) 
end 
 
tempname results 
tempfile psm_results_raw 
postfile `results' int spec_num str20 spec_label long n_matched long n_dropped /// 
    double att double se double p double mean_abs_smd using "`psm_results_raw'", replace 
 
forvalues i = 1/`nspecs' { 
	tempfile spec`i'_file 
} 
 
// Step 3: Run each specification. 
forvalues i = 1/`nspecs' { 
    local lbl    : word `i' of `labels' 
    local optsi  "opts`i'" 
    di "=== Spec `i': `lbl' -- ``optsi'' ===" 
 
    use "$out_match/Matching_output_code_03_sample.dta", clear 
    cap noisily psmatch2 $D $Xpscore, ``optsi'' logit 
    if _rc { 
        di as error "Spec `lbl' failed, rc=`=_rc'" 
        post `results' (`i') ("`lbl'") (.) (.) (.) (.) (.) (.) 
        continue 
    } 
 
    rename _pscore  pscore 
    rename _weight  psm_weight 
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
        local p = 2 * ttail(e(df_r), abs(`b' / `s')) 
        post `results' (`i') ("`lbl'") (`nm') (`nd') (`b') (`s') (`p') (`smd') 
        save `spec`i'_file', replace 
    } 
} 
postclose `results' 
 
use "`psm_results_raw'", clear 
export delimited using "$out_match/psm_specification_comparison.csv", replace 
 
// Step 4: Select winning specification (lowest mean |SMD|). 
drop if missing(att) | missing(se) | missing(p) | missing(mean_abs_smd) 
if _N == 0 { 
    di as error "No spec produced a valid estimate + balance metric. Aborting." 
    exit 459 
} 
sort mean_abs_smd spec_num 
local best_spec_num   = spec_num[1] 
local best_spec_label = spec_label[1] 
local best_att        = att[1] 
local best_se         = se[1] 
local best_p          = p[1] 
local best_nm         = n_matched[1] 
local best_nd         = n_dropped[1] 
local best_smd        = mean_abs_smd[1] 
di "=== WINNING SPEC: `best_spec_label' (spec `best_spec_num'), mean|SMD| = `best_smd' ===" 
 
// Step 5: Post-match balance and overlap graph for the winner. 
use `spec`best_spec_num'_file', clear 
joint_balance_test "$Xcand" "psm_weight" "psm_matched==1" "PSM (best: `best_spec_label')" 
local jf_p  = r(f_p) 
local jmv_p = r(mvtest_p) 
 
iebaltab $Xcand if psm_matched==1 [aw=psm_weight], grpvar($D) /// 
    savexlsx("$out_match/psm_balance_postmatch.xlsx") replace vce(robust) rowvarlabels 
 
twoway (histogram pscore if $D==1, bin(30) color(blue%40)) /// 
       (histogram pscore if $D==0, bin(30) color(red%40)),  /// 
    legend(order(1 "Treated" 2 "Control")) xtitle("Propensity score") ytitle("Density") /// 
    title("Propensity Score Overlap (`best_spec_label')") 
graph export "$out_match/psm_pscore_common_support.png", replace width(1200) 
 
regress $Y_main $D [iweight=psm_weight] if psm_matched==1, robust 
rank_vars_by_importance $Y_main "$Xpscore" "psm_matched==1" 
local vars_used  = r(ordered_vars) 
local this_label "PSM (best: `best_spec_label')" 
 
// Step 6: Upsert winning result. 
upsert_effect_row, csvpath("$csv_path") model("`this_label'") method("psmatch2") /// 
    beta(`best_att') se(`best_se') pval(`best_p') n1(`best_nm') n2(`best_nd')    /// 
    varsused("`vars_used'") dropcond(`"strpos(Model, "PSM (") == 1"')              /// 
    jointfp(`jf_p') 
 
di "Done. Winning spec: `best_spec_label' (mean|SMD| = `best_smd')" 
log close 
