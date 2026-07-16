 
*========================================================================= 
* DML_code_02a_subgroup_analysis.do 
* 
* Double/Debiased Machine Learning -- Subgroup Analysis 
* 
* Purpose: Repeats the DML partial-model analysis on subgroups defined 
*          by competition strata and firm characteristics. 
* 
* REQUIRES: DML_code_01a_partial_full_analysis.do must be run first -- 
* this file loads its processed dataset and reuses its globals rather 
* than re-deriving them, and its Part 5 comparison table depends on 
* dml_partial_full.ster already existing. 
* 
* Three subgroups are estimated via a single generalized program: 
*   (1) High competition environment (competition_strata == 1) 
*   (2) Low competition environment  (competition_strata == 0) 
*   (3) Matching subsample -- same eligibility population used in 
*       Matching_code_01_adding_comparison_group.do 
* 
* Input:  DML/Output/dml_partial_processed.dta (from file 01) 
* Output: DML/Output/dml_partial_highcomp.ster 
*         DML/Output/dml_partial_lowcomp.ster 
*         DML/Output/dml_partial_match.ster 
*         DML/Output/<outname>_pscore_hist.png (per subgroup) 
* 
* Author: Aaron Joseph 
* Date:   08/15/2025 (revised) 
*========================================================================= 
 
*------------------------------------------------------------------------- 
* Part 0: Settings 
*------------------------------------------------------------------------- 
clear all 
set more off 
set seed 123 
cd "/Users/aaronjoseph/Downloads/Capstone/Felipe" 
 
global out_dml "DML/Output" 
 
*------------------------------------------------------------------------- 
* Part 1: Globals (must match DML_code_01_partial_full_analysis.do) 
*------------------------------------------------------------------------- 
global Y_main business_practices_sum_2019 
global D      treatment_assignment 
 
global Xcont business_practices_sum_2018 years_functioning_2018 /// 
    respondent_gender_2018 respondent_type_2018 /// 
    number_employees_RAIS_2016 competition_density_full_zipco /// 
    Q1_respondent_educ_level_2018 Q2_respondent_busin_experi_2018 /// 
    Q13_respondent_risk_averse_2018 
 
global pscore_lo 0.05 
global pscore_hi 0.95 
 
*------------------------------------------------------------------------- 
* Part 2: Load processed data from DML_code_01_partial_full_analysis.do 
*------------------------------------------------------------------------- 
cap confirm file "$out_dml/dml_partial_processed.dta" 
if _rc { 
    di as error "ERROR: $out_dml/dml_partial_processed.dta not found." 
    di as error "Run DML_code_01_partial_full_analysis.do first -- this file depends on its processed output." 
    exit 601 
} 
use "$out_dml/dml_partial_processed.dta", clear 
di "Processed sample loaded from file 01. N = " _N 
 
* Rebuild the missing-indicator names that file 01 generated (cheap -- 
* just reconstructs the list based on the naming pattern; the variables 
* themselves already exist in the processed dataset just loaded above, 
* so this is a plain local-macro loop, not a varlist check). 
local missnames 
local Xcont_orig $Xcont 
foreach var of local Xcont_orig { 
    local missname = substr("`var'", 1, 27) + "_miss" 
    local missnames `missnames' `missname' 
} 
 
global X     $Xcont i.randomization_strata `missnames' 
global Xcont $Xcont `missnames' 
 
di "X    : $X" 
di "Xcont: $Xcont" 

*------------------------------------------------------------------------- 
* Part 3: Generalized DML subgroup program 
*------------------------------------------------------------------------- 
* Runs the full ddml partial-model sequence (init -> E[Y|X] -> E[D|X] -> 
* crossfit -> estimate) on whatever subset of the loaded data satisfies 
* condition(), then stores/saves the estimates under outname(). Assumes 
* $Y_main, $D, $X, $Xcont, $out_dml, $pscore_lo, $pscore_hi are already 
* defined and missing-value handling (Part 2) has already run on the 
* full dataset -- preserve/restore means this only needs to happen once. 
* 
* D (treatment_assignment) may have more than two arms, so balance is 
* checked via a joint F-test (testparm) rather than a two-sample ttest. 
 
capture program drop run_dml_subgroup 
program define run_dml_subgroup 
    syntax, /// 
        condition(string)   /// Stata boolean expression, e.g. "competition_strata == 1" 
        label(string)       /// display label, e.g. "High competition subgroup" 
        outname(string)     /// estimates store/save name, e.g. "dml_partial_highcomp" 
        [kfolds(integer 4) reps(integer 5)] 
    preserve 
    keep if `condition' 
    di "--- DML: `label' ---" 
    di "N = " _N 
 
    * (a) Fold-size check relative to Lasso/Ridge interaction count 
    local n_xcont : word count $Xcont 
    local n_interact = `n_xcont' * (`n_xcont' + 1) / 2 
    qui count 
    local per_fold = floor(r(N) / `kfolds') 
 
    di "kfolds = `kfolds', ~N/fold = `per_fold', interaction terms = `n_interact'" 
    if `per_fold' < 10 * `n_interact' { 
        di as error "WARNING (`label'): per-fold N is small relative to the number of Lasso/Ridge interaction terms." 
    } 
 
    * (b) Covariate balance by $D (joint F-test, robust to multi-arm D) 
    di "--- Covariate balance: $Xcont by $D (`label') ---" 
    foreach var of varlist $Xcont { 
        qui regress `var' i.$D 
        qui testparm i.$D 
        di "`var': balance p-value = " %5.3f r(p) 
    } 
 
    * DML estimation 
    ddml init partial, kfolds(`kfolds') reps(`reps') 
 
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
 
    estimates store `outname' 
    estimates save "$out_dml/`outname'.ster", replace 
 
    * (c) Propensity-score diagnostics. Run `ddml describe` if the 
    * variable name below doesn't match your ddml/pystacked version. 
    cap confirm variable D_pystacked 
    if !_rc { 
        di "--- Propensity score (E[D|X]) diagnostics: `label' ---" 
        summarize D_pystacked, detail 
        count if D_pystacked < $pscore_lo | D_pystacked > $pscore_hi 
        di "Observations outside [$pscore_lo, $pscore_hi]: " r(N) 
 
        histogram D_pystacked, /// 
            title("Estimated propensity score: `label'") /// 
            xline($pscore_lo $pscore_hi, lcolor(red)) /// 
            name(pscore_`outname', replace) 
        graph export "$out_dml/`outname'_pscore_hist.png", replace width(1200) 
    } 
    else { 
        di as text "NOTE: D-hat variable not found under expected name for `label'; run 'ddml describe'." 
    } 
 
    restore 
end 
 
*------------------------------------------------------------------------- 
* Part 4: Run the three subgroups 
*------------------------------------------------------------------------- 
* (1) High competition environment (competition_strata convention from code_06) 
run_dml_subgroup, condition("competition_strata == 1") /// 
    label("High competition subgroup") /// 
    outname("dml_partial_highcomp") 
 
* (2) Low competition environment 
run_dml_subgroup, condition("competition_strata == 0") /// 
    label("Low competition subgroup") /// 
    outname("dml_partial_lowcomp") 
 
* (3) Matching subsample. Eligibility criteria copied from Part 2 of 
* Matching_code_01_adding_comparison_group.do (the experimental-sample 
* side of the matching design), so this subgroup and the matching 
* comparison-group estimate are evaluated on the same population. 
run_dml_subgroup, /// 
    condition("appears_in_RAIS_2016 == 1 & number_employees_RAIS_2016 > 0 & number_employees_RAIS_2016 <= 10 & business_practices_sum_2018 <= 22 & treated_impact_evaluation_2017 != 1") /// 
    label("Matching subsample") /// 
    outname("dml_partial_match") 
  
*------------------------------------------------------------------------- 
* Part 5: Summary table of subgroup results 
*------------------------------------------------------------------------- 
cap confirm file "$out_dml/dml_partial_full.ster" 
if !_rc { 
    estimates use "$out_dml/dml_partial_full.ster" 
    estimates store dml_partial_full 
    estimates table dml_partial_full dml_partial_highcomp dml_partial_lowcomp /// 
        dml_partial_match, b star stats(N) 
} 
else { 
    di as text "NOTE: dml_partial_full.ster not found; showing subgroup estimates only." 
    estimates table dml_partial_highcomp dml_partial_lowcomp dml_partial_match, /// 
        b star stats(N) 
} 
 
di "DML subgroup analysis complete. Estimates saved to $out_dml" 
di "  dml_partial_highcomp.ster -- High competition subsample" 
di "  dml_partial_lowcomp.ster  -- Low competition subsample" 
di "  dml_partial_match.ster  -- Matching subsample" 

 

 

 