

*============================================================================== 
* Matching_code_12_cem_did_analysis.do 
* Date: 08/07/2026 
* Author: Aaron Joseph 
* 
* Purpose: Build a comparison group via Coarsened Exact Matching (CEM) 
* against the RCT sample, then estimate a DiD treatment effect on 
* business_practices_sum (2018 pre / 2019 post). 
* 
* Input:  Matching/Output/Matching_output_code_01_comparison_group.dta 
*         Matching/Data/output_code_05_sample.dta 
*         Matching/Data/output_code_04_full_population_sse_2015_2018.dta 
* Output: Matching/Output/Matching_output_effect_comparison.csv (appended) 
*         Matching/Output/output_code_12_cem_did.txt (log) 
* 
* Main steps: 
*   1. Load and stack the RCT sample and comparison pool. 
*   2. Run Coarsened Exact Matching on the stacked sample. 
*   3. Reshape the matched sample to a firm-year panel. 
*   4. Estimate the CEM-matched DiD effect. 
*   5. Upsert the result into the shared comparison CSV. 
*============================================================================== 
 
clear all 
set more off 
set seed 123 
cd "/Users/aaronjoseph/Downloads/Capstone/Felipe" 
 
global out_match "Matching/Output" 
cap mkdir "$out_match" 
cap log close 
log using "$out_match/output_code_12_cem_did.txt", text replace 
 
global Y_base business_practices_sum_2018 
global Y_post business_practices_sum_2019 
global D treatment_assignment_binary 
global Xmatch_exact respondent_gender_2018 business_practices_sum_2018 
global Xcoarse number_employees_RAIS_2016 
global Xmatch $Xmatch_exact $Xcoarse 
 
// Step 1: Load and stack the RCT sample and comparison pool. 
use "Matching/Data/output_code_05_sample.dta", clear 
local need_merge = 0 
foreach v in business_practices_sum_2018 business_practices_sum_2019 $Xmatch { 
    cap confirm variable `v' 
    if _rc local need_merge = 1 
} 
if `need_merge' == 1 { 
    merge 1:1 firm_id using "Matching/Data/output_code_04_full_population_sse_2015_2018.dta", /// 
        keepusing(business_practices_sum_2018 business_practices_sum_2019 $Xmatch) 
    keep if _merge == 3 
    drop _merge 
} 
 
local rebuild_D = 0 
cap confirm variable treatment_assignment_binary 
if _rc { 
    local rebuild_D = 1 
} 
else { 
    quietly count if missing(treatment_assignment_binary) 
    if r(N) == _N { 
        di as error "WARNING: treatment_assignment_binary is fully missing -- rebuilding." 
        drop treatment_assignment_binary 
        local rebuild_D = 1 
    } 
} 
if `rebuild_D' == 1 { 
    gen byte treatment_assignment_binary = (treatment_assignment != 0) if !missing(treatment_assignment) 
} 
quietly count if missing(treatment_assignment_binary) 
 
gen byte in_rct_sample = 1 
tempfile rct_sample 
save `rct_sample' 
 
use "$out_match/Matching_output_code_01_comparison_group.dta", clear 
keep if matching_comparison_group == 1 
gen byte in_rct_sample = 0 
gen byte treatment_assignment_binary = 0 
tempfile comparison_pool 
save `comparison_pool' 
 
use `rct_sample', clear 
append using `comparison_pool' 
local n_prematch = _N 
di "--- Stacked sample loaded: N = " `n_prematch' " ---" 
tab in_rct_sample $D, missing 
 
// Step 2: Run Coarsened Exact Matching on the stacked sample. 
* Explicit coarsening on the one continuous covariate, using meaningful 
* employee-size bands instead of Stata's auto-binning. 
cem $Xmatch_exact $Xcoarse 

 

// Step 2 (continued): Run Coarsened Exact Matching on the stacked sample. 
cem $Xmatch_exact $Xcoarse(0 5 10 20 50 100), treatment($D) 
keep if cem_matched == 1 
local n_matched = _N 
local n_dropped = `n_prematch' - `n_matched' 
di "--- CEM matching complete: N matched = " `n_matched' " (dropped " `n_dropped' ") ---" 
tab $D cem_matched, missing 
 
joint_balance_test "$Xmatch" "" "cem_matched==1" "CEM-matched DiD" 
local jf_p = r(f_p) 
local jmv_p = r(mvtest_p) 
 
* Importance ranking on the matched cross-sectional data, BEFORE the 
* reshape to firm-year panel, using the post-treatment outcome. 
rank_vars_by_importance $Y_post "$Xmatch" "1" 
local vars_used = r(ordered_vars) 
 
// Step 3: Reshape the matched sample to a firm-year panel. 
keep firm_id $D cem_weights $Y_base $Y_post $Xmatch 
rename $Y_base y2018 
rename $Y_post y2019 
reshape long y, i(firm_id) j(year) 
tab year 
 
gen post = (year == 2019) 
gen did = post * $D 
quietly count if missing(did) 
 
// Step 4: Estimate the CEM-matched DiD effect. 
xtset firm_id year 
reghdfe y did [pweight = cem_weights], absorb(firm_id year) vce(cluster firm_id) 
 
di "" 
di "========================================================================" 
di " CEM-matched DiD estimate (did = post x $D):" 
di " coefficient = " _b[did] 
di " SE = " _se[did] 
di "========================================================================" 
 
local beta = _b[did] 
local se = _se[did] 
local p = 2*ttail(e(df_r), abs(`beta'/`se')) 
 
// Step 5: Upsert the result into the shared comparison CSV. 
* n_matched and n_dropped are firm counts, captured before the reshape, 
* consistent with the other matching methods (codes 09, 10, 11, 13). 
local csv_path "$csv_path" 
local this_label "CEM-matched DiD" 
 
upsert_effect_row, csvpath(`"`csv_path'"') model(`"`this_label'"') method(`"cem_did"') /// 
    beta(`beta') se(`se') pval(`p') n1(`n_matched') n2(`n_dropped') /// 
    varsused(`"`vars_used'"') dropcond(`"Model == "`this_label'""') /// 
    jointfp(`jf_p') 

 
di "" 
di "========================================================================" 
di " CEM + DiD analysis complete." 
di " Result written to $out_match/Matching_output_effect_comparison.csv" 
di "========================================================================" 
log close 

 
