*============================================================================== 
* Matching_code_15_dr_specsweep.do 
* Date: 08/07/2026 | Author: Aaron Joseph 
* 
* AIPW and IPWRA, each with logit and probit; winner selected by lowest 
* mean |SMD|. respondent_owner_2018 dropped (collinear on this sample). 
* Output: dr_specification_comparison.csv, dr_pscore_overlap.png, 
*         Matching_output_effect_comparison.csv (appended) 
*============================================================================== 
clear all 
set more off 
cap postutil clear 
cd "/Users/aaronjoseph/Downloads/Capstone/Felipe" 
 
cap log close 
log using "$out_match/output_code_15_dr_analysis.txt", text replace 
 
// Step 1: Load sample and build doubly-robust covariate list. 
use "$out_match/Matching_output_code_03_sample.dta", clear 
di "N = " _N 
tabulate sebrae_regional_office_2018,      generate(reg_office) 
tabulate sebrae_strategic_business_sector, generate(sector) 
cap drop sector9 
tab $D 
 
local dropvar respondent_owner_2018 
local Xcand   "$Xcand" 
local Xdr : list Xcand - dropvar 
di as result "Xdr = `Xdr'" 
 
// Step 2: Pre-estimation balance test (full sample). 
joint_balance_test "`Xdr'" "" "1" "Doubly robust specs (pre-estimation)" 
local jf_p  = r(f_p) 
local jmv_p = r(mvtest_p) 
 
// Helper: mean absolute SMD using ATET weights (treated=1, control=p/(1-p)). 
capture program drop compute_dr_smd 
program define compute_dr_smd, rclass 
    args varlist pscorevar 
    tempvar atetw 
    quietly gen double `atetw' = cond($D==1, 1, `pscorevar' / (1 - `pscorevar')) 
    local sum = 0 
    local n   = 0 
    foreach v of local varlist { 
        quietly summarize `v' if $D==1 [aw=`atetw'] 
        local mT = r(mean) 
        local sT = r(sd) 
        quietly summarize `v' if $D==0 [aw=`atetw'] 
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
 
// Step 3: Run each AIPW/IPWRA specification. 
local labels  aipw_logit aipw_probit ipwra_logit ipwra_probit 
local estim1 aipw 
local link1  logit 
local estim2 aipw 
local link2  probit 
local estim3 ipwra 
local link3  logit 
local estim4 ipwra 
local link4  probit 
local nspecs : word count `labels' 
 
tempname results 
tempfile dr_results_raw 
postfile `results' int spec_num str16 spec_label double beta double se /// 
    double p long n1 long n2 double mean_abs_smd using "`dr_results_raw'", replace 
 
forvalues i = 1/`nspecs' { 
    local lbl : word `i' of `labels' 
    di "=== Spec `i': `lbl' ===" 
 
    cap drop pscore_spec 
    quietly `link`i'' $D `Xdr' 
    predict double pscore_spec if e(sample), pr 
 
    cap noisily teffects `estim`i'' ($Y_main `Xdr') ($D `Xdr', `link`i''), atet 
    if _rc { 
        di as error "Spec `lbl' failed, rc=`=_rc'" 
        post `results' (`i') ("`lbl'") (.) (.) (.) (.) (.) (.) 
        continue 
    } 
 
    matrix b = e(b) 
    matrix V = e(V) 
    local beta_i = b[1,1] 
    local se_i   = sqrt(V[1,1]) 
    local p_i    = 2 * normal(-abs(`beta_i' / `se_i')) 
    quietly count if $D == 1 & e(sample) 
    local n1_i = r(N) 
    quietly count if $D == 0 & e(sample) 
    local n2_i = r(N) 
    compute_dr_smd "`Xdr'" pscore_spec 
    post `results' (`i') ("`lbl'") (`beta_i') (`se_i') (`p_i') (`n1_i') (`n2_i') (r(mean_abs_smd)) 
} 
postclose `results' 
cap drop pscore_spec 
 
use "`dr_results_raw'", clear 
export delimited using "$out_match/dr_specification_comparison.csv", replace 
 
// Step 4: Select winning specification. 
drop if missing(beta) | missing(se) | missing(p) | missing(mean_abs_smd) 
if _N == 0 { 
    di as error "No spec produced a valid estimate. Aborting." 
    exit 459 
} 
sort mean_abs_smd spec_num 
local best_spec_num   = spec_num[1] 
local best_spec_label = spec_label[1] 
local best_beta       = beta[1] 
local best_se         = se[1] 
local best_p          = p[1] 
local best_n1         = n1[1] 
local best_n2         = n2[1] 
local best_smd        = mean_abs_smd[1] 
di "=== WINNING SPEC: `best_spec_label', mean|SMD| = `best_smd' ===" 
 
// Step 5: Overlap graph for the winning spec. 
use "$out_match/Matching_output_code_03_sample.dta", clear 
quietly `link`best_spec_num'' $D `Xdr' 
predict double pscore_best if e(sample), pr 
 
twoway (histogram pscore_best if $D==1, bin(30) color(blue%40)) /// 
       (histogram pscore_best if $D==0, bin(30) color(red%40)),  /// 
    legend(order(1 "Treated" 2 "Control")) xtitle("Propensity score") ytitle("Density") /// 
    title("Propensity Score Overlap (`best_spec_label')") 
graph export "$out_match/dr_pscore_overlap.png", replace width(1200) 
 
// Step 6: Rank covariates and upsert result. 
rank_vars_by_importance $Y_main "`Xdr'" "1" 
local vars_used  = r(ordered_vars) 
local this_label "Doubly Robust (best: `best_spec_label')" 
 
upsert_effect_row, csvpath("$csv_path") model("`this_label'") method("`best_spec_label'") /// 
    beta(`best_beta') se(`best_se') pval(`best_p') n1(`best_n1') n2(`best_n2')            /// 
    varsused("`vars_used'") dropcond(`"strpos(Model, "Doubly Robust (") == 1"')            /// 
    jointfp(`jf_p') 
 
di "Done. Winning spec: `best_spec_label' (mean|SMD| = `best_smd')" 
log close 
 
