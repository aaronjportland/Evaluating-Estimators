*============================================================================= 
* Matching_code_09_diffmeans_analysis.do 
* 
* Purpose: Basic unadjusted difference-in-means comparison of treated vs. 
* control firms, before any matching/weighting is applied. Naive baseline 
* benchmark against the matched-sample estimates in codes 10-14. 
* 
* Requires: Matching_code_08_setup.do already run this session. 
* 
* Input:  Matching/Output/Matching_output_code_03_sample.dta 
* Output: Matching/Output/Matching_output_effect_comparison.csv (appended) 
*         Matching/Output/output_code_09_diffmeans.txt (log) 
* 
* Author: Aaron Joseph 
*============================================================================= 
cap log close 
log using "$out_match/output_code_09_diffmeans.txt", text replace 
 
use "$out_match/Matching_output_code_03_sample.dta", clear 
di "N = " _N 
tab $D 
 
* Diff-in-means has no matched sample to balance-check against, so the 
* joint balance test runs on the full unadjusted sample here only. 
joint_balance_test "$Xcand" "" "1" "Pre-matching (unadjusted sample)" 
local jf_p = r(f_p) 
local jmv_p = r(mvtest_p) 
 
quietly ttest $Y_main, by($D) 
local beta = r(mu_2) - r(mu_1) 
local se = r(se) 
local t = r(t) 
local df = r(df_t) 
local p = 2*ttail(`df', abs(`t')) 
local n1 = r(N_1) 
local n2 = r(N_2) 
 
* No covariate adjustment here -- record that explicitly. 
local vars_used "None (unadjusted t-test)" 
local this_label "Diff-in-means (unadjusted)" 
 
upsert_effect_row, csvpath(`"$csv_path"') model(`"`this_label'"') method(`"diffmeans"') /// 
	coefname(`"diff"') beta(`beta') se(`se') pval(`p') n1(`n2') n2(`n1') /// 
	varsused(`"`vars_used'"') dropcond(`"Model == "`this_label'""') /// 
	jointfp(`jf_p') jointmvtestp(`jmv_p') 
 
di "Done. Result written to $out_match/Matching_output_effect_comparison.csv" 
log close 
 
 
 

 

 

 