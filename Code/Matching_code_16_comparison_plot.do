*============================================================================= 
* Matching_code_16_comparison_plot.do 
* 
* Purpose: Coefficient plot comparing point estimates and 95% CIs across 
* all nonexperimental methods in the shared comparison file, with 
* reference lines at zero and at the true experimental benchmark. 
* 
* Requires: Matching_code_08_setup.do already run this session (for 
* $out_match). Can also run standalone -- only reads the CSV produced 
* by codes 09-15. 
* 
* Input:  Matching/Output/Matching_output_effect_comparison.csv 
* Output: Matching/Output/effect_comparison_plot.png 
*         Matching/Output/output_code_16_comparison_plot.txt (log) 
* 
* Author: Aaron Joseph 
*============================================================================= 
clear all 
set more off 
cd "/Users/aaronjoseph/Downloads/Capstone/Felipe" 
 
global out_match "Matching/Output" 
cap log close 
log using "$out_match/output_code_16_comparison_plot.txt", text replace 
 
* Known experimental benchmark. Set to "" to omit the reference line. 
local true_effect = -0.14 
 
import delimited "$out_match/Matching_output_effect_comparison.csv", /// 
	clear varnames(1) case(preserve) 
 
* CI from Beta/SE, consistent with how SEs were computed upstream. 
gen double ci_lo = Beta - 1.96*SE 
gen double ci_hi = Beta + 1.96*SE 
 
* Order methods for display: strongest designs first, Doubly Robust 
* (AIPW) after the matching methods, diff-in-means last as baseline. 
gen order = . 
replace order = 1 if Model == "CEM-matched DiD" 
replace order = 2 if Model == "CEM (PSM variables)" 
replace order = 3 if strpos(Model, "PSM (") == 1 
replace order = 4 if Model == "Entropy Balancing" 
replace order = 5 if Model == "LASSO(adaptive)+CEM" 
replace order = 6 if Model == "Doubly Robust (AIPW)" 
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
 
twoway /// 
	(rcap ci_lo ci_hi y, horizontal lcolor(gs8)) /// 
	(scatter y Beta, mcolor(navy) msymbol(D) msize(medium)), /// 
	xline(0, lcolor(red) lpattern(dash)) /// 
	xline(`true_effect', lcolor(green) lpattern(shortdash) lwidth(medthick)) /// 
	ylabel(`ylabels', angle(0) labsize(small)) /// 
	ytitle("") /// 
	xtitle("Estimated coefficient (95% CI)") /// 
	title("Nonexperimental Estimators vs. True Experimental Effect") /// 
	subtitle("Red = zero | Green = true experimental coefficient (`true_effect')") /// 
	legend(off) /// 
	yscale(reverse) /// 
	graphregion(color(white)) plotregion(margin(medium)) 
 
graph export "$out_match/effect_comparison_plot.png", replace width(1600) 
 
di "Comparison plot saved to $out_match/effect_comparison_plot.png" 
log close 

 

 
