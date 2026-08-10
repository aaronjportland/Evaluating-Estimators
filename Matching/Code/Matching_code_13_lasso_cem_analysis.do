*============================================================================== 
* Matching_code_13_lasso_cem_analysis.do 
* Date: 08/07/2026 
* Author: Aaron Joseph 
* 
* Purpose: Use adaptive LASSO to select covariates as predictors of $D, then 
* use the selected variables as CEM coarsening dimensions and estimate the 
* treatment effect on the matched sample. 
* 
* Input:  Matching/Output/Matching_output_code_03_sample.dta 
* Output: Matching/Output/lasso_selected_vars.txt 
*         Matching/Output/lasso_cem_balance_prematch.xlsx, _postmatch.xlsx 
*         Matching/Output/Matching_output_effect_comparison.csv (appended) 
*         Matching/Output/output_code_13_lasso_cem.txt (log) 
* 
* Main steps: 
*   1. Load the matching sample and build the candidate covariate list. 
*   2. Run adaptive LASSO to select predictors of treatment. 
*   3. Run CEM on the LASSO-selected covariates. 
*   4. Check post-matching balance. 
*   5. Estimate the CEM-weighted treatment effect. 
*   6. Rank covariates by importance and upsert the result. 
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
global D treatment_assignment_binary 
 
// Step 1: Load the matching sample and build the candidate covariate list. 
use "$out_match/Matching_output_code_03_sample.dta", clear 
di "Matching sample loaded. N = " _N 
tab $D 
 
tabulate sebrae_regional_office_2018, generate(reg_office) 
tabulate sebrae_strategic_business_sector, generate(sector) 
 
global Xcand respondent_age_2018 respondent_gender_2018 /// 
    business_practices_sum_2018 years_functioning_2018 /// 
    competition_density_full_zipco total_services_2015_2018 /// 
    respondent_owner_2018 number_employees_RAIS_2016 sse_2018_only /// 
    reg_office2 reg_office3 reg_office4 reg_office5 reg_office6 /// 
    sector2 sector3 sector4 sector5 sector6 sector7 sector8 sector10 
 
di "--- Running adaptive LASSO variable selection (predictors of $D) ---" 
local Xcand_clean 
foreach v of global Xcand { 
    quietly sum `v' 
    if r(sd) > 0 & !missing(r(sd)) { 
        local Xcand_clean `Xcand_clean' `v' 
    } 
    else { 
        di as error "Dropping `v' from candidate set: zero variance (constant)." 
    } 
} 
global Xcand `Xcand_clean' 
local ncand : word count $Xcand 
 
// Step 2: Run adaptive LASSO to select predictors of treatment. 
lasso logit $D $Xcand, selection(adaptive) 
lassocoef, display(coef) 

matrix b = e(b) 
local Xlasso : colnames b 
local Xlasso : subinstr local Xlasso "_cons" "", word 
local nsel : word count `Xlasso' 
local ncand : word count $Xcand 
di "--- Adaptive LASSO-selected variables ---" 
di "`Xlasso'" 
di "Number of variables selected: `nsel' (out of `ncand')" 
 
tempname lasso_fh 
file open `lasso_fh' using "$out_match/lasso_selected_vars.txt", write replace 
file write `lasso_fh' "Adaptive LASSO-selected variables (predictors of $D):" _n 
file write `lasso_fh' "`Xlasso'" _n 
file write `lasso_fh' "N selected: `nsel' / `ncand'" _n 
file close `lasso_fh' 
 
di "--- Pre-matching balance: adaptive LASSO-selected covariates ---" 
iebaltab `Xlasso', grpvar($D) savexlsx("$out_match/lasso_cem_balance_prematch.xlsx") /// 
    replace vce(robust) rowvarlabels 
 
// Step 3: Run CEM on the LASSO-selected covariates. 
di "--- Running CEM on adaptive LASSO-selected covariates ---" 
cem `Xlasso', treatment($D) 
count if cem_matched == 1 
local n_matched = r(N) 
count if cem_matched == 0 
local n_dropped = r(N) 
di "N matched: `n_matched'" 
di "N dropped: `n_dropped'" 
tab $D cem_matched 
 
// Step 4: Check post-matching balance. 
di "--- Post-matching balance: LASSO+CEM matched sample ---" 
iebaltab `Xlasso' if cem_matched == 1 [aw = cem_weights], grpvar($D) /// 
    savexlsx("$out_match/lasso_cem_balance_postmatch.xlsx") replace vce(robust) rowvarlabels 
 
joint_balance_test "`Xlasso'" "" "cem_matched==1" "LASSO(adaptive)+CEM" 
local jf_p = r(f_p) 
local jmv_p = r(mvtest_p) 
 
// Step 5: Estimate the CEM-weighted treatment effect. 
di "--- CEM-weighted treatment effect (adaptive LASSO-selected covariates) ---" 
regress $Y_main $D [iweight = cem_weights] if cem_matched == 1, robust 
 
local beta = _b[$D] 
local se = _se[$D] 
local df = e(df_r) 
local p = 2*ttail(`df', abs(`beta'/`se')) 
 
// Step 6: Rank covariates by importance and upsert the result. 
rank_vars_by_importance $Y_main "`Xlasso'" "cem_matched==1" 
local vars_used = r(ordered_vars) 
 
local csv_path "$out_match/Matching_output_effect_comparison.csv" 
local this_label "LASSO(adaptive)+CEM" 
 
upsert_effect_row, csvpath(`"`csv_path'"') model(`"`this_label'"') method(`"lasso_cem"') /// 
    beta(`beta') se(`se') pval(`p') n1(`n_matched') n2(`n_dropped') /// 
    varsused(`"`vars_used'"') dropcond(`"Model == "`this_label'""') /// 
    jointfp(`jf_p')
 
di "" 
di "========================================================================" 
di " LASSO (adaptive) + CEM analysis complete." 
di " Selected variables: `Xlasso'" 
di " N selected: `nsel' / `ncand'" 
di " Matched N: `n_matched' | Dropped N: `n_dropped'" 
di " Result written to $out_match/Matching_output_effect_comparison.csv" 
di "========================================================================" 
log close 
