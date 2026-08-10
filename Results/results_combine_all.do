*============================================================================== 
* Results_combine_all.do 
* 
* Date: 08/07/2026 
* Author: Aaron Joseph 
* 
* Loads stored estimates from all pipelines, produces a coefplot and esttab 
* tables, then merges the output CSVs from the Original, Matching, and DML 
* pipelines into a single unified comparison table in Results/. 
* Run this after all pipelines have produced their .ster and CSV outputs. 
* 
* Inputs (estimates): 
*   Experiment/Output/experiment_itt.ster 
*   Matching/Output/output_code_04a_naive_RAIS_2016_itt.ster 
*   Matching/Output/output_code_04a_propensity_score_matching_RAIS_2016_itt.ster 
*   Matching/Output/output_code_05a_LASSO_propensity_score_matching_RAIS_2016.ster 
*   Matching/Output/output_code_06_coarsened_exact_matching.ster 
*   Matching/Output/output_code_07_teffects_nnmatch_RAIS_2016.ster 
*   RDD/Output/rdd_sharp.ster 
*   Diff-in-Diff/Output/simple_diff_in_diff_business_practices.ster 
*   Diff-in-Diff/Output/diff_in_diff_full_interactive_business_practices.ster 
*   Diff-in-Diff/Output/diff_in_diff_full_interactive_fe_business_practices.ster 
* 
* Inputs (CSVs): 
*   Results/treatment_table_original.csv  (see note below) 
*   Results/matching_method_comparison.csv 
*   Results/dml_method_comparison.csv 
*   Results/did_method_comparison.csv 
* 
* Outputs: 
*   Results/treatment_table.rtf 
*   Results/treatment_table.tex 
*   Results/all_methods_combined.csv 
*   Results/all_methods_combined_plot.png 
* 
* Main steps: 
*   1. Load stored estimates from all pipelines. 
*   2. Produce coefplot (90% CI, bar style). 
*   3. Produce esttab tables (.rtf and .tex). 
*   4. Import CSVs into tempfiles and append. 
*   5. De-duplicate the RCT benchmark row. 
*   6. Write the combined CSV. 
*   7. Draw a single combined coefficient plot. 
*============================================================================== 
 
clear all 
set more off 
cd "/Users/aaronjoseph/Downloads/Capstone/Felipe" 
 
local true_effect = -0.14 
 
*------------------------------------------------------------------------------ 
* NOTE: treatment_table_original.csv is not produced automatically by the 
* original pipeline script (which writes .rtf/.tex via esttab). Add this 
* one line to the END of that script to generate the CSV this combiner reads: 
* 
*   export delimited "Results/treatment_table_original.csv", replace 
* 
* Alternatively export the table manually once, or replace the esttab call 
* with export delimited if you want a fully automated run. 
*------------------------------------------------------------------------------ 
 
// Step 1: Load stored estimates from all pipelines. 
 
estimates use "Experiment/Output/experiment_itt.ster" 
estimates store m0 
 
estimates use "Matching/Output/output_code_04a_naive_RAIS_2016_itt.ster" 
estimates store m1 
 
estimates use "Matching/Output/output_code_04a_propensity_score_matching_RAIS_2016_itt.ster" 
estimates store m2 
 
estimates use "Matching/Output/output_code_05a_LASSO_propensity_score_matching_RAIS_2016.ster" 
estimates store m3 
 
estimates use "Matching/Output/output_code_06_coarsened_exact_matching.ster" 
estimates store m4 
 
estimates use "Matching/Output/output_code_07_teffects_nnmatch_RAIS_2016.ster" 
nlcom treatment_assignment_binary: _b[r1vs0.treatment_assignment_binary], post 
estimates store m5 
 
estimates use "RDD/Output/rdd_sharp.ster" 
nlcom treatment_assignment_binary: _b[treat_employees], post 
estimates store rdd1 
 
// simple_diff_in_diff_business_practices.ster captures the last estimation 
// command in Diff_code_01/02, which is xtdidregress/didregress. That command 
// stores the ATET in the ATET equation under r1vs0.did, not as a plain _b[did]. 
estimates use "Diff-in-Diff/Output/simple_diff_in_diff_business_practices.ster" 
nlcom treatment_assignment_binary: _b[ATET:r1vs0.did], post 
estimates store dd1 
 
// Fully interactive DiD (no FE). 
// did is a plain binary (gen did = post*treatment), so _b[did] directly. 
estimates use "Diff-in-Diff/Output/diff_in_diff_full_interactive_business_practices.ster" 
nlcom treatment_assignment_binary: _b[did], post 
estimates store dd2 
 
// Fully interactive DiD with firm fixed effects. 
// Only post, did, and post x X are identified after within-transformation; 
// the did coefficient maps to the ATET of interest. 
estimates use "Diff-in-Diff/Output/diff_in_diff_full_interactive_fe_business_practices.ster" 
nlcom treatment_assignment_binary: _b[did], post 
estimates store dd3 
 
// Step 2: Produce coefplot (bar style, 90% CI). 
 
coefplot                                                          /// 
    (m0,   label("RCT"))                                          /// 
    (m1,   label("Simple Comparison"))                            /// 
    (m2,   label("Propensity Score"))                             /// 
    (m3,   label("LASSO + Pscore"))                               /// 
    (m4,   label("CEM"))                                          /// 
    (m5,   label("Euclidean Distance"))                           /// 
    (rdd1, label("RDD"))                                          /// 
    (dd1,  label("DiD (Simple)"))                                 /// 
    (dd2,  label("DiD (Full Interactive)"))                       /// 
    (dd3,  label("DiD (Full Interactive FE)")),                   /// 
    keep(treatment_assignment_binary)                             /// 
    vertical                                                      /// 
    recast(bar)                                                   /// 
    citop                                                         /// 
    ci(90)                                                        /// 
    ciopts(lcolor(black) recast(rcap))                            /// 
    title("Comparison of Treatment Effect Estimates (90% CI)", size(large)) /// 
    yline(0, lcolor(black) lpattern(dash))                        /// 
    graphregion(color(white))                                     /// 
    barwidth(0.1) 
 
// Step 3: Produce esttab tables (.rtf and .tex). 
 
esttab m0 m1 m2 m3 m4 m5 rdd1 dd1 dd2 dd3                        /// 
    using "Results/treatment_table.rtf", replace                  /// 
    b(3) se parentheses star(* 0.10 ** 0.05 *** 0.01)            /// 
    keep(treatment_assignment_binary)                             /// 
    mtitles("RCT" "Simple Comparison" "Propensity Score"          /// 
            "LASSO + Pscore" "CEM" "Euclidean Distance" "RDD"    /// 
            "DiD (Simple)" "DiD (Full Int.)" "DiD (Full Int. FE)") /// 
    varlabels(treatment_assignment_binary "ATET")                 /// 
    label title("Comparing methods") align(center) eqlabels(" " " ") 
 
esttab m0 m1 m2 m3 m4 m5 rdd1 dd1 dd2 dd3                        /// 
    using "Results/treatment_table.tex", replace                  /// 
    b(3) se parentheses star(* 0.10 ** 0.05 *** 0.01)            /// 
    keep(treatment_assignment_binary)                             /// 
    mtitles("RCT" "Simple Comparison" "Propensity Score"          /// 
            "LASSO + Pscore" "CEM" "Euclidean Distance" "RDD"    /// 
            "DiD (Simple)" "DiD (Full Int.)" "DiD (Full Int. FE)") /// 
    varlabels(treatment_assignment_binary "ATET")                 /// 
    label title("Comparing methods") align(center) eqlabels(" " " ") 
 
// Step 4: Import CSVs into tempfiles and append. 
// did_method_comparison.csv is produced by Diff_code_04_comparison_plot.do. 
 
tempfile orig match dml did 
 
capture { 
    import delimited "Results/treatment_table_original.csv", clear varnames(1) case(preserve) 
    cap drop Joint_MVTest_Pvalue 
    cap drop Coef_Name 
    cap gen str20 Pipeline = "Original" 
    replace Pipeline = "Original" if missing(Pipeline) 
    save `orig' 
} 
 
capture { 
    import delimited "Results/matching_method_comparison.csv", clear varnames(1) case(preserve) 
    cap drop Joint_MVTest_Pvalue 
    cap drop Coef_Name 
    save `match' 
} 
 
capture { 
    import delimited "Results/dml_method_comparison.csv", clear varnames(1) case(preserve) 
    cap drop Joint_MVTest_Pvalue 
    cap drop Coef_Name 
    save `dml' 
} 
 
capture { 
    import delimited "Results/did_method_comparison.csv", clear varnames(1) case(preserve) 
    cap drop Joint_MVTest_Pvalue 
    cap drop Coef_Name 
    save `did' 
} 
 
local started = 0 
foreach f in orig match dml did { 
    capture confirm file "``f''" 
    if !_rc { 
        if `started' == 0 { 
            use ``f'', clear 
            local started = 1 
        } 
        else { 
            append using ``f'' 
        } 
    } 
    else { 
        di as error "NOTE: tempfile for `f' not created -- input CSV or estimate may be missing." 
    } 
} 
 
if `started' == 0 { 
    di as error "ERROR: no input CSVs found in Results/. Run the pipeline scripts first." 
    exit 601 
} 
 
// Step 5: De-duplicate the RCT benchmark row. 
// Each pipeline appends its own RCT row; keep only one. 
 
bysort Model (Pipeline): gen dup = _n 
drop if Model == "RCT (ITT benchmark)" & dup > 1 
drop dup 
 
// Step 6: Write the combined CSV. 
 
cap drop ci_lo ci_hi 
gen double ci_lo = Beta - 1.96 * SE 
gen double ci_hi = Beta + 1.96 * SE 
 
export delimited using "Results/all_methods_combined.csv", replace 
di "Results/all_methods_combined.csv written." 
 
// Step 7: Draw a single combined coefficient plot. 
// Colour-code by pipeline so the four groups are visually distinct. 
 
gen byte pipeline_code = 1 if Pipeline == "Original" 
replace pipeline_code = 2 if Pipeline == "Matching" 
replace pipeline_code = 3 if Pipeline == "DML" 
replace pipeline_code = 4 if Pipeline == "Diff-in-Diff" 
replace pipeline_code = 0 if Model == "RCT (ITT benchmark)" 
 
sort pipeline_code Model 
cap drop y 
gen y = _n 
 
local ylabels "" 
forvalues i = 1/`=_N' { 
    local lbl = Model[`i'] 
    local ylabels `ylabels' `i' "`lbl'" 
} 
 
twoway                                                                         /// 
    (rcap ci_lo ci_hi y if pipeline_code==0, horizontal                       /// 
        lcolor(green) lwidth(medthick))                                        /// 
    (rcap ci_lo ci_hi y if pipeline_code==2, horizontal lcolor(navy))         /// 
    (rcap ci_lo ci_hi y if pipeline_code==3, horizontal lcolor(maroon))       /// 
    (rcap ci_lo ci_hi y if pipeline_code==4, horizontal lcolor(purple))       /// 
    (scatter y Beta if pipeline_code==0,                                       /// 
        mcolor(green)  msymbol(D) msize(medium))                               /// 
    (scatter y Beta if pipeline_code==2,                                       /// 
        mcolor(navy)   msymbol(D) msize(medium))                               /// 
    (scatter y Beta if pipeline_code==3,                                       /// 
        mcolor(maroon) msymbol(D) msize(medium))                               /// 
    (scatter y Beta if pipeline_code==4,                                       /// 
        mcolor(purple) msymbol(D) msize(medium)),                              /// 
    xline(0, lcolor(red) lpattern(dash))                                       /// 
    xline(`true_effect', lcolor(green) lpattern(shortdash) lwidth(medthick))  /// 
    ylabel(`ylabels', angle(0) labsize(vsmall))                                /// 
    ytitle("")                                                                 /// 
    xtitle("Estimated coefficient (95% CI)")                                   /// 
    title("All Methods vs. RCT Benchmark")                                    /// 
    subtitle("Red = zero | Green line = RCT benchmark (`true_effect')")       /// 
    legend(order(5 "RCT" 6 "Matching" 7 "DML" 8 "Diff-in-Diff")              /// 
        rows(1) size(small))                                                   /// 
    yscale(reverse) graphregion(color(white)) plotregion(margin(medium)) 
 
graph export "Results/all_methods_combined_plot.png", replace width(2000) 
di "Results/all_methods_combined_plot.png written." 
 
di "" 
di "Run order reminder:" 
di "  1. Original pipeline script  -> Results/treatment_table_original.csv" 
di "  2. Matching_code_16_comparison_plot.do -> Results/matching_method_comparison.csv" 
di "  3. DML_code_04_comparison_plot.do      -> Results/dml_method_comparison.csv" 
di "  4. Diff_code_01 + Diff_code_03         -> Diff-in-Diff/Output/*.ster" 
di "  5. Diff_code_04_comparison_plot.do     -> Results/did_method_comparison.csv" 
di "  6. This script -> Results/treatment_table.rtf/.tex" 
di "                    Results/all_methods_combined.csv + .png" 
