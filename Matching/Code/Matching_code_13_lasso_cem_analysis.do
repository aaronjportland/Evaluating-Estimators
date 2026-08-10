*============================================================================== 
* Matching_code_13_lasso_cem_analysis.do 
* Date: 08/07/2026 | Author: Aaron Joseph 
* 
* Adaptive LASSO selects predictors of $D; selected variables used as CEM 
* coarsening dimensions. 
* Output: lasso_selected_vars.txt, lasso_cem_balance_prematch/postmatch.xlsx, 
*         Matching_output_effect_comparison.csv (appended) 
*============================================================================== 
clear all 
set more off 
set seed 12345 
cd "/Users/aaronjoseph/Downloads/Capstone/Felipe" 
 
global out_match "Matching/Output" 
cap mkdir "$out_match" 
cap log close 
log using "$out_match/output_code_13_lasso_cem.txt", text replace 
 
global Y_main business_practices_sum_2019 
global D      treatment_assignment_binary 
 
// Step 1: Load sample and build candidate covariate list. 
use "$out_match/Matching_output_code_03_sample.dta", clear 
di "Matching sample loaded. N = " _N 
tab $D 
 
tabulate sebrae_regional_office_2018,       generate(reg_office) 
tabulate sebrae_strategic_business_sector,  generate(sector) 
 
global Xcand respondent_age_2018 respondent_gender_2018             /// 
             business_practices_sum_2018 years_functioning_2018     /// 
             competition_density_full_zipco total_services_2015_2018 /// 
             respondent_owner_2018 number_employees_RAIS_2016 sse_2018_only /// 
             reg_office2 reg_office3 reg_office4 reg_office5 reg_office6   /// 
             sector2 sector3 sector4 sector5 sector6 sector7 sector8 sector10 
 
// Drop zero-variance candidates before LASSO. 
local Xcand_clean 
foreach v of global Xcand { 
    quietly sum `v' 
    if r(sd) > 0 & !missing(r(sd)) local Xcand_clean `Xcand_clean' `v' 
    else di as error "Dropping `v': zero variance." 
} 
global Xcand `Xcand_clean' 
 
// Step 2: Adaptive LASSO to select predictors of treatment. 
lasso logit $D $Xcand, selection(adaptive) 
lassocoef, display(coef) 
matrix b    = e(b) 
local Xlasso : colnames b 
local Xlasso : subinstr local Xlasso "_cons" "", word 
local nsel  : word count `Xlasso' 
local ncand : word count $Xcand 
di "Adaptive LASSO selected `nsel' / `ncand' variables: `Xlasso'" 
 
tempname fh 
file open `fh' using "$out_match/lasso_selected_vars.txt", write replace 
file write `fh' "Adaptive LASSO-selected variables (predictors of $D):" _n /// 
    "`Xlasso'" _n "N selected: `nsel' / `ncand'" _n 
file close `fh' 
 
iebaltab `Xlasso', grpvar($D) savexlsx("$out_match/lasso_cem_balance_prematch.xlsx") /// 
    replace vce(robust) rowvarlabels 
 
// Step 3: CEM on LASSO-selected covariates. 
cem `Xlasso', treatment($D) 
quietly count if cem_matched == 1 
local n_matched = r(N) 
quietly count if cem_matched == 0 
local n_dropped = r(N) 
di "N matched: `n_matched'  |  N dropped: `n_dropped'" 
tab $D cem_matched 
 
// Step 4: Post-matching balance. 
iebaltab `Xlasso' if cem_matched==1 [aw=cem_weights], grpvar($D) /// 
    savexlsx("$out_match/lasso_cem_balance_postmatch.xlsx") replace vce(robust) rowvarlabels 
joint_balance_test "`Xlasso'" "" "cem_matched==1" "LASSO(adaptive)+CEM" 
local jf_p  = r(f_p) 
local jmv_p = r(mvtest_p) 
 
// Step 5: CEM-weighted treatment effect. 
regress $Y_main $D [iweight=cem_weights] if cem_matched==1, robust 
local beta = _b[$D] 
local se   = _se[$D] 
local p    = 2 * ttail(e(df_r), abs(`beta' / `se')) 
 
// Step 6: Rank covariates and upsert result. 
rank_vars_by_importance $Y_main "`Xlasso'" "cem_matched==1" 
local vars_used  = r(ordered_vars) 
local this_label "LASSO(adaptive)+CEM" 
 
upsert_effect_row, csvpath("$csv_path") model("`this_label'") method("lasso_cem") /// 
    beta(`beta') se(`se') pval(`p') n1(`n_matched') n2(`n_dropped')               /// 
    varsused("`vars_used'") dropcond(`"Model == "`this_label'""')                  /// 
    jointfp(`jf_p') 
 
di "LASSO+CEM complete. Selected: `Xlasso' | Matched N: `n_matched'" 
log close 
