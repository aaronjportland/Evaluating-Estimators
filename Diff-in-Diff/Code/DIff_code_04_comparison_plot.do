*============================================================================== 
* Diff_code_04_comparison_plot.do 
* Date: 08/07/2026 
* Author: Aaron Joseph 
* 
* Purpose: Identical plot logic and format to Matching_code_16 and 
* DML_code_04 so DiD results are visually comparable side by side. 
* Builds the comparison dataset directly from stored .ster files (the DiD 
* pipeline does not produce a method-comparison CSV natively), draws a 
* coefficient plot saved to Diff-in-Diff/Output/, appends the RCT benchmark 
* row, exports Results/did_method_comparison.csv, and draws the Results/ 
* comparison plot. 
* 
* Does NOT edit Diff_code_01 or Diff_code_02. 
* 
* Inputs (estimates): 
*   Diff-in-Diff/Output/simple_diff_in_diff_business_practices.ster 
*   Diff-in-Diff/Output/diff_in_diff_full_interactive_business_practices.ster 
*   Diff-in-Diff/Output/diff_in_diff_full_interactive_fe_business_practices.ster 
*   Experiment/Output/experiment_itt.ster 
* 
* Outputs: 
*   Diff-in-Diff/Output/did_comparison_plot.png 
*   Results/did_method_comparison.csv 
*   Results/did_comparison_plot.png 
* 
* Main steps: 
* 
*   1. Build the comparison dataset from stored .ster files. 
*   2. Compute confidence intervals and y-axis labels. 
*   3. Draw the coefficient plot and save to Diff-in-Diff/Output/. 
*   4. Pull the RCT benchmark from the stored .ster file. 
*   5. Append the RCT benchmark row and export to Results/. 
*   6. Draw the Results/ comparison plot. 
*============================================================================== 
 
clear all 
set more off 
cd "/Users/aaronjoseph/Downloads/Capstone/Felipe" 
 
global out_did "Diff-in-Diff/Output" 
cap mkdir "Results" 
 
local true_effect = -0.14 
 
// Step 1: Build the comparison dataset from stored .ster files. 
// 
// Coefficient names differ across the three models because each was estimated 
// with a different command: 
// 
//   ster1 (simple DiD): last command in Diff_code_01/02 is xtdidregress / 
//     didregress, which stores the ATET in a sub-equation. Confirmed via 
//     matrix list e(b): column is "ATET:r1vs0.did". 
// 
//   ster2 (full interactive, no FE): estimated with reg, so column is "did". 
//   ster3 (full interactive, FE):    estimated with xtreg, so column is "did". 
 
local n_models = 3 
 
local ster1 "$out_did/simple_diff_in_diff_business_practices.ster" 
local ster2 "$out_did/diff_in_diff_full_interactive_business_practices.ster" 
local ster3 "$out_did/diff_in_diff_full_interactive_fe_business_practices.ster" 
 
local lbl1  "DiD (Simple)" 
local lbl2  "DiD (Full Interactive)" 
local lbl3  "DiD (Full Interactive FE)" 
 
// Exact e(b) column name for the treatment coefficient in each model. 
local coef1 "ATET:r1vs0.did" 
local coef2 "did" 
local coef3 "did" 
 
clear 
set obs `n_models' 
gen str60  Model    = "" 
gen double Beta     = . 
gen double SE       = . 
gen double PValue   = . 
gen double N_Total  = . 
gen str20  Pipeline = "Diff-in-Diff" 
gen str10  Estimand = "ATT" 
 
forvalues i = 1/`n_models' { 
 
    capture estimates use "`ster`i''" 
    if _rc { 
        di as error "WARNING: could not load `ster`i'' -- row `i' left missing." 
        replace Model = "`lbl`i''" in `i' 
        continue 
    } 
 
    // colnumb handles both plain names ("did") and equation:name notation 
    // ("ATET:r1vs0.did"), so no special parsing is needed. 
    local cname "`coef`i''" 
    capture local pos = colnumb(e(b), "`cname'") 
    if _rc | `pos' == . { 
        di as error "WARNING: '`cname'' not found in `ster`i'' -- row `i' left missing." 
        di as error "         Run: estimates use `ster`i'', then: matrix list e(b)" 
        replace Model = "`lbl`i''" in `i' 
        continue 
    } 
 
    matrix b_tmp = e(b) 
    matrix V_tmp = e(V) 
    local b_val  = b_tmp[1, `pos'] 
    local se_val = sqrt(V_tmp[`pos', `pos']) 
    local n_val  = e(N) 
 
    replace Model   = "`lbl`i''"                                       in `i' 
    replace Beta    = `b_val'                                          in `i' 
    replace SE      = `se_val'                                         in `i' 
    replace N_Total = `n_val'                                          in `i' 
    replace PValue  = 2 * ttail(`n_val' - 1, abs(`b_val' / `se_val')) in `i' 
} 
 
// Step 2: Compute confidence intervals and y-axis labels. 
 
gen double ci_lo = Beta - 1.96 * SE 
gen double ci_hi = Beta + 1.96 * SE 
gen y = _n 
 
local ylabels "" 
forvalues i = 1/`=_N' { 
    local lbl = Model[`i'] 
    local ylabels `ylabels' `i' "`lbl'" 
} 
 
// Step 3: Draw the coefficient plot and save to Diff-in-Diff/Output/. 
 
twoway                                                                          /// 
    (rcap ci_lo ci_hi y, horizontal lcolor(gs8))                                /// 
    (scatter y Beta, mcolor(navy) msymbol(D) msize(medium)),                    /// 
    xline(0, lcolor(red) lpattern(dash))                                        /// 
    xline(`true_effect', lcolor(green) lpattern(shortdash) lwidth(medthick))   /// 
    ylabel(`ylabels', angle(0) labsize(small)) ytitle("")                       /// 
    xtitle("Estimated coefficient (95% CI)")                                    /// 
    title("DiD Estimators vs. True Experimental Effect")                        /// 
    subtitle("Red = zero | Green = RCT benchmark (`true_effect')")              /// 
    legend(off) yscale(reverse) graphregion(color(white)) plotregion(margin(medium)) 
 
graph export "$out_did/did_comparison_plot.png", replace width(1600) 
di "DiD comparison plot saved to $out_did/did_comparison_plot.png" 
 
// Step 4: Pull the RCT benchmark from the stored .ster file. 
 
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
        local rct_beta = b[1, `pos'] 
        local rct_se   = sqrt(V[`pos', `pos']) 
        local rct_n    = e(N) 
        local have_rct = 1 
    } 
} 
 
// Step 5: Append the RCT benchmark row and export to Results/. 
 
if `have_rct' { 
    local nobs = _N + 1 
    set obs `nobs' 
    replace Model    = "RCT (ITT benchmark)" in `nobs' 
    replace Pipeline = "RCT"                 in `nobs' 
    replace Estimand = "ITT"                 in `nobs' 
    replace Beta     = `rct_beta'            in `nobs' 
    replace SE       = `rct_se'              in `nobs' 
    replace N_Total  = `rct_n'              in `nobs' 
    replace PValue   = 2 * ttail(`rct_n' - 1, abs(`rct_beta' / `rct_se')) in `nobs' 
} 
else { 
    di as error "NOTE: experiment_itt.ster not found -- RCT row omitted from Results/ output." 
} 
 
cap drop ci_lo ci_hi 
gen double ci_lo = Beta - 1.96 * SE 
gen double ci_hi = Beta + 1.96 * SE 
 
export delimited using "Results/did_method_comparison.csv", replace 
di "Results/did_method_comparison.csv written." 
 
// Step 6: Draw the Results/ comparison plot. 
// RCT row sits at the bottom as a visual reference point, consistent 
// with Matching_code_16 and DML_code_04. 
 
gen order2 = _n 
replace order2 = 99 if Model == "RCT (ITT benchmark)" 
sort order2 
gen y2 = _n 
 
local ylabels2 "" 
local n2 = _N 
forvalues i = 1/`n2' { 
    local lbl = Model[`i'] 
    local ylabels2 `ylabels2' `i' "`lbl'" 
} 
 
twoway                                                                          /// 
    (rcap ci_lo ci_hi y2, horizontal lcolor(gs8))                               /// 
    (scatter y2 Beta, mcolor(navy) msymbol(D) msize(medium)),                   /// 
    xline(0, lcolor(red) lpattern(dash))                                        /// 
    xline(`true_effect', lcolor(green) lpattern(shortdash) lwidth(medthick))   /// 
    ylabel(`ylabels2', angle(0) labsize(small))                                 /// 
    ytitle("")                                                                  /// 
    xtitle("Estimated coefficient (95% CI)")                                    /// 
    title("DiD Estimators vs. RCT Benchmark")                                   /// 
    subtitle("Red = zero | Green = RCT benchmark (`true_effect')")              /// 
    legend(off) yscale(reverse) graphregion(color(white)) plotregion(margin(medium)) 
 
graph export "Results/did_comparison_plot.png", replace width(1600) 
di "Results/did_comparison_plot.png written." 
