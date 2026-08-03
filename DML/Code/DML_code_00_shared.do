*========================================================================= 
* DML_code_00_shared.do 
* Shared globals, prep, and estimation engine for both the partial (ATE) 
* and interactive (ATET) DML models, full-sample or subgroup. 
*========================================================================= 
clear all 
set more off 
set seed 123 
cd "/Users/aaronjoseph/Downloads/Capstone/Felipe" 
 
global out_dml "DML/Output" 
cap mkdir "DML" 
cap mkdir "$out_dml" 
 
global Y_main business_practices_sum_2019 
global D_raw treatment_assignment 
global Xcont0 business_practices_sum_2018 years_functioning_2018 /// 
    respondent_gender_2018 respondent_type_2018 /// 
    number_employees_RAIS_2016 competition_density_full_zipco /// 
    Q1_respondent_educ_level_2018 Q2_respondent_busin_experi_2018 /// 
    Q13_respondent_risk_averse_2018 
 
global pscore_lo 0.05 
global pscore_hi 0.95 
 
*------------------------------------------------------------------------- 
* prep_dml: load raw data once, optionally collapse treatment to binary, 
* and generate missing-indicators. Used by both model variants so this 
* logic exists in exactly one place. 
*------------------------------------------------------------------------- 
capture program drop prep_dml 
program define prep_dml 
    syntax, model(string)          // "partial" or "interactive" 
 
    use "Experiment/Output/output_code_05_sample.dta", clear 
    di "Sample loaded. N = " _N 
 
    if "`model'" == "interactive" { 
        * Collapse multi-arm treatment to binary any_treatment 
        capture confirm string variable $D_raw 
        if !_rc local traw $D_raw 
        else { 
            decode $D_raw, gen(_D_raw_str) 
            local traw _D_raw_str 
        } 
        gen byte any_treatment = . 
        replace any_treatment = 0 if strpos(lower(`traw'), "control") 
        replace any_treatment = 1 if strpos(lower(`traw'), "coaching") /// 
                                    | strpos(lower(`traw'), "benchmark") /// 
                                    | strpos(lower(`traw'), "competition") 
        cap drop _D_raw_str 
        label define any_treatment_lbl 0 "Control" /// 
            1 "Any treatment (Coaching, Benchmark, or Competition)" 
        label values any_treatment any_treatment_lbl 
 
        qui count if missing(any_treatment) 
        if r(N) > 0 di as error "WARNING: `r(N)' obs unmatched; dropping." 
        drop if missing(any_treatment) 
        global D any_treatment 
    } 
    else global D $D_raw 
 
    * Missing-indicator generation (identical logic, one copy) 
    local missnames 
    foreach var of varlist $Xcont0 { 
        capture confirm numeric variable `var' 
        if !_rc { 
            local missname = substr("`var'", 1, 27) + "_miss" 
            cap drop `missname' 
            gen `missname' = missing(`var') 
            replace `var' = 0 if missing(`var') 
            local missnames `missnames' `missname' 
        } 
    } 
    global Xcont $Xcont0 `missnames' 
    global X     $Xcont i.randomization_strata 
 
    save "$out_dml/dml_`model'_processed.dta", replace 
 
end 
 
*------------------------------------------------------------------------- 
* run_ddml: single engine for both partial (ATE) and interactive (ATET) 
* models, on the full sample or any subgroup. Replaces four duplicated 
* estimation blocks with one. 
*------------------------------------------------------------------------- 
capture program drop run_ddml 
program define run_ddml 
    syntax, model(string) outname(string) [condition(string) label(string) /// 
        kfolds(integer 4) reps(integer 5)] 
 
    if "`condition'" != "" { 
        preserve 
        keep if `condition' 
    } 
    if "`label'" == "" local label "`outname'" 
    di "--- DML (`model'): `label' ---" 
    di "N = " _N 
 
    * Fold-size diagnostic 
    local n_xcont : word count $Xcont 
    local n_interact = `n_xcont' * (`n_xcont' + 1) / 2 
    qui count 
    local per_fold = floor(r(N) / `kfolds') 
    di "kfolds=`kfolds' ~N/fold=`per_fold' interactions=`n_interact'" 
    if `per_fold' < 10 * `n_interact' { 
        di as error "WARNING (`label'): per-fold N small vs. interaction terms." 
    } 
 
    * Balance check (joint F-test works for both binary & multi-arm D) 
    foreach var of varlist $Xcont { 
        qui regress `var' i.$D 
        qui testparm i.$D 
        di "`var': balance p = " %5.3f r(p) 
    } 
 
    local pystacked_opts /// 
        || method(ols) /// 
        || m(lassocv) xvars($Xcont c.($Xcont)#c.($Xcont) i.randomization_strata) /// 
        || m(ridgecv) xvars($Xcont c.($Xcont)#c.($Xcont) i.randomization_strata) /// 
        || m(rf) pipe(sparse) opt(max_features(5)) /// 
        || m(gradboost) pipe(sparse) opt(n_estimators(250) learning_rate(0.01)), /// 
        njobs(5) 
 
    if "`model'" == "partial" { 
        ddml init partial, kfolds(`kfolds') reps(`reps') 
        ddml E[Y|X]: pystacked $Y_main $X `pystacked_opts' 
        ddml E[D|X]: pystacked $D $X `pystacked_opts' 
        ddml crossfit 
        ddml estimate, robust allcombos 
        cap pystacked, table 
    } 
    else { 
        ddml init interactive, kfolds(`kfolds') reps(`reps') 
        ddml E[Y|X,D]: pystacked $Y_main $X `pystacked_opts' 
        ddml E[D|X]: pystacked $D $X /// 
            || method(logit) /// 
            || m(lassocv) xvars($Xcont c.($Xcont)#c.($Xcont) i.randomization_strata) /// 
            || m(ridgecv) xvars($Xcont c.($Xcont)#c.($Xcont) i.randomization_strata) /// 
            || m(rf) pipe(sparse) opt(max_features(5)) /// 
            || m(gradboost) pipe(sparse) opt(n_estimators(250) learning_rate(0.01)), /// 
            type(class) njobs(5) 
        ddml crossfit 
        ddml estimate, robust atet allcombos 
        cap pystacked, table 
    } 
 
    *--------------------------------------------------------------------- 
    * Propensity-score diagnostics. 
    * ddml crossfit leaves the cross-fitted D-hat values as ordinary 
    * variables in the CURRENT dataset (one per resample), so there is 
    * no need to export to CSV / reimport into a linked frame. We just 
    * average the per-resample columns directly. Do this immediately 
    * after crossfit, before any preserve/restore or dataset change 
    * that could wipe these variables. 
    *--------------------------------------------------------------------- 
    cap ds D1_pystacked_* 
    local dresamples "`r(varlist)'" 
 
    local phat "" 
    if "`dresamples'" != "" { 
        cap drop _phat_exported 
        egen _phat_exported = rowmean(`dresamples') 
        local phat _phat_exported 
    } 
    else { 
        di as error "NOTE (`label'): no D1_pystacked_<r> variables found in memory after crossfit; inspect dataset with 'ds *pystacked*' to find correct names." 
    } 
 
    if "`phat'" != "" { 
        summarize `phat', detail 
        count if `phat' < $pscore_lo | `phat' > $pscore_hi 
        di "Outside [$pscore_lo, $pscore_hi]: " r(N) 
        histogram `phat', title("Estimated propensity score: `label'") /// 
            xline($pscore_lo $pscore_hi, lcolor(red)) name(pscore_`outname', replace) 
        graph export "$out_dml/`outname'_pscore_hist.png", replace width(1200) 
    } 
 
    estimates store `outname' 
    estimates save "$out_dml/`outname'.ster", replace 
 
    if "`condition'" != "" restore 
end 
*------------------------------------------------------------------------- 
* write_results_csv: emits the SAME schema as Matching_output_effect_ 
* comparison.csv (Model, Beta, SE, N) so both pipelines share one plot 
* routine. Pulls the treatment coefficient automatically regardless of 
* whether D is treatment_assignment or any_treatment. 
*------------------------------------------------------------------------- 
global KNOWN_TREATVARS "treatment_assignment any_treatment treatment_y itt treatment treatment_assignment_binary" 
 
capture program drop write_results_csv 
program define write_results_csv 
    syntax, models(string) csvfile(string) [estimand(string)] 
 
    file open fh using "`csvfile'", write replace 
    file write fh "Model,Beta,SE,N,Estimand" _n 
    foreach m of local models { 
        quietly estimates restore `m' 
        local colnames : colnames e(b) 
        local tcoef "" 
        local tcoef_full "" 
        foreach cand of global KNOWN_TREATVARS { 
            * Exact match first (single-equation models) 
            local pos : list posof "`cand'" in colnames 
            if `pos' > 0 { 
                local tcoef "`cand'" 
                local tcoef_full "`cand'" 
                continue, break 
            } 
            * Multi-equation models prefix columns as "eqname:varname" 
            * (e.g. "y1:treatment_y") -- match on the suffix after ":". 
            foreach cn of local colnames { 
                local base = "`cn'" 
                local colonpos = strpos("`cn'", ":") 
                if `colonpos' > 0 local base = substr("`cn'", `colonpos'+1, .) 
                if "`base'" == "`cand'" { 
                    local tcoef "`cand'" 
                    local tcoef_full "`cn'" 
                    continue, break 
                } 
            } 
            if "`tcoef'" != "" continue, break 
        } 
        if "`tcoef'" == "" { 
            di as error "NOTE: no treatment coef for `m' -- skipped." 
            continue 
        } 
        local pos : list posof "`tcoef_full'" in colnames 
        matrix b = e(b) 
        matrix V = e(V) 
        local beta = b[1,`pos'] 
        local se   = sqrt(V[`pos',`pos']) 
        local n    = e(N) 
        file write fh "`m'," %9.4f (`beta') "," %9.4f (`se') "," %9.0f (`n') ",`estimand'" _n 
    } 
    file close fh 
 
end 
