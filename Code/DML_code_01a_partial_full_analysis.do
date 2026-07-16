*========================================================================= 
* DML_code_01a_partial_full_analysis.do 
* 
* Double/Debiased Machine Learning -- Primary (Full-Sample) Analysis 
* 
* Purpose: Estimate the effect of treatment_assignment on 
*          business_practices_sum_2019 using the DML partial 
*          (interactive/AIPW) model on the full analysis sample. 
* 
* Input:   Experiment/Output/output_code_05_sample.dta 
* Output:  DML/Output/dml_partial_full.ster 
*          DML/Output/dml_partial_full_pscore_hist.png 
* 
* Author:  Aaron Joseph 
* Date: 
*========================================================================= 
 
*------------------------------------------------------------------------- 
* Part 0: Settings 
*------------------------------------------------------------------------- 
clear all 
set more off 
set seed 123 
 
* Set working directory before running 
cd "/Users/aaronjoseph/Downloads/Capstone/Felipe" 
 
*------------------------------------------------------------------------- 
* Part 1: Globals 
*------------------------------------------------------------------------- 
global Y_main business_practices_sum_2019 
global D       treatment_assignment 
 
* Continuous covariates only -- used for c.()##c.() interaction 
* expansions in Lasso/Ridge (c. cannot be applied to i. terms) 
global Xcont business_practices_sum_2018 years_functioning_2018 /// 
    respondent_gender_2018 respondent_type_2018 /// 
    number_employees_RAIS_2016 competition_density_full_zipco /// 
    Q1_respondent_educ_level_2018 Q2_respondent_busin_experi_2018 /// 
    Q13_respondent_risk_averse_2018 
 
global X $Xcont i.randomization_strata 
 
global out_dml "DML/Output" 

cap mkdir "DML" 
cap mkdir "$out_dml" 
 
* Propensity-score trimming band for diagnostics 
global pscore_lo 0.05 
global pscore_hi 0.95 
 
*------------------------------------------------------------------------- 
* Part 2: Load data and handle missing values 
*------------------------------------------------------------------------- 
use "Experiment/Output/output_code_05_sample.dta", clear 
di "Full analysis sample loaded. N = " _N 
 
* Generate a missing-indicator and zero-fill each covariate 
local missnames 
foreach var of varlist $Xcont { 
    capture confirm numeric variable `var' 
    if !_rc { 
        local missname = substr("`var'", 1, 27) + "_miss" 
        capture drop `missname' 
        gen `missname' = missing(`var') 
        replace `var' = 0 if missing(`var') 
        local missnames `missnames' `missname' 
    } 
} 
 
* Add missing-indicators (themselves continuous 0/1) to both globals 
global X $X `missnames' 
global Xcont $Xcont `missnames' 
 
di "X : $X" 
di "Xcont: $Xcont" 
 
*------------------------------------------------------------------------- 
* Part 3: Pre-estimation diagnostics 
*------------------------------------------------------------------------- 
 
* 3a. Fold-size check relative to Lasso/Ridge interaction count 
local kfolds = 4 
local n_xcont : word count $Xcont 
local n_interact = `n_xcont' * (`n_xcont' + 1) / 2 
qui count 
local per_fold = floor(r(N) / `kfolds') 
 
di "N = " r(N) ", kfolds = `kfolds', ~N/fold = `per_fold', interaction terms = `n_interact'" 
if `per_fold' < 10 * `n_interact' { 
    di as error "WARNING: per-fold N is small relative to the number of Lasso/Ridge interaction terms." 
} 
 
* 3b. Covariate balance across treatment arms (joint F-test; handles >2 arms) 
di "--- Covariate balance: $Xcont by $D ---" 
foreach var of varlist $Xcont { 
    qui regress `var' i.$D 
    qui testparm i.$D 
    di "`var': balance p-value = " %5.3f r(p) 
} 
 
*------------------------------------------------------------------------- 
* Part 4: DML partial (AIPW) estimation, full sample 
*------------------------------------------------------------------------- 
di "--- DML: Full sample ---" 
 
ddml init partial, kfolds(4) reps(5) 
 
ddml E[Y|X]: pystacked $Y_main $X /// 
    || method(ols) /// 
    || m(lassocv) xvars(c.($Xcont)##c.($Xcont) i.randomization_strata) /// 
    || m(ridgecv) xvars(c.($Xcont)##c.($Xcont) i.randomization_strata) /// 
    || m(rf) pipe(sparse) opt(max_features(5)) /// 
    || m(gradboost) pipe(sparse) opt(n_estimators(250) learning_rate(0.01)), /// 
    njobs(5) 
 
ddml E[D|X]: pystacked $D $X /// 
    || method(ols) /// 
    || m(lassocv) xvars(c.($Xcont)##c.($Xcont) i.randomization_strata) /// 
    || m(ridgecv) xvars(c.($Xcont)##c.($Xcont) i.randomization_strata) /// 
    || m(rf) pipe(sparse) opt(max_features(5)) /// 
    || m(gradboost) pipe(sparse) opt(n_estimators(250) learning_rate(0.01)), /// 
    njobs(5) 
 
qui ddml crossfit 
ddml estimate, robust 
 
estimates store dml_partial_full 
estimates save "$out_dml/dml_partial_full.ster", replace 
 
*------------------------------------------------------------------------- 
* Part 5: Propensity-score (E[D|X]) diagnostics 
*------------------------------------------------------------------------- 
 
* Run ddml describe if the variable name below doesn't match your 
* ddml/pystacked version's naming convention. 
cap confirm variable D_pystacked 
if !_rc { 
    summarize D_pystacked, detail 
    count if D_pystacked < $pscore_lo | D_pystacked > $pscore_hi 
    di "Observations outside [$pscore_lo, $pscore_hi]: " r(N) 
 
    histogram D_pystacked, /// 
        title("Estimated propensity score, full sample") /// 
        xline($pscore_lo $pscore_hi, lcolor(red)) /// 
        name(pscore_full, replace) 
 
    graph export "$out_dml/dml_partial_full_pscore_hist.png", replace width(1200) 
} 
else { 
    di as text "NOTE: D-hat variable not found under expected name; run 'ddml describe'." 
} 
 
*------------------------------------------------------------------------- 
* Part 6: Summary 
*------------------------------------------------------------------------- 
di "Primary DML analysis complete. Estimates saved to $out_dml/dml_partial_full.ster" 
di "Compare against subgroup estimates in DML_code_02_subgroup_analysis.do via:" 
di "  estimates table dml_partial_full dml_high_competition dml_low_competition ///" 
di "    dml_rdd_subsample, b star stats(N)" 
 
* Save processed sample for downstream files (subgroup analysis depends 
* on this exact processed dataset + covariate list). 
save "$out_dml/dml_partial_processed.dta", replace 
