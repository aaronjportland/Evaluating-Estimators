*========================================================================= 
* DML_code_01b_interactive_full_analysis.do 
* 
* Double/Debiased Machine Learning -- Primary (Full-Sample) Analysis 
* 
* Purpose: Estimate the effect of treatment on business_practices_sum_2019 
*          using the DML interactive (AIPW/doubly-robust) model on the 
*          full analysis sample, with treatment collapsed to binary. 
* 
* Input:   Experiment/Output/output_code_05_sample.dta 
* Output:  DML/Output/dml_int_full.ster 
*          DML/Output/dml_int_full_pscore_hist.png 
* 
* Author:  Aaron Joseph 
* Date:    (interactive-model variation) 
*========================================================================= 
 
*------------------------------------------------------------------------- 
* Part 0: Settings 
*------------------------------------------------------------------------- 
clear all 
set more off 
set seed 123 
cd "/Users/aaronjoseph/Downloads/Capstone/Felipe" 
 
*------------------------------------------------------------------------- 
* Part 1: Globals 
*------------------------------------------------------------------------- 
global Y_main business_practices_sum_2019 
global D_raw   treatment_assignment 
global D       any_treatment   // binary collapse of treatment_assignment, see Part 2b 
 
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
 
* Propensity-score trimming band -- directly load-bearing here, since 
* extreme scores destabilize AIPW weights 1/pscore and 1/(1-pscore) 
global pscore_lo 0.05 
global pscore_hi 0.95 
 
*------------------------------------------------------------------------- 
* Part 2: Load data, collapse treatment, handle missing values 
*------------------------------------------------------------------------- 
use "Experiment/Output/output_code_05_sample.dta", clear 
di "Full analysis sample loaded. N = " _N 
 
* 2a. Inspect original treatment_assignment levels before collapsing 
di "--- Levels of $D_raw found in data ---" 
levelsof $D_raw, local(traw_levels) 
di "Levels: `traw_levels'" 
 
* 2b. Collapse to binary: any_treatment = 0 for Control, 1 for any 
* Coaching/Benchmark/Competition arm (pooled across ranking systems). 
* ddml's interactive model requires binary D. Adjust string matching 
* below if category labels differ, using the levels listed above. 
capture confirm string variable $D_raw 
if !_rc { 
    gen byte any_treatment = . 
    replace any_treatment = 0 if strpos(lower($D_raw), "control") 
    replace any_treatment = 1 if strpos(lower($D_raw), "coaching") | /// 
        strpos(lower($D_raw), "benchmark") | /// 
        strpos(lower($D_raw), "competition") 
} 
else { 
    * Numeric with value labels -- decode first 
    decode $D_raw, gen(_D_raw_str) 
    gen byte any_treatment = . 
    replace any_treatment = 0 if strpos(lower(_D_raw_str), "control") 
    replace any_treatment = 1 if strpos(lower(_D_raw_str), "coaching") | /// 
        strpos(lower(_D_raw_str), "benchmark") | /// 
        strpos(lower(_D_raw_str), "competition") 
    drop _D_raw_str 
} 
 
label define any_treatment_lbl 0 "Control" 1 "Any treatment (Coaching, Benchmark, or Competition)" 
label values any_treatment any_treatment_lbl 
 
qui count if missing(any_treatment) 
if r(N) > 0 { 
    di as error "WARNING: `r(N)' observations did not match Control/Coaching/" /// 
        "Benchmark/Competition patterns and will be dropped." 
} 
 
di "--- Collapsed treatment: $D (any_treatment) ---" 
tab $D_raw any_treatment, missing 
drop if missing(any_treatment) 
 
* Generate a missing-indicator and zero-fill each covariate 
local missnames 
foreach var of varlist $Xcont { 
    capture confirm numeric variable `var' 
    if !_rc { 
        local missname = substr("`var'", 1, 27) + "_miss" 
        gen `missname' = missing(`var') 
        replace `var' = 0 if missing(`var') 
        local missnames `missnames' `missname' 
    } 
} 
 
* Add missing-indicators (themselves continuous 0/1) to both globals 
global X     $X `missnames' 
global Xcont $Xcont `missnames' 
 
di "X    : $X" 
di "Xcont: $Xcont" 
 
*------------------------------------------------------------------------- 
* Part 3: Pre-estimation diagnostics 
*------------------------------------------------------------------------- 
* 3a. Fold-size check relative to Lasso/Ridge interaction count 
local kfolds  = 4 
local n_xcont : word count $Xcont 
local n_interact = `n_xcont' * (`n_xcont' + 1) / 2 
qui count 
local per_fold = floor(r(N) / `kfolds') 
 
di "N = " r(N) ", kfolds = `kfolds', ~N/fold = `per_fold', interaction terms = `n_interact'" 
if `per_fold' < 10 * `n_interact' { 
    di as error "WARNING: per-fold N is small relative to the number of Lasso/Ridge interaction terms." 
} 
 
* 3b. Covariate balance by any_treatment. D is binary here, so a 
* standard two-sample ttest applies (unlike the multi-arm partial-model file). 
di "--- Covariate balance: $Xcont by $D ---" 
foreach var of varlist $Xcont { 
    qui ttest `var', by($D) 
    di "`var': ttest p-value (Control vs. Any Treatment) = " %5.3f r(p) 
} 
 
* 3c. Composition of any_treatment==1 by original arm (context only) 
di "--- Composition of any_treatment == 1 by original arm ---" 
tab $D_raw if any_treatment == 1 
 
*------------------------------------------------------------------------- 
* Part 4: DML interactive (AIPW) estimation, full sample 
*------------------------------------------------------------------------- 
* D is strictly binary, so ddml's interactive model estimates 
* E[Y|X,D=0], E[Y|X,D=1], and E[D|X] (propensity score), combined via 
* the AIPW score -- allowing effect heterogeneity across X. 
di "--- DML (interactive/AIPW): Full sample, binary treatment ---" 
 
ddml init interactive, kfolds(4) reps(5) 
 
ddml E[Y|X,D]: pystacked $Y_main $X /// 
    || method(ols) /// 
    || m(lassocv) xvars(c.($Xcont)##c.($Xcont) i.randomization_strata) /// 
    || m(ridgecv) xvars(c.($Xcont)##c.($Xcont) i.randomization_strata) /// 
    || m(rf) pipe(sparse) opt(max_features(5)) /// 
    || m(gradboost) pipe(sparse) opt(n_estimators(250) learning_rate(0.01)), /// 
    njobs(5) 
 
* Propensity-score model; confirm via pystacked output that D is 
* treated as binary/classification, not regression. 
ddml E[D|X]: pystacked $D $X /// 
    || method(logit) /// 
    || m(lassocv) xvars(c.($Xcont)##c.($Xcont) i.randomization_strata) /// 
    || m(ridgecv) xvars(c.($Xcont)##c.($Xcont) i.randomization_strata) /// 
    || m(rf) pipe(sparse) opt(max_features(5)) /// 
    || m(gradboost) pipe(sparse) opt(n_estimators(250) learning_rate(0.01)), /// 
    type(class) njobs(5) 
 
qui ddml crossfit 
ddml estimate, robust atet   // atet optional: drop if ATE (not ATET) is the target 
 
estimates store dml_int_full 
estimates save "$out_dml/dml_int_full.ster", replace 
 
*------------------------------------------------------------------------- 
* Part 5: Propensity-score (E[D|X]) diagnostics 
*------------------------------------------------------------------------- 
* Run `ddml describe` if the variable name below doesn't match your 
* ddml/pystacked version's naming convention. 
cap confirm variable D1_pystacked 
if !_rc { 
    summarize D1_pystacked, detail 
    count if D1_pystacked < $pscore_lo | D1_pystacked > $pscore_hi 
    di "Observations outside [$pscore_lo, $pscore_hi]: " r(N) 
 
    histogram D1_pystacked, /// 
        title("Estimated propensity score, full sample (interactive model)") /// 
        xline($pscore_lo $pscore_hi, lcolor(red)) /// 
        name(pscore_int_full, replace) 
    graph export "$out_dml/dml_int_full_pscore_hist.png", replace width(1200) 
} 
else { 
    di as text "NOTE: D-hat variable not found under expected name; run 'ddml describe'." 
} 
 
*------------------------------------------------------------------------- 
* Part 6: Summary 
*------------------------------------------------------------------------- 
di "Interactive (AIPW) DML analysis complete. Treatment collapsed to binary:" 
di "any_treatment (0=Control, 1=Coaching/Benchmark/Competition, pooled across ranking systems)." 
di "Estimates saved to $out_dml/dml_int_full.ster" 
di "" 
di "Compare against:" 
di "  - Partial-model baseline (DML_code_01_partial_full_analysis.do), which" 
di "    used the full multi-arm treatment_assignment under a constant-effect assumption." 



* Save processed sample (post treatment-collapse and missing-indicator 
* generation) for downstream files (subgroup analysis depends on this 
* exact processed dataset + covariate list). 
save "$out_dml/dml_int_processed.dta", replace
