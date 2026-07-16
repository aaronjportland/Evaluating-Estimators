 
*========================================================================= 
* DML_code_02b_interactive_subgroup_analysis.do 
* 
* Double/Debiased Machine Learning -- Interactive (AIPW) Model 
* Subgroup Analysis, Binary Treatment 
* 
* REQUIRES: DML_code_01b_interactive_full_analysis.do must be run first 
* -- this file loads its processed dataset (already collapsed to binary 
* any_treatment, with missing-indicators generated) rather than 
* re-deriving them, and its Part 5 comparison table depends on 
* dml_int_full.ster already existing. 
* 
* Three subgroups are estimated via a single generalized program: 
*   (1) High competition environment (competition_strata == 1) 
*   (2) Low competition environment  (competition_strata == 0) 
*   (3) Matching subsample -- same eligibility population used in 
*       Matching_code_01_adding_comparison_group.do 
* 
* Input:  DML/Output/dml_int_processed.dta (from file 01b) 
* Output: DML/Output/dml_int_highcomp.ster 
*         DML/Output/dml_int_lowcomp.ster 
*         DML/Output/dml_int_match.ster 
*         DML/Output/<outname>_pscore_hist.png (per subgroup) 
* 
* Author: Aaron Joseph 
* Date:   (interactive-model variation) 
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
* Part 1: Globals (must match DML_code_01b_interactive_full_analysis.do) 
*------------------------------------------------------------------------- 
global Y_main business_practices_sum_2019 
global D_raw   treatment_assignment 
global D       any_treatment 
 
global Xcont business_practices_sum_2018 years_functioning_2018 /// 
    respondent_gender_2018 respondent_type_2018 /// 
    number_employees_RAIS_2016 competition_density_full_zipco /// 
    Q1_respondent_educ_level_2018 Q2_respondent_busin_experi_2018 /// 
    Q13_respondent_risk_averse_2018 
 
* Rebuild the missing-indicator names that file 01b generated (cheap -- 
* just reconstructs the list; the variables and any_treatment already 
* exist in the processed dataset loaded below). 
local missnames 
foreach var of local Xcont { 
    local missname = substr("`var'", 1, 27) + "_miss" 
    local missnames `missnames' `missname' 
} 
global X $Xcont i.randomization_strata `missnames' 
global Xcont $Xcont `missnames' 
 
global pscore_lo 0.05 
global pscore_hi 0.95 
 
*------------------------------------------------------------------------- 
* Part 2: Load processed data from DML_code_01b_interactive_full_analysis.do 
*------------------------------------------------------------------------- 
cap confirm file "$out_dml/dml_int_processed.dta" 
if _rc { 
    di as error "ERROR: $out_dml/dml_int_processed.dta not found." 
    di as error "Run DML_code_01b_interactive_full_analysis.do first -- this file depends on its processed output (including the any_treatment collapse)." 
    exit 601 
} 
use "$out_dml/dml_int_processed.dta", clear 
di "Processed sample loaded from file 01b. N = " _N 
 
di "X    : $X" 
di "Xcont: $Xcont" 


*------------------------------------------------------------------------- 
* Part 3: Generalized interactive-model DML subgroup program 
*------------------------------------------------------------------------- 
* Runs the full ddml interactive-model sequence (init -> E[Y|X,D] -> 
* E[D|X] -> crossfit -> estimate) on whatever subset of the loaded data 
* satisfies condition(), then stores/saves the estimates under 
* outname(). Assumes $Y_main, $D, $X, $Xcont, $out_dml, $pscore_lo, 
* $pscore_hi are already defined and treatment already collapsed to 
* binary any_treatment (Part 2) -- preserve/restore means this only 
* needs to happen once, upfront. 
* 
* D (any_treatment) is binary, so ddml init interactive (AIPW, 
* doubly-robust) is used, permitting effect heterogeneity across X. 
 
capture program drop run_dml_int_subgroup 
program define run_dml_int_subgroup 
    syntax, /// 
        condition(string)   /// Stata boolean expression, e.g. "competition_strata == 1" 
        label(string)       /// display label, e.g. "High competition subgroup" 
        outname(string)     /// estimates store/save name, e.g. "dml_int_highcomp" 
        [kfolds(integer 4) reps(integer 5)] 
 
    preserve 
    keep if `condition' 
    di "--- DML (interactive/AIPW): `label' ---" 
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
 
    * (b) Covariate balance by $D (binary ttest) 
    qui count if $D == 1 
    local n_treated = r(N) 
    qui count if $D == 0 
    local n_control = r(N) 
    di "`label': N control = `n_control', N any_treatment = `n_treated'" 
    if `n_treated' < 10 | `n_control' < 10 { 
        di as error "WARNING (`label'): fewer than 10 obs in a treatment arm. AIPW estimates and propensity overlap will be unreliable." 
    } 
 
    di "--- Covariate balance: $Xcont by $D (`label') ---" 
    foreach var of varlist $Xcont { 
        qui ttest `var', by($D) 
        di "`var': ttest p-value (Control vs. Any Treatment) = " %5.3f r(p) 
    } 
 
    * (c) Composition of any_treatment==1 by original arm (context only) 
    di "--- Composition of any_treatment == 1 by original arm (`label') ---" 
    tab $D_raw if $D == 1 
 
    * DML estimation (interactive/AIPW) 
    ddml init interactive, kfolds(`kfolds') reps(`reps') 
 
    ddml E[Y|X,D]: pystacked $Y_main $X /// 
        || method(ols) /// 
        || m(lassocv) xvars(c.($Xcont)##c.($Xcont) i.randomization_strata) /// 
        || m(ridgecv) xvars(c.($Xcont)##c.($Xcont) i.randomization_strata) /// 
        || m(rf) pipe(sparse) opt(max_features(5)) /// 
        || m(gradboost) pipe(sparse) opt(n_estimators(250) learning_rate(0.01)), /// 
        njobs(5) 
 
    ddml E[D|X]: pystacked $D $X /// 
        || method(logit) /// 
        || m(lassocv) xvars(c.($Xcont)##c.($Xcont) i.randomization_strata) /// 
        || m(ridgecv) xvars(c.($Xcont)##c.($Xcont) i.randomization_strata) /// 
        || m(rf) pipe(sparse) opt(max_features(5)) /// 
        || m(gradboost) pipe(sparse) opt(n_estimators(250) learning_rate(0.01)), /// 
        type(class) njobs(5) 
 
    qui ddml crossfit 
    ddml estimate, robust atet 
 
    estimates store `outname' 
    estimates save "$out_dml/`outname'.ster", replace 
 
    * (d) Propensity-score diagnostics. D-hat is named D1_pystacked for 
    * the interactive model (not D_pystacked) -- confirm via 
    * `ddml describe` if this doesn't match your version. 
    cap confirm variable D1_pystacked 
    if !_rc { 
        di "--- Propensity score (E[D|X]) diagnostics: `label' ---" 
        summarize D1_pystacked, detail 
        count if D1_pystacked < $pscore_lo | D1_pystacked > $pscore_hi 
        di "Observations outside [$pscore_lo, $pscore_hi]: " r(N) 
 
        histogram D1_pystacked, /// 
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
run_dml_int_subgroup, condition("competition_strata == 1") /// 
    label("High competition subgroup") /// 
    outname("dml_int_highcomp") 
 
run_dml_int_subgroup, condition("competition_strata == 0") /// 
    label("Low competition subgroup") /// 
    outname("dml_int_lowcomp") 
 
* Matching subsample. Eligibility criteria copied from Part 2 of 
* Matching_code_01_adding_comparison_group.do, so this subgroup and the 
* matching comparison-group estimate are evaluated on the same population. 
run_dml_int_subgroup, /// 
    condition("appears_in_RAIS_2016 == 1 & number_employees_RAIS_2016 > 0 & number_employees_RAIS_2016 <= 10 & business_practices_sum_2018 <= 22 & treated_impact_evaluation_2017 != 1") /// 
    label("Matching subsample") /// 
    outname("dml_int_match") 
 
*------------------------------------------------------------------------- 
* Part 5: Summary table of subgroup results 
*------------------------------------------------------------------------- 
cap confirm file "$out_dml/dml_int_full.ster" 
if !_rc { 
    estimates use "$out_dml/dml_int_full.ster" 
    estimates store dml_int_full 
    estimates table dml_int_full dml_int_highcomp dml_int_lowcomp /// 
        dml_int_match, b star stats(N) 
} 
else { 
    di as text "NOTE: dml_int_full.ster not found; showing subgroup estimates only." 
    estimates table dml_int_highcomp dml_int_lowcomp dml_int_match, /// 
        b star stats(N) 
} 
 
di "Interactive (AIPW) DML subgroup analysis complete. Estimates saved to $out_dml" 
di "  dml_int_highcomp.ster        -- High competition subsample" 
di "  dml_int_lowcomp.ster         -- Low competition subsample" 
di "  dml_int_match.ster -- Matching subsample" 
