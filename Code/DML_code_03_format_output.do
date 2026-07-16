 

*========================================================================= 
* DML_code_03_format_output.do 
* 
* Purpose: Consolidate partial-model (ATE) and interactive-model (AIPW/ 
*   ATET) DML results into summary CSVs, and compare both against the 
*   RCT ITT. 
* 
* Input:  DML/Output/dml_partial_*.ster, DML/Output/dml_int_*.ster, 
*         Experiment/Output/experiment_itt.ster 
* 
* Output: DML/Output/output_dml_partial_results_table.csv 
*         DML/Output/output_dml_interactive_results_table.csv 
*         DML/Output/output_dml_method_comparison_table.csv 
* 
* NOTE: partial DML and RCT ITT are ATE; interactive DML is ATET -- 
*   comparison table is directional/magnitude only. 
* 
* Author: Aaron Joseph 
* Date: 
*========================================================================= 
 
*------------------------------------------------------------------------- 
* Part 0: Settings 
*------------------------------------------------------------------------- 
clear all 
set more off 
cd "/Users/aaronjoseph/Downloads/Capstone/Felipe" 
 
global out_dml     "DML/Output" 
global out_results "$out_dml" 
cap mkdir "$out_dml" 
 
* Known treatment-variable names used anywhere in the pipeline 
global KNOWN_TREATVARS "treatment_assignment any_treatment treatment_y treatment_assignment_binary" 
 
*------------------------------------------------------------------------- 
* Helper: get_te -- pull treatment coefficient/SE/N from a stored estimate 
*------------------------------------------------------------------------- 
capture program drop get_te 
program define get_te, rclass 
    version 16 
    args storedname 
 
    quietly estimates restore `storedname' 
    local colnames : colnames e(b) 
 
    local tcoef "" 
    foreach cand of global KNOWN_TREATVARS { 
        local pos : list posof "`cand'" in colnames 
        if `pos' > 0 { 
            local tcoef "`cand'" 
            continue, break 
        } 
    } 
    if "`tcoef'" == "" { 
        return local coef "" 
        exit 
    } 
 
    local pos : list posof "`tcoef'" in colnames 
    matrix b = e(b) 
    matrix V = e(V) 
 
    return local coef "`tcoef'" 
    return scalar b  = b[1, `pos'] 
    return scalar se = sqrt(V[`pos', `pos']) 
    return scalar N  = e(N) 
end 
 
*------------------------------------------------------------------------- 
* Helper: write_te_row -- append one formatted row to an open CSV handle 
*------------------------------------------------------------------------- 
capture program drop write_te_row 
program define write_te_row 
    args fh label storedname 
 
    get_te `storedname' 
    if "`r(coef)'" == "" { 
        di as error "NOTE: no recognized treatment coefficient for `storedname' -- skipped." 
        exit 
    } 
 
    local b  = r(b) 
    local se = r(se) 
    local n  = r(N) 
    file write `fh' `"`label',`storedname',`r(coef)',"' %9.4f (`b') "," %9.4f (`se') "," %9.0f (`n') _n 
end 
 
*------------------------------------------------------------------------- 
* Part 1: Load partial-model DML estimates (ATE) 
*------------------------------------------------------------------------- 
local avail_partial 
 
capture estimates use "$out_dml/dml_partial_full.ster" 
if !_rc { 
    estimates store dml_partial_full 
    local avail_partial `avail_partial' dml_partial_full 
} 
else di as error "NOTE: dml_partial_full.ster not found -- run DML_code_01_partial_full_analysis.do first." 
 
capture estimates use "$out_dml/dml_partial_highcomp.ster" 
if !_rc { 
    estimates store dml_partial_highcomp 
    local avail_partial `avail_partial' dml_partial_highcomp 
} 
else di as error "NOTE: dml_partial_highcomp.ster not found -- run DML_code_02_subgroup_analysis.do first." 
 
capture estimates use "$out_dml/dml_partial_lowcomp.ster" 
if !_rc { 
    estimates store dml_partial_lowcomp 
    local avail_partial `avail_partial' dml_partial_lowcomp 
} 
else di as error "NOTE: dml_partial_lowcomp.ster not found -- run DML_code_02_subgroup_analysis.do first." 
 
capture estimates use "$out_dml/dml_partial_match.ster" 
if !_rc { 
    estimates store dml_partial_match 
    local avail_partial `avail_partial' dml_partial_match 
} 
else di as error "NOTE: dml_partial_match.ster not found -- run DML_code_02_subgroup_analysis.do first." 
 
*------------------------------------------------------------------------- 
* Part 2: Load interactive-model DML estimates (ATET) 
*------------------------------------------------------------------------- 
local avail_int 
 
capture estimates use "$out_dml/dml_int_full.ster" 
if !_rc { 
    estimates store dml_int_full 
    local avail_int `avail_int' dml_int_full 
} 
else di as error "NOTE: dml_int_full.ster not found -- run DML_code_01b_interactive_full_analysis.do first." 
 
capture estimates use "$out_dml/dml_int_highcomp.ster" 
if !_rc { 
    estimates store dml_int_highcomp 
    local avail_int `avail_int' dml_int_highcomp 
} 
else di as error "NOTE: dml_int_highcomp.ster not found -- run DML_code_02b_interactive_subgroup_analysis.do first." 
 
capture estimates use "$out_dml/dml_int_lowcomp.ster" 
if !_rc { 
    estimates store dml_int_lowcomp 
    local avail_int `avail_int' dml_int_lowcomp 
} 
else di as error "NOTE: dml_int_lowcomp.ster not found -- run DML_code_02b_interactive_subgroup_analysis.do first." 
 
capture estimates use "$out_dml/dml_int_match.ster" 
if !_rc { 
    estimates store dml_int_match 
    local avail_int `avail_int' dml_int_match 
} 
else di as error "NOTE: dml_int_match.ster not found -- run DML_code_02b_interactive_subgroup_analysis.do first." 
 
*------------------------------------------------------------------------- 
* Part 3: Load RCT ITT 
*------------------------------------------------------------------------- 
local have_rct = 0 
capture estimates use "Experiment/Output/experiment_itt.ster" 
if !_rc { 
    estimates store rct_itt 
    local have_rct = 1 
} 
else di as error "NOTE: experiment_itt.ster not found -- RCT ITT comparison will be skipped." 
 
if "`avail_partial'" == "" & "`avail_int'" == "" { 
    di as error "ERROR: no DML .ster files found. Run the DML analysis scripts first." 
    exit 601 
} 
 
*------------------------------------------------------------------------- 
* Part 4: Partial-model DML results table (ATE) 
*------------------------------------------------------------------------- 
file open partial_fh using "$out_results/output_dml_partial_results_table.csv", write replace 
file write partial_fh "model_label,stata_name,coef_name,beta,se,N" _n 
 
if `have_rct' write_te_row partial_fh "RCT ITT" rct_itt 
foreach m of local avail_partial { 
    write_te_row partial_fh "`m'" `m' 
} 
file close partial_fh 
 
di "" 
di "===========================================================================" 
di " Partial DML (ATE) results written to: $out_results/output_dml_partial_results_table.csv" 
di "===========================================================================" 
 
*------------------------------------------------------------------------- 
* Part 5: Interactive-model DML results table (ATET) 
*------------------------------------------------------------------------- 
file open int_fh using "$out_results/output_dml_interactive_results_table.csv", write replace 
file write int_fh "model_label,stata_name,coef_name,beta,se,N" _n 
 
if `have_rct' write_te_row int_fh "RCT ITT" rct_itt 
foreach m of local avail_int { 
    write_te_row int_fh "`m'" `m' 
} 
file close int_fh 
 
di "" 
di "===========================================================================" 
di " Interactive DML (ATET) results written to: $out_results/output_dml_interactive_results_table.csv" 
di "===========================================================================" 
 
*------------------------------------------------------------------------- 
* Part 6: Three-way method comparison (RCT ITT vs partial ATE vs int ATET) 
*------------------------------------------------------------------------- 
file open comp_fh using "$out_results/output_dml_method_comparison_table.csv", write replace 
file write comp_fh "sample,model_label,stata_name,coef_name,beta,se,N" _n 
 
* --- Full sample --- 
if `have_rct' { 
    get_te rct_itt 
    if "`r(coef)'" != "" file write comp_fh "Full sample,RCT ITT (ATE),rct_itt,`r(coef)'," %9.4f (r(b)) "," %9.4f (r(se)) "," %9.0f (r(N)) _n 
} 
if `: list posof "dml_partial_full" in avail_partial' { 
    get_te dml_partial_full 
    if "`r(coef)'" != "" file write comp_fh "Full sample,Partial DML (ATE),dml_partial_full,`r(coef)'," %9.4f (r(b)) "," %9.4f (r(se)) "," %9.0f (r(N)) _n 
} 
if `: list posof "dml_int_full" in avail_int' { 
    get_te dml_int_full 
    if "`r(coef)'" != "" file write comp_fh "Full sample,Interactive DML (ATET),dml_int_full,`r(coef)'," %9.4f (r(b)) "," %9.4f (r(se)) "," %9.0f (r(N)) _n 
} 
 
* --- Matching subsample --- 
if `have_rct' { 
    get_te rct_itt 
    if "`r(coef)'" != "" file write comp_fh "Matching subsample,RCT ITT (ATE),rct_itt,`r(coef)'," %9.4f (r(b)) "," %9.4f (r(se)) "," %9.0f (r(N)) _n 
} 
if `: list posof "dml_partial_match" in avail_partial' { 
    get_te dml_partial_match 
    if "`r(coef)'" != "" file write comp_fh "Matching subsample,Partial DML (ATE),dml_partial_match,`r(coef)'," %9.4f (r(b)) "," %9.4f (r(se)) "," %9.0f (r(N)) _n 
} 
if `: list posof "dml_int_match" in avail_int' { 
    get_te dml_int_match 
    if "`r(coef)'" != "" file write comp_fh "Matching subsample,Interactive DML (ATET),dml_int_match,`r(coef)'," %9.4f (r(b)) "," %9.4f (r(se)) "," %9.0f (r(N)) _n 
} 
 
file write comp_fh "NOTE,RCT ITT and Partial DML report ATE; Interactive DML reports ATET. Not identical estimands -- compare directionally only.,,,," _n 
file close comp_fh 
 
di "" 
di "===========================================================================" 
di " Three-way method comparison written to: $out_results/output_dml_method_comparison_table.csv" 
di "===========================================================================" 
 
*------------------------------------------------------------------------- 
* Part 7: Wrap-up 
*------------------------------------------------------------------------- 
di "" 
di "===========================================================================" 
di " Output formatting complete." 
di " Files saved:" 
di "   $out_results/output_dml_partial_results_table.csv" 
di "   $out_results/output_dml_interactive_results_table.csv" 
di "   $out_results/output_dml_method_comparison_table.csv" 
di " Partial models included:     `avail_partial'" 
di " Interactive models included: `avail_int'" 
di " RCT ITT included: " cond(`have_rct', "yes", "no") 
di " REMINDER: RCT ITT and partial-model DML are ATE; interactive-model DML" 
di " is ATET. The three-way comparison file is directional only." 
di "===========================================================================" 
