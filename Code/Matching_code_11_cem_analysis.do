
*============================================================================= 
* Matching_code_11_cem_analysis.do 
* 
* Purpose: Estimate the effect of $D on $Y_main via Coarsened Exact Matching. 
* 
* Requires: Matching_code_00_setup.do already run this session. 
* 
* Author: Aaron Joseph 
*============================================================================= 
cap log close 
log using "$out_match/output_code_10_cem.txt", text replace 
 
use "$out_match/Matching_output_code_03_sample.dta", clear 
di "Matching sample loaded. N = " _N 
tab $D 
 
di "--- Pre-matching balance: candidate covariates ---" 
iebaltab $Xcand, grpvar($D) savexlsx("$out_match/cem_balance_prematch.xlsx") /// 
	replace vce(robust) rowvarlabels 
 
joint_balance_test "$Xcand" "" "1" "CEM (PSM variables)" 
local jf_p = r(f_p) 
local jmv_p = r(mvtest_p) 
 
di "--- Running CEM ---" 
cem $Xcem, treatment($D) 
 
count if cem_matched == 1 
local n_matched = r(N) 
count if cem_matched == 0 
local n_dropped = r(N) 
di "N matched: `n_matched'" 
di "N dropped: `n_dropped'" 
 
di "--- Post-matching balance: matched sample ---" 
iebaltab $Xcand if cem_matched == 1 [aw = cem_weights], grpvar($D) /// 
	savexlsx("$out_match/cem_balance_postmatch.xlsx") replace vce(robust) rowvarlabels 
 
di "--- CEM-weighted treatment effect ---" 
regress $Y_main $D [iweight = cem_weights], robust 
local beta = _b[$D] 
local se = _se[$D] 
local df = e(df_r) 
local p = 2*ttail(`df', abs(`beta'/`se')) 
 
rank_vars_by_importance $Y_main "$Xcem" "cem_matched==1" 
local vars_used = r(ordered_vars) 
 
local this_label "CEM (PSM variables)" 
 
upsert_effect_row, csvpath(`"$csv_path"') model(`"`this_label'"') method(`"cem"') /// 
	coefname(`"beta"') beta(`beta') se(`se') pval(`p') n1(`n_matched') n2(`n_dropped') /// 
	varsused(`"`vars_used'"') dropcond(`"Model == "`this_label'""') /// 
	jointfp(`jf_p') jointmvtestp(`jmv_p') 
 
di "CEM analysis complete. Matched N: `n_matched'" 
log close 
