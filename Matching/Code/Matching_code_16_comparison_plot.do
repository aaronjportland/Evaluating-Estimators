*============================================================================== 
* Matching_code_16_comparison_plot.do 
* Date: 08/07/2026 | Author: Aaron Joseph 
* 
* Coefficient plot across all nonexperimental methods + RCT benchmark. 
* Also exports Results/matching_method_comparison.csv and comparison plot. 
* Input:  Matching_output_effect_comparison.csv, 
*         Experiment/Output/experiment_itt.ster 
* Output: effect_comparison_plot.png, matching_method_comparison.csv, 
*         matching_comparison_plot.png 
*============================================================================== 
clear all 
set more off 
cd "/Users/aaronjoseph/Downloads/Capstone/Felipe" 
 
global out_match "Matching/Output" 
cap mkdir "Results" 
cap log close 
log using "$out_match/output_code_16_comparison_plot.txt", text replace 
 
local true_effect = -0.14 
 
// Shared helper: assign display ordering for all methods. 
// Called on whatever dataset is current. 
capture program drop apply_plot_order 
program define apply_plot_order 
    args ordvar 
    gen `ordvar' = . 
    replace `ordvar' = 1  if Model == "CEM-matched DiD" 
    replace `ordvar' = 2  if Model == "CEM (PSM variables)" 
    replace `ordvar' = 3  if strpos(Model, "PSM (") == 1 
    replace `ordvar' = 4  if Model == "Entropy Balancing" 
    replace `ordvar' = 5  if Model == "LASSO(adaptive)+CEM" 
    replace `ordvar' = 6  if strpos(Model, "Doubly Robust") == 1 
    replace `ordvar' = 7  if Model == "Diff-in-means (unadjusted)" 
    replace `ordvar' = 8  if Model == "RCT (ITT benchmark)" 
    replace `ordvar' = 99 if missing(`ordvar') 
end 
 
// Step 1: Import CSV and compute CIs. 
import delimited "$out_match/Matching_output_effect_comparison.csv", /// 
    clear varnames(1) case(preserve) 
gen double ci_lo = Beta - 1.96 * SE 
gen double ci_hi = Beta + 1.96 * SE 
 
// Step 2: Order and build y-axis labels. 
apply_plot_order order 
sort order 
gen y = _n 
 
local ylabels 
forvalues i = 1/`=_N' { 
    local ylabels `ylabels' `i' "`=Model[`i']'" 
} 
 
// Step 3: Draw Matching/Output/ comparison plot. 
twoway /// 
    (rcap ci_lo ci_hi y, horizontal lcolor(gs8)) /// 
    (scatter y Beta, mcolor(navy) msymbol(D) msize(medium)), /// 
    xline(0, lcolor(red) lpattern(dash)) /// 
    xline(`true_effect', lcolor(green) lpattern(shortdash) lwidth(medthick)) /// 
    ylabel(`ylabels', angle(0) labsize(small)) ytitle("") /// 
    xtitle("Estimated coefficient (95% CI)") /// 
    title("Nonexperimental Estimators vs. True Experimental Effect") /// 
    subtitle("Red = zero | Green = RCT benchmark (`true_effect')") /// 
    legend(off) yscale(reverse) graphregion(color(white)) plotregion(margin(medium)) 
graph export "$out_match/effect_comparison_plot.png", replace width(1600) 
 
// Step 4: Pull RCT benchmark. 
local have_rct = 0 
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
 
// Step 5: Reimport CSV, tag Pipeline, append RCT row, export to Results/. 
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
    replace PValue   = 2 * ttail(`rct_n' - 1, abs(`rct_beta' / `rct_se')) in `nobs' 
    gen double ci_lo = Beta - 1.96 * SE 
    gen double ci_hi = Beta + 1.96 * SE 
} 
else { 
    gen double ci_lo = Beta - 1.96 * SE 
    gen double ci_hi = Beta + 1.96 * SE 
    di as error "NOTE: experiment_itt.ster not found -- RCT row omitted." 
} 
 
export delimited using "Results/matching_method_comparison.csv", replace 
di "Results/matching_method_comparison.csv written." 
 
// Step 6: Draw Results/ comparison plot. 
apply_plot_order order2 
sort order2 
gen y2 = _n 
 
local ylabels2 
forvalues i = 1/`=_N' { 
    local ylabels2 `ylabels2' `i' "`=Model[`i']'" 
} 
 
twoway /// 
    (rcap ci_lo ci_hi y2, horizontal lcolor(gs8)) /// 
    (scatter y2 Beta, mcolor(navy) msymbol(D) msize(medium)), /// 
    xline(0, lcolor(red) lpattern(dash)) /// 
    xline(`true_effect', lcolor(green) lpattern(shortdash) lwidth(medthick)) /// 
    ylabel(`ylabels2', angle(0) labsize(small)) ytitle("") /// 
    xtitle("Estimated coefficient (95% CI)") /// 
    title("Matching Methods vs. RCT Benchmark") /// 
    subtitle("Red = zero | Green = RCT benchmark (`true_effect')") /// 
    legend(off) yscale(reverse) graphregion(color(white)) plotregion(margin(medium)) 
graph export "Results/matching_comparison_plot.png", replace width(1600) 
di "Results/matching_comparison_plot.png written." 
 
log close 
