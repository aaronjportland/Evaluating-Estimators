*============================================================================== 
* Matching_code_09_diffmeans_analysis.do 
* Date: 08/07/2026 | Author: Aaron Joseph 
* 
* Unadjusted difference-in-means: naive baseline benchmark. 
* Input:  Matching/Output/Matching_output_code_03_sample.dta 
* Output: Matching/Output/Matching_output_effect_comparison.csv (appended) 
*         Matching/Output/output_code_09_diffmeans.txt (log) 
*============================================================================== 
cap log close 
log using "$out_match/output_code_09_diffmeans.txt", text replace 
 
// Step 1: Load the matching sample. 
use "$out_match/Matching_output_code_03_sample.dta", clear 
di "N = " _N 
tab $D 
 
// Step 2: Pre-matching balance test (full unadjusted sample). 
joint_balance_test "$Xcand" "" "1" "Pre-matching (unadjusted sample)" 
local jf_p  = r(f_p) 
local jmv_p = r(mvtest_p) 
 
// Step 3: Unadjusted t-test. 
quietly ttest $Y_main, by($D) 
local beta = r(mu_2) - r(mu_1) 
local se   = r(se) 
local p    = 2 * ttail(r(df_t), abs(r(t))) 
local n1   = r(N_2)   // treated (D=1) 
local n2   = r(N_1)   // control (D=0) 
 
// Step 4: Upsert result. 
local this_label "Diff-in-means (unadjusted)" 
upsert_effect_row, csvpath("$csv_path") model("`this_label'") method("diffmeans") /// 
    beta(`beta') se(`se') pval(`p') n1(`n1') n2(`n2')                             /// 
    varsused("None (unadjusted t-test)") dropcond(`"Model == "`this_label'""')    /// 
    jointfp(`jf_p') 
 
di "Done." 
log close 
