SSE Impact Evaluation Project — README 

Overview 

This project tests whether non-experimental methods can recover the known treatment effect from a real RCT. The SSE program's impact on firms' business practices was measured experimentally — the result is a null effect. The project then applies RDD, Matching, DiD, and DML to the same data to see how close each gets to that benchmark. 

 

1. Data Preparation (Experiment/Code/) 

Raw data from multiple SSE survey waves, the WBG survey, and RAIS administrative records are cleaned individually, key composite variables (business practices score, competition index, past service take-up) are constructed, and everything is merged into one master dataset used by all downstream analyses. 

 

2. Experimental Analysis — RCT (Experiment/Code/, Experiment/Output/) 

Defines the experimental sample, checks baseline balance and differential attrition, and estimates the ITT effect. The stored result (experiment_itt.ster) is the benchmark every other method is compared against. 

 

3. Regression Discontinuity Design (RDD/Code/, RDD/Output/) 

Builds Sharp and Fuzzy RDD samples around the program eligibility cutoff, validates the design (covariate smoothness, placebo cutoffs, McCrary density test), and estimates the local treatment effect across multiple bandwidths. 

 

4. Matching Analysis (Matching/Code/, Matching/Output/) 

Constructs a non-experimental control group from RAIS data and estimates the treatment effect using seven methods, each following the same structure: load sample, check balance, apply method, estimate effect, record result. 

Setup: One-time session configuration — packages, shared globals, file paths. 

Diff-in-means (code_09): Unadjusted treated vs. control comparison, used as a naive baseline. 

Propensity Score Matching (code_10): Matches on estimated treatment probability across eight specifications; keeps the best-balanced result. 

CEM (code_11): Matches firms on key characteristics using coarsened exact matching, then estimates a cross-sectional treatment effect. 

CEM + DiD (code_12): Same matching approach but estimates a DiD effect on the matched panel. 

LASSO + CEM (code_13): Uses adaptive LASSO to select matching variables, then applies CEM on those variables. 

Entropy Balancing (code_14): Reweights the control group to match the treated group's covariate distribution without dropping observations. Standard errors are bootstrapped so weight-estimation uncertainty is accounted for. 

Doubly Robust (code_15): Combines propensity and outcome models across four specifications; keeps the best-balanced result. 

Comparison Plot (code_16): Plots all matching estimates against the RCT benchmark. Also writes a combined output to Results/ for cross-pipeline comparison. 

 

5. Difference-in-Differences (Diff-in-Diff/Code/, Diff-in-Diff/Output/) 

Estimates the treatment effect by comparing outcome changes over time between treated and control firms. 

Baseline DiD (Diff_code_01): Core two-period DiD on business practices. 

Employees & Event Study (Diff_code_02): Extends the analysis to number of employees, tests parallel trends, and adds an event-study specification showing year-by-year dynamic effects. 

Fully Interactive DiD (Diff_code_03): Adds full covariate interactions to allow the treatment effect to vary with firm characteristics. Continuous covariates are demeaned so the DiD coefficient is interpretable at the sample mean rather than at zero. Run with and without firm fixed effects. 

 

6. Double Machine Learning (DML/Code/, DML/Output/) 

Uses Stata's ddml/pystacked to flexibly estimate nuisance functions and produce treatment effect estimates robust to model misspecification. 

Shared Engine (DML_code_00): Central setup and estimation programs reused by all DML scripts. Handles both an ATE specification (partial model, multi-arm treatment) and an ATET specification (interactive model, binary treatment). Propensity-score diagnostics are only produced for the interactive model since they are not meaningful for the multi-arm partial model. 

Full-Sample Analysis (DML_code_01): Runs both specifications on the full sample. 

Subgroup Analysis (DML_code_02): Repeats both specifications for high-competition, low-competition, and matching-comparable subgroups. 

Output Formatting (DML_code_03): Compiles all DML results and the RCT benchmark into summary CSVs. 

Comparison Plot (DML_code_04): Plots all DML estimates against the RCT benchmark and writes a combined output to Results/. 

 

7. Final Results (Results/) 

Results_combine_all.do handles everything. It first loads .ster estimates from the original pipeline methods (RCT, old Matching, RDD, baseline DiD) and produces a coefplot and esttab tables (.rtf and .tex). It also imports and combines the comparison CSVs written by Matching and DML scripts, de-duplicates the RCT benchmark row that each pipeline adds, and writes a single unified CSV and colour-coded coefficient plot covering all methods across all pipelines. 

Run order: 

Matching_code_16_comparison_plot.do → Results/matching_method_comparison.csv 

DML_code_04_comparison_plot.do → Results/dml_method_comparison.csv 

Results_combine_all.do → Results/treatment_table.rtf/.tex, Results/all_methods_combined.csv, Results/all_methods_combined_plot.png 

Note: Results_combine_all.do also reads Results/treatment_table_original.csv for the combined CSV. This file is not produced automatically — add export delimited "Results/treatment_table_original.csv", replace to the end of the original Formatting_output_table.do and run it once. 

 

8. Documentation (Results/) 

Project report with a summary of the analysis and suggested next steps, plus supporting documents on the original 2018 experiment design. 

 

 

This document was generated by mAI. 

 
