*============================================================================== 
* Matching_code_09_diffmeans_analysis.do 
* Date: 08/07/2026 
* Author: Aaron Joseph 
* 
* Purpose: Basic unadjusted difference-in-means comparison of treated vs. 
* control firms, before any matching/weighting is applied. Naive baseline 
* benchmark against the matched-sample estimates in codes 10-15. 
* 
* Input:  Matching/Output/Matching_output_code_03_sample.dta 
* Output: Matching/Output/Matching_output_effect_comparison.csv (appended) 
*         Matching/Output/output_code_09_diffmeans.txt (log) 
* 
* Main steps: 
*   1. Load the matching sample. 
*   2. Run the joint balance test on the full unadjusted sample. 
*   3. Run the unadjusted t-test comparison. 
*   4. Upsert the result into the shared comparison CSV. 
*============================================================================== 
 
cap log close 
log using "$out_match/output_code_09_diffmeans.txt", text replace 
 
// Step 1: Load the matching sample. 
use "$out_match/Matching_output_code_03_sample.dta", clear 
di "N = " _N 
tab $D 
 
// Step 2: Run the joint balance test on the full unadjusted sample. 
* Diff-in-means has no matched sample to balance-check against, so the 
* joint balance test runs on the full unadjusted sample here only. 
joint_balance_test "$Xcand" "" "1" "Pre-matching (unadjusted sample)" 
local jf_p = r(f_p) 
local jmv_p = r(mvtest_p) 
 
// Step 3: Run the unadjusted t-test comparison. 
quietly ttest $Y_main, by($D) 
local beta = r(mu_2) - r(mu_1) 
local se = r(se) 
local t = r(t) 
local df = r(df_t) 
local p = 2*ttail(`df', abs(`t')) 
* r(N_1) = control (D=0), r(N_2) = treated (D=1) -- assign correctly. 
local n1 = r(N_2)   // treated count -> N_Treated_or_Matched 
local n2 = r(N_1)   // control count -> N_Control_or_Dropped 
 
* No covariate adjustment here -- record that explicitly. 
local vars_used "None (unadjusted t-test)" 
local this_label "Diff-in-means (unadjusted)" 
 
// Step 4: Upsert the result into the shared comparison CSV. 
upsert_effect_row, csvpath(`"$csv_path"') model(`"`this_label'"') method(`"diffmeans"') /// 
    beta(`beta') se(`se') pval(`p') n1(`n1') n2(`n2') /// 
    varsused(`"`vars_used'"') dropcond(`"Model == "`this_label'""') /// 
    jointfp(`jf_p')
 
di "Done. Result written to $out_match/Matching_output_effect_comparison.csv" 
log close 
