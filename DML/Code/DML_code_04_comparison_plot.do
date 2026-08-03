
*========================================================================= 
* DML_code_04_comparison_plot.do 
* Identical plot logic/format to Matching_code_15_comparison_plot.do -- 
* same CI formula, same layout -- so DML and Matching results are visually 
* comparable side by side. 
*========================================================================= 
clear all 
set more off 
cd "/Users/aaronjoseph/Downloads/Capstone/Felipe" 
global out_dml "DML/Output" 
 
local true_effect = -0.14 
 
import delimited "$out_dml/output_dml_method_comparison_table.csv", clear varnames(1) case(preserve) 
 
gen double ci_lo = Beta - 1.96*SE 
gen double ci_hi = Beta + 1.96*SE 
gen y = _n 
 
local ylabels "" 
forvalues i = 1/`=_N' { 
    local lbl = Model[`i'] 
    local ylabels `ylabels' `i' "`lbl'" 
} 
 
twoway (rcap ci_lo ci_hi y, horizontal lcolor(gs8)) /// 
       (scatter y Beta, mcolor(navy) msymbol(D) msize(medium)), /// 
    xline(0, lcolor(red) lpattern(dash)) /// 
    xline(`true_effect', lcolor(green) lpattern(shortdash) lwidth(medthick)) /// 
    ylabel(`ylabels', angle(0) labsize(small)) ytitle("") /// 
    xtitle("Estimated coefficient (95% CI)") /// 
    title("DML Estimators vs. True Experimental Effect") /// 
    subtitle("Red = zero | Green = true experimental coefficient (`true_effect')") /// 
    legend(off) yscale(reverse) graphregion(color(white)) plotregion(margin(medium)) 
 
graph export "$out_dml/dml_comparison_plot.png", replace width(1600) 
di "DML comparison plot saved to $out_dml/dml_comparison_plot.png" 
