*========================================================================= 
* DML_code_04_comparison_plot.do 
* Date: 08/07/2026 
* Author: Aaron Joseph 
* 
* Purpose: Identical plot logic/format to Matching_code_16 so DML and 
* Matching results are visually comparable side by side. Also exports the 
* combined output (DML methods + RCT benchmark) to Results/ so that 
* Results_combine_all.do can import it. 
* 
* Input:  DML/Output/output_dml_method_comparison_table.csv 
*         Experiment/Output/experiment_itt.ster  (for RCT benchmark row) 
* 
* Output: DML/Output/dml_comparison_plot.png 
*         Results/dml_method_comparison.csv   <- consumed by Results_combine_all.do 
*     
* Main steps: 
*   1. Import the DML method-comparison CSV. 
*   2. Compute confidence intervals and y-axis labels. 
*   3. Draw the coefficient plot and save to DML/Output/. 
*   4. Pull the RCT benchmark estimate.  
*   5. Reload the DML comparison CSV and setup export to Results/.
*   6. Re-draw the combined (DML + RCT) plot for Results/.
*========================================================================= 
clear all 
set more off 
cd "/Users/aaronjoseph/Downloads/Capstone/Felipe" 
global out_dml "DML/Output" 
cap mkdir "Results" 
 
local true_effect = -0.14 
 
// Step 1: Import the DML method-comparison CSV. 
import delimited "$out_dml/output_dml_method_comparison_table.csv", /// 
    clear varnames(1) case(preserve) 
 
// Step 2: Compute confidence intervals and y-axis labels. 
gen double ci_lo = Beta - 1.96 * SE 
gen double ci_hi = Beta + 1.96 * SE 
gen y = _n 
 
local ylabels "" 
forvalues i = 1/`=_N' { 
    local lbl = Model[`i'] 
    local ylabels `ylabels' `i' "`lbl'" 
} 
 
// Step 3: Draw the coefficient plot and save to DML/Output/. 
twoway                                                                       /// 
    (rcap ci_lo ci_hi y, horizontal lcolor(gs8))                             /// 
    (scatter y Beta, mcolor(navy) msymbol(D) msize(medium)),                 /// 
    xline(0, lcolor(red) lpattern(dash))                                     /// 
    xline(`true_effect', lcolor(green) lpattern(shortdash) lwidth(medthick)) /// 
    ylabel(`ylabels', angle(0) labsize(small)) ytitle("")                    /// 
    xtitle("Estimated coefficient (95% CI)")                                 /// 
    title("DML Estimators vs. True Experimental Effect")                     /// 
    subtitle("Red = zero | Green = RCT benchmark (`true_effect')")           /// 
    legend(off) yscale(reverse) graphregion(color(white)) plotregion(margin(medium)) 
 
graph export "$out_dml/dml_comparison_plot.png", replace width(1600) 
di "DML comparison plot saved to $out_dml/dml_comparison_plot.png" 
 
// Step 4: Pull the RCT benchmark estimate. 
local have_rct = 0 
local rct_beta = . 
local rct_se   = . 
local rct_n    = . 
 
capture estimates use "Experiment/Output/experiment_itt.ster" 
if !_rc { 
    local colnames : colnames e(b) 
    local pos : list posof "treatment_assignment_binary" in colnames 
    if `pos' > 0 { 
        matrix b       = e(b) 
        matrix V       = e(V) 
        local rct_beta = b[1, `pos'] 
        local rct_se   = sqrt(V[`pos', `pos']) 
        local rct_n    = e(N) 
        local have_rct = 1 
    } 
} 
 
// Step 5: Reload the DML comparison CSV, add Pipeline column, append the 
// RCT benchmark row, recompute CIs, and export to Results/. 
import delimited "$out_dml/output_dml_method_comparison_table.csv", /// 
    clear varnames(1) case(preserve) 
 
// Tag all DML rows with Pipeline = "DML". 
gen str20 Pipeline = "DML" 
 
// Append the RCT benchmark row. 
if `have_rct' { 
    local nobs = _N + 1 
    set obs `nobs' 
    replace Model    = "RCT (ITT benchmark)" in `nobs' 
    replace Pipeline = "RCT"                  in `nobs' 
    replace Beta     = `rct_beta'             in `nobs' 
    replace SE       = `rct_se'               in `nobs' 
    replace N_Total  = `rct_n'                in `nobs'   // N_Total; no bare N column 
    replace Estimand = "ITT"                  in `nobs' 
} 
else { 
    di as error "NOTE: experiment_itt.ster not found -- RCT row omitted from Results/ output." 
} 
 
// Recompute CIs on the full (DML + RCT) dataset. 
cap drop ci_lo ci_hi 
gen double ci_lo = Beta - 1.96 * SE 
gen double ci_hi = Beta + 1.96 * SE 
 
// Export to Results/ -- this is what Results_combine_all.do reads. 
export delimited using "Results/dml_method_comparison.csv", replace 
di "Results/dml_method_comparison.csv written." 
 
// Step 6: Re-draw the combined (DML + RCT) plot for Results/. 
gen y2 = _n 
local ylabels2 "" 
local n2 = _N 
forvalues i = 1/`n2' { 
    local lbl = Model[`i'] 
    local ylabels2 `ylabels2' `i' "`lbl'" 
} 
 
twoway                                                                       /// 
    (rcap ci_lo ci_hi y2, horizontal lcolor(gs8))                            /// 
    (scatter y2 Beta, mcolor(navy) msymbol(D) msize(medium)),                /// 
    xline(0, lcolor(red) lpattern(dash))                                     /// 
    xline(`true_effect', lcolor(green) lpattern(shortdash) lwidth(medthick)) /// 
    ylabel(`ylabels2', angle(0) labsize(small))                              /// 
    ytitle("")                                                               /// 
    xtitle("Estimated coefficient (95% CI)")                                 /// 
    title("DML Estimators vs. RCT Benchmark")                                /// 
    subtitle("Red = zero | Green = RCT benchmark (`true_effect')")           /// 
    legend(off) yscale(reverse) graphregion(color(white)) plotregion(margin(medium)) 
 
graph export "Results/dml_comparison_plot.png", replace width(1600) 
di "Results/dml_comparison_plot.png written." 
di "" 
di "Results/dml_method_comparison.csv is ready for Results_combine_all.do." 
