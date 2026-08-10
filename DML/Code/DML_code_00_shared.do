*========================================================================= 
* DML_code_00_shared.do 
* Date: 08/07/2026 
* Author: Aaron Joseph 
* 
* Shared globals, prep, and estimation engine for both the partial (ATE) 
* and interactive (ATET) DML models, full-sample or subgroup. 
* 
* Main steps: 
* 1. Set session-level globals (paths, outcome/treatment/covariate lists). 
* 2. Define rank_vars_by_importance: ranks covariates by |standardised 
*    beta| on the outcome -- identical to the matching helper so both 
*    pipelines produce comparable Variables_Used columns. 
* 3. Define prep_dml: loads the sample, builds the treatment variable, and 
*    generates missing-indicators. 
* 4. Define run_ddml: runs the DML estimation engine (partial or 
*    interactive) on the full sample or any subgroup, with propensity-score 
*    diagnostics. 
* 5. Define write_results_csv: extracts the treatment coefficient from any 
*    stored model and writes it into a shared comparison CSV. Supports an 
*    append option so code_01 and code_02 can extend the same file. 
* 
* CHANGES FROM PRIOR VERSION: 
* - Step 6 of run_ddml: n_treated now counts $D != 0 for partial models 
*   (multi-arm D) instead of $D == 1, fixing the silent undercount. 
* - estimates save removed from Step 7: ddml Mata objects cannot be 
*   serialised. write_results_csv must be called while estimates are 
*   still in memory (see code_01 and code_02). 
* - write_results_csv gains an append option so subgroup rows can be 
*   added to CSVs whose headers were already written in code_01. 
*========================================================================= 
 
// Step 1: Set session-level globals. 
clear all 
set more off 
set seed 123 
cd "/Users/aaronjoseph/Downloads/Capstone/Felipe" 
 
global out_dml "DML/Output" 
cap mkdir "DML" 
cap mkdir "$out_dml" 
 
global Y_main business_practices_sum_2019 
global D_raw  treatment_assignment 
global Xcont0 business_practices_sum_2018 years_functioning_2018         /// 
              respondent_gender_2018 respondent_type_2018                 /// 
              number_employees_RAIS_2016 competition_density_full_zipco   /// 
              Q1_respondent_educ_level_2018 Q2_respondent_busin_experi_2018 /// 
              Q13_respondent_risk_averse_2018 
 
global pscore_lo 0.05 
global pscore_hi 0.95 
 
*------------------------------------------------------------------------- 
* rank_vars_by_importance 
* 
* Ranks a varlist by |standardised coefficient| on the outcome, within the 
* sample defined by `touse'. Unweighted by design -- this is a ranking 
* heuristic for reporting only, separate from the headline weighted 
* treatment-effect estimate. 
* 
* Identical in logic to the matching helper so both pipelines produce 
* comparable Variables_Used columns. 
* 
* Returns: r(ordered_vars) -- semicolon-separated, most to least important. 
*------------------------------------------------------------------------- 
capture program drop rank_vars_by_importance 
program define rank_vars_by_importance, rclass 
    args yvar varlist touse 
 
    tempname rk 
    tempfile rank_raw 
 
    quietly postfile `rk' str32 varname double abscoef /// 
        using "`rank_raw'", replace 
 
    // Step 1: Standardised-beta regression. Variables with zero variance 
    // in this sample (e.g. constant _miss indicators in a subgroup) are 
    // silently dropped by regress. 
    quietly regress `yvar' `varlist' if `touse', beta 
    matrix b    = e(b) 
    local  names : colnames b 
    local  j = 0 
 
    // Step 2: Post each covariate's absolute standardised coefficient. 
    foreach v of local names { 
        local j = `j' + 1 
        if "`v'" == "_cons" continue 
        local c = b[1, `j'] 
        post `rk' ("`v'") (abs(`c')) 
    } 
 
    postclose `rk' 
 
    // Step 3: Sort covariates by importance and return the ordered list. 
    preserve 
        use "`rank_raw'", clear 
 
        if _N == 0 { 
            restore 
            di as error "rank_vars_by_importance: no non-constant " /// 
                "coefficients to rank." 
            error 2001 
        } 
 
        gsort -abscoef 
        local n = _N 
        local ordered "" 
        forvalues i = 1/`n' { 
            local vname = varname[`i'] 
            if `i' == 1 local ordered "`vname'" 
            else         local ordered "`ordered'; `vname'" 
        } 
    restore 
 
    return local ordered_vars "`ordered'" 
end 
 
*------------------------------------------------------------------------- 
* prep_dml 
* 
* Loads the raw data once, builds the treatment variable, generates 
* missing-indicators, and saves the processed dataset for reuse. 
* Used by both model variants so this logic exists in exactly one place. 
*------------------------------------------------------------------------- 
capture program drop prep_dml 
program define prep_dml 
    syntax, model(string)   // "partial" or "interactive" 
 
    // Step 1: Load the RCT sample. 
    use "Experiment/Output/output_code_05_sample.dta", clear 
    di "Sample loaded. N = " _N 
 
    // Step 2: Build the treatment variable. 
    if "`model'" == "interactive" { 
        // Collapse multi-arm treatment to binary any_treatment. 
        capture confirm string variable $D_raw 
        if !_rc local traw $D_raw 
        else { 
            decode $D_raw, gen(_D_raw_str) 
            local traw _D_raw_str 
        } 
 
        gen byte any_treatment = . 
        replace any_treatment = 0 if strpos(lower(`traw'), "control") 
        replace any_treatment = 1 if strpos(lower(`traw'), "coaching")    /// 
                                   | strpos(lower(`traw'), "benchmark")   /// 
                                   | strpos(lower(`traw'), "competition") 
        cap drop _D_raw_str 
 
        label define any_treatment_lbl 0 "Control"                           /// 
            1 "Any treatment (Coaching, Benchmark, or Competition)" 
        label values any_treatment any_treatment_lbl 
 
        qui count if missing(any_treatment) 
        if r(N) > 0 di as error "WARNING: `r(N)' obs unmatched; dropping." 
        drop if missing(any_treatment) 
        global D any_treatment 
    } 
    else global D $D_raw 
 
    // Step 3: Generate missing-indicators for continuous covariates. 
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
 
    // Step 4: Save the processed dataset for reuse. 
    save "$out_dml/dml_`model'_processed.dta", replace 
end 
 
*------------------------------------------------------------------------- 
* run_ddml 
* 
* Single engine for both partial (ATE) and interactive (ATET) models, 
* on the full sample or any subgroup. 
* 
* NOTE: estimates save is intentionally omitted -- ddml stores Mata 
* objects in e() that cannot be serialised by estimates save/use. 
* write_results_csv must be called while models are still in memory. 
*------------------------------------------------------------------------- 
capture program drop run_ddml, eclass 
program define run_ddml, eclass 
    syntax, model(string) outname(string) [condition(string) label(string) /// 
            kfolds(integer 4) reps(integer 5)] 
 
    // Step 1: Restrict to subgroup if a condition is given. 
    if "`condition'" != "" { 
        preserve 
        keep if `condition' 
    } 
    if "`label'" == "" local label "`outname'" 
    di "--- DML (`model'): `label' ---" 
    di "N = " _N 
 
    // Step 2: Fold-size and balance diagnostics (display only). 
    // NOTE: the per-fold N warning is calibrated for OLS. With regularised 
    // learners (lasso, ridge, RF, gradboost) the threshold is conservative 
    // and the warning is informational only. 
    local n_xcont : word count $Xcont 
    local n_interact = `n_xcont' * (`n_xcont' + 1) / 2 
    qui count 
    local per_fold = floor(r(N) / `kfolds') 
    di "kfolds=`kfolds' ~N/fold=`per_fold' interactions=`n_interact'" 
    if `per_fold' < 10 * `n_interact' { 
        di as error "WARNING (`label'): per-fold N small vs. interaction terms." 
    } 
    foreach var of varlist $Xcont { 
        qui regress `var' i.$D 
        cap qui testparm i.$D 
        if _rc | missing(r(p)) di "`var': balance p = (omitted -- constant in subgroup)" 
        else                   di "`var': balance p = " %5.3f r(p) 
    } 
 
    // Step 3: Rank covariates by |standardised beta| on the outcome. 
    // Must run before ddml estimate to avoid clobbering e(). 
    tempvar touse 
    gen byte `touse' = 1 
 
    cap rank_vars_by_importance $Y_main "$Xcont" `touse' 
    if !_rc { 
        local ordered_vars = r(ordered_vars) 
        // Append any covariates dropped (e.g. constant _miss in subgroup). 
        foreach v of varlist $Xcont { 
            if !strpos("`ordered_vars'", "`v'") { 
                if "`ordered_vars'" == "" local ordered_vars "`v'" 
                else                      local ordered_vars "`ordered_vars'; `v'" 
            } 
        } 
    } 
    else { 
        di as error "NOTE (`label'): rank_vars_by_importance failed; " /// 
            "falling back to original covariate order." 
        local ordered_vars : subinstr local Xcont " " "; ", all 
    } 
 
    // Step 4: Estimate the DML model (partial or interactive) via ddml/pystacked. 
    local pystacked_opts                                                             /// 
        || method(ols)                                                               /// 
        || m(lassocv) xvars($Xcont c.($Xcont)#c.($Xcont) i.randomization_strata)    /// 
        || m(ridgecv) xvars($Xcont c.($Xcont)#c.($Xcont) i.randomization_strata)    /// 
        || m(rf)        pipe(sparse) opt(max_features(5))                            /// 
        || m(gradboost) pipe(sparse) opt(n_estimators(250) learning_rate(0.01)),     /// 
        njobs(5) 
 
    if "`model'" == "partial" { 
        ddml init partial, kfolds(`kfolds') reps(`reps') 
        ddml E[Y|X]:  pystacked $Y_main $X `pystacked_opts' 
        ddml E[D|X]:  pystacked $D      $X `pystacked_opts' 
        ddml crossfit 
        ddml estimate, robust allcombos 
        cap pystacked, table 
    } 
    else { 
        ddml init interactive, kfolds(`kfolds') reps(`reps') 
        ddml E[Y|X,D]: pystacked $Y_main $X `pystacked_opts' 
        ddml E[D|X]:   pystacked $D      $X                                          /// 
            || method(logit)                                                           /// 
            || m(lassocv) xvars($Xcont c.($Xcont)#c.($Xcont) i.randomization_strata)  /// 
            || m(ridgecv) xvars($Xcont c.($Xcont)#c.($Xcont) i.randomization_strata)  /// 
            || m(rf)        pipe(sparse) opt(max_features(5))                          /// 
            || m(gradboost) pipe(sparse) opt(n_estimators(250) learning_rate(0.01)),   /// 
            type(class) njobs(5) 
        ddml crossfit 
        ddml estimate, robust atet allcombos 
        cap pystacked, table 
    } 
 
    // Step 5: Propensity-score diagnostics (interactive model only). 
    if "`model'" == "interactive" { 
        cap ds D1_pystacked_* 
        local dresamples "`r(varlist)'" 
 
        local phat "" 
        if "`dresamples'" != "" { 
            cap drop _phat_exported 
            egen _phat_exported = rowmean(`dresamples') 
            local phat _phat_exported 
        } 
        else { 
            di as error "NOTE (`label'): no D1_pystacked_<r> variables found; " /// 
                "inspect with 'ds pystacked' to find correct names." 
        } 
 
        if "`phat'" != "" { 
            summarize `phat', detail 
            count if `phat' < $pscore_lo | `phat' > $pscore_hi 
            di "Outside [$pscore_lo, $pscore_hi]: " r(N) 
            histogram `phat', title("Estimated propensity score: `label'") /// 
                xline($pscore_lo $pscore_hi, lcolor(red))                   /// 
                name(pscore_`outname', replace) 
            graph export "$out_dml/`outname'_pscore_hist.png", replace width(1200) 
        } 
    } 
    else { 
        di "NOTE (`label'): partial model -- D-hat values are not a binary " /// 
            "propensity score; pscore diagnostic skipped." 
    } 
 
    // Step 6: Attach metadata to the estimation object before saving. 
    // FIX: For partial models, $D is multi-arm (0/1/2/3...). Count all 
    // non-zero values as treated; == 1 would silently undercount. 
    // For interactive models, $D is binary 0/1, so == 1 / == 0 is exact. 
    if "`model'" == "partial" { 
        quietly count if $D != 0 
        local n_treated = r(N) 
        quietly count if $D == 0 
        local n_control = r(N) 
    } 
    else { 
        quietly count if $D == 1 
        local n_treated = r(N) 
        quietly count if $D == 0 
        local n_control = r(N) 
    } 
 
    // Store ddml results temporarily so the F-test regress doesn't clobber e(). 
    estimates store _ddt 
 
    // Joint F-test of covariates on treatment. 
    quietly regress $D $Xcont 
    quietly testparm $Xcont 
    local joint_f_p = r(p) 
 
    // Restore ddml results and attach metadata. 
    quietly estimates restore _ddt 
 
    ereturn scalar n_treated = `n_treated' 
    ereturn scalar n_control = `n_control' 
    ereturn scalar joint_f_p = `joint_f_p' 
    ereturn local  vars_used  "`ordered_vars'" 
    ereturn local  method     "ddml" 
 
    // Step 7: Store in memory only. 
    // FIX: estimates save omitted -- ddml Mata objects cannot be serialised. 
    // write_results_csv must be called while estimates are still in memory. 
    estimates store `outname' 
 
    // Clean up. 
    cap estimates drop _ddt 
    if "`condition'" != "" restore 
end 
 
*------------------------------------------------------------------------- 
* write_results_csv 
* 
* Emits the same schema as Matching_output_effect_comparison.csv. 
* The append option lets code_01 write headers and code_02 add subgroup 
* rows to the same file without re-opening in replace mode. 
* 
* Steps: 
* 1. Open CSV in replace mode (writes header) or append mode (skips header). 
* 2. For each model, locate the treatment coefficient generically. 
* 3. Determine the estimand label. 
* 4. Pull metadata from e() and write the full row. 
*------------------------------------------------------------------------- 
global KNOWN_TREATVARS "treatment_assignment any_treatment treatment_y itt treatment treatment_assignment_binary" 
 
capture program drop write_results_csv 
program define write_results_csv 
    syntax, models(string) csvfile(string) [estimand(string) APPend] 
 
    // Step 1: Open CSV -- replace writes header; append skips it. 
    if "`append'" != "" { 
        file open fh using "`csvfile'", write append 
    } 
    else { 
        file open fh using "`csvfile'", write replace 
        file write fh "Model,Method,Beta,SE,PValue,N_Treated_or_Matched," /// 
            "N_Control_or_Dropped,N_Total,Variables_Used,Joint_F_Pvalue,Estimand" _n 
    } 
 
    foreach m of local models { 
        quietly estimates restore `m' 
 
        // Step 2: Locate the treatment coefficient generically. 
        local colnames : colnames e(b) 
        local tcoef      "" 
        local tcoef_full "" 
        foreach cand of global KNOWN_TREATVARS { 
            local pos : list posof "`cand'" in colnames 
            if `pos' > 0 { 
                local tcoef      "`cand'" 
                local tcoef_full "`cand'" 
                continue, break 
            } 
            foreach cn of local colnames { 
                local base     = "`cn'" 
                local colonpos = strpos("`cn'", ":") 
                if `colonpos' > 0 local base = substr("`cn'", `colonpos'+1, .) 
                if "`base'" == "`cand'" { 
                    local tcoef      "`cand'" 
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
 
        // Step 3: Determine the estimand label. 
        local row_estimand "`estimand'" 
        if "`row_estimand'" == "" { 
            if      strpos("`m'", "partial") > 0 local row_estimand "ATE" 
            else if strpos("`m'", "int")     > 0 local row_estimand "ATET" 
            else if "`m'" == "rct_itt"           local row_estimand "ITT" 
        } 
 
        // Step 4: Pull metadata from e() and write the full row. 
        local pos : list posof "`tcoef_full'" in colnames 
        matrix b  = e(b) 
        matrix V  = e(V) 
        local beta    = b[1, `pos'] 
        local se      = sqrt(V[`pos', `pos']) 
        local n_total = e(N) 
 
        // ddml uses z-statistics; guard against missing df_r. 
        if !missing(e(df_r)) & e(df_r) < . { 
            local pval = 2 * ttail(e(df_r), abs(`beta' / `se')) 
        } 
        else { 
            local pval = 2 * (1 - normal(abs(`beta' / `se'))) 
        } 
 
        local n_treated  = e(n_treated) 
        local n_control  = e(n_control) 
        local joint_f_p  = e(joint_f_p) 
        local vars_used  = e(vars_used) 
        local method_lbl = e(method) 
        if "`method_lbl'" == "" local method_lbl "ddml" 
 
        // vars_used contains only Stata variable names and semicolons -- 
        // no commas, so no CSV quoting needed. 
        file write fh "`m',`method_lbl'," %9.4f (`beta') "," %9.4f (`se') "," /// 
            %9.4f (`pval') "," %9.0f (`n_treated') "," %9.0f (`n_control')     /// 
            "," %9.0f (`n_total') ",`vars_used'," %9.4f (`joint_f_p')          /// 
            ",`row_estimand'" _n 
    } 
 
    file close fh 
end 

 

 
