*============================================================================== 
* Matching_code_11_cem_analysis.do 
* Date: 08/07/2026 | Author: Aaron Joseph 
* 
* Estimates the treatment effect via Coarsened Exact Matching. 
* Input:  Matching/Output/Matching_output_code_03_sample.dta 
* Output: Matching/Output/Matching_output_effect_comparison.csv (appended) 
*         Matching/Output/output_code_11_cem.txt (log) 
*============================================================================== 
cap log close 
log using "$out_match/output_code_11_cem.txt", text replace 
 
// Step 1: Load sample and pre-matching balance. 
use "$out_match/Matching_output_code_03_sample.dta", clear 
di "Matching sample loaded. N = " _N 
tab $D 
iebaltab $Xcand, grpvar($D) savexlsx("$out_match/cem_balance_prematch.xlsx") /// 
    replace vce(robust) rowvarlabels 
joint_balance_test "$Xcand" "" "1" "CEM (PSM variables)" 
local jf_p  = r(f_p) 
local jmv_p = r(mvtest_p) 
 
// Step 2: Run CEM. 
cem $Xcem, treatment($D) 
quietly count if cem_matched == 1 
local n_matched = r(N) 
quietly count if cem_matched == 0 
local n_dropped = r(N) 
di "N matched: `n_matched'  |  N dropped: `n_dropped'" 
 
// Step 3: Post-matching balance. 
iebaltab $Xcand if cem_matched==1 [aw=cem_weights], grpvar($D) /// 
    savexlsx("$out_match/cem_balance_postmatch.xlsx") replace vce(robust) rowvarlabels 
 
// Step 4: CEM-weighted treatment effect. 
regress $Y_main $D [iweight=cem_weights], robust 
local beta = _b[$D] 
local se   = _se[$D] 
local p    = 2 * ttail(e(df_r), abs(`beta' / `se')) 
 
// Step 5: Rank covariates and upsert result. 
rank_vars_by_importance $Y_main "$Xcem" "cem_matched==1" 
local vars_used  = r(ordered_vars) 
local this_label "CEM (PSM variables)" 
 
upsert_effect_row, csvpath("$csv_path") model("`this_label'") method("cem") /// 
    beta(`beta') se(`se') pval(`p') n1(`n_matched') n2(`n_dropped')         /// 
    varsused("`vars_used'") dropcond(`"Model == "`this_label'""')            /// 
    jointfp(`jf_p') 
 
di "CEM analysis complete. Matched N: `n_matched'" 
log close 
