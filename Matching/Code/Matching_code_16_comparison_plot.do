*============================================================================== 
* Matching_code_16_comparison_plot.do 
* Date: 08/07/2026 
* Author: Aaron Joseph 
* 
* Purpose: Coefficient plot comparing point estimates and 95% CIs across all 
* nonexperimental methods in the shared comparison file, with reference 
* lines at zero and at the true experimental benchmark. Also exports the 
* combined output (matching methods + RCT benchmark) to Results/ so it can 
* be compared directly against the DML pipeline output. 
* 
* Requires: Matching_code_08_setup.do already run this session. 
* 
* Input:  Matching/Output/Matching_output_effect_comparison.csv 
*         Experiment/Output/experiment_itt.ster (for RCT benchmark row) 
* Output: Matching/Output/effect_comparison_plot.png (unchanged) 
*         Matching/Output/output_code_16_comparison_plot.txt (log) 
*         Results/matching_method_comparison.csv (new) 
*         Results/matching_comparison_plot.png (new) 
* 
* Main steps: 
*   1. Import the shared effect-comparison CSV. 
*   2. Compute confidence intervals. 
*   3. Order methods for display and build y-axis labels. 
*   4. Draw the coefficient plot and save to Matching/Output/. 
*   5. Pull the RCT benchmark from the stored .ster file. 
*   6. Reimport the CSV, append the RCT row, and export to Results/. 
*   7. Draw the Results/ comparison plot. 
*============================================================================== 
 
clear all 
set more off 
cd "/Users/aaronjoseph/Downloads/Capstone/Felipe" 
 
global out_match "Matching/Output" 
cap mkdir "Results" 
cap log close 
log using "$out_match/output_code_16_comparison_plot.txt", text replace 
 
local true_effect = -0.14 
 
// Step 1: Import the shared effect-comparison CSV. 
import delimited "$out_match/Matching_output_effect_comparison.csv", /// 
    clear varnames(1) case(preserve) 
 
// Step 2: Compute confidence intervals. 
gen double ci_lo = Beta - 1.96*SE 
gen double ci_hi = Beta + 1.96*SE 
 
// Step 3: Order methods for display and build y-axis labels. 
gen order = . 
replace order = 1 if Model == "CEM-matched DiD" 
replace order = 2 if Model == "CEM (PSM variables)" 
replace order = 3 if strpos(Model, "PSM (") == 1 
replace order = 4 if Model == "Entropy Balancing" 
replace order = 5 if Model == "LASSO(adaptive)+CEM" 
replace order = 6 if strpos(Model, "Doubly Robust") == 1 
replace order = 7 if Model == "Diff-in-means (unadjusted)" 
replace order = 99 if missing(order) 
sort order 
gen y = _n 
 
local ylabels "" 
local n = _N 
forvalues i = 1/`n' { 
    local lbl = Model[`i'] 
    local ylabels `ylabels' `i' "`lbl'" 
} 
 
// Step 4: Draw the coefficient plot and save to Matching/Output/. 
twoway /// 
    (rcap ci_lo ci_hi y, horizontal lcolor(gs8)) /// 
    (scatter y Beta, mcolor(navy) msymbol(D) msize(medium)), /// 
    xline(0, lcolor(red) lpattern(dash)) /// 
    xline(`true_effect', lcolor(green) lpattern(shortdash) lwidth(medthick)) /// 
    ylabel(`ylabels', angle(0) labsize(small)) /// 
    ytitle("") /// 
    xtitle("Estimated coefficient (95% CI)") /// 
    title("Nonexperimental Estimators vs. True Experimental Effect") /// 
    subtitle("Red = zero | Green = RCT benchmark (`true_effect')") /// 
    legend(off) yscale(reverse) graphregion(color(white)) plotregion(margin(medium)) 
 
graph export "$out_match/effect_comparison_plot.png", replace width(1600) 
 
// Step 5: Pull the RCT benchmark from the stored .ster file. 
local have_rct = 0 
local rct_beta = . 
local rct_se   = . 
local rct_n    = . 
 
capture estimates use "Experiment/Output/experiment_itt.ster" 
if !_rc { 
    local colnames : colnames e(b) 
    local pos : list posof "treatment_assignment_binary" in colnames 
    if `pos' > 0 { 
        matrix b = e(b) 
        matrix V = e(V) 
        local rct_beta = b[1,`pos'] 
        local rct_se   = sqrt(V[`pos',`pos']) 
        local rct_n    = e(N) 
        local have_rct = 1 
    } 
} 
 
// Step 6: Reimport the CSV, append the RCT row, and export to Results/. 
* Reimport so the dataset is clean before adding the Pipeline column and 
* RCT row -- same pattern as DML_code_04 which works correctly. 
import delimited "$out_match/Matching_output_effect_comparison.csv", /// 
    clear varnames(1) case(preserve) 
 
gen str20 Pipeline = "Matching" 
 
if `have_rct' { 
    local nobs = _N + 1 
    set obs `nobs' 
    replace Model    = "RCT (ITT benchmark)" in `nobs' 
    replace Pipeline = "RCT"                 in `nobs' 
    replace Beta     = `rct_beta'            in `nobs' 
    replace SE       = `rct_se'              in `nobs' 
    replace N_Total  = `rct_n'              in `nobs' 
    replace PValue   = 2*ttail(`rct_n'-1, abs(`rct_beta'/`rct_se')) in `nobs' 
} 
else { 
    di as error "NOTE: experiment_itt.ster not found -- RCT row omitted from Results/ output." 
} 
 
cap drop ci_lo ci_hi 
gen double ci_lo = Beta - 1.96*SE 
gen double ci_hi = Beta + 1.96*SE 
 
export delimited using "Results/matching_method_comparison.csv", replace 
di "Results/matching_method_comparison.csv written." 
 
// Step 7: Draw the Results/ comparison plot. 
* Reapply ordering so the RCT row sits at the bottom as a reference point, 
* then use y2 = _n for the plot axis -- same approach as DML_code_04. 
gen order2 = . 
replace order2 = 1 if Model == "CEM-matched DiD" 
replace order2 = 2 if Model == "CEM (PSM variables)" 
replace order2 = 3 if strpos(Model, "PSM (") == 1 
replace order2 = 4 if Model == "Entropy Balancing" 
replace order2 = 5 if Model == "LASSO(adaptive)+CEM" 
replace order2 = 6 if strpos(Model, "Doubly Robust") == 1 
replace order2 = 7 if Model == "Diff-in-means (unadjusted)" 
replace order2 = 8 if Model == "RCT (ITT benchmark)" 
replace order2 = 99 if missing(order2) 
sort order2 
gen y2 = _n 
 
local ylabels2 "" 
local n2 = _N 
forvalues i = 1/`n2' { 
    local lbl = Model[`i'] 
    local ylabels2 `ylabels2' `i' "`lbl'" 
} 
 
twoway /// 
    (rcap ci_lo ci_hi y2, horizontal lcolor(gs8)) /// 
    (scatter y2 Beta, mcolor(navy) msymbol(D) msize(medium)), /// 
    xline(0, lcolor(red) lpattern(dash)) /// 
    xline(`true_effect', lcolor(green) lpattern(shortdash) lwidth(medthick)) /// 
    ylabel(`ylabels2', angle(0) labsize(small)) /// 
    ytitle("") /// 
    xtitle("Estimated coefficient (95% CI)") /// 
    title("Matching Methods vs. RCT Benchmark") /// 
    subtitle("Red = zero | Green = RCT benchmark (`true_effect')") /// 
    legend(off) yscale(reverse) graphregion(color(white)) plotregion(margin(medium)) 
 
graph export "Results/matching_comparison_plot.png", replace width(1600) 
di "Results/matching_comparison_plot.png written." 
 
log close 
