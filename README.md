# SSE Impact Evaluation Project — README 
 
## Overview 
 
This project tests whether non-experimental methods can recover the known treatment effect from a real RCT. The SSE program's impact on firms' business practices was measured experimentally — the result is a null effect. The project then applies RDD, Matching, DiD, and DML to the same data to see how close each gets to that benchmark. 
 
--- 
 
## 1. Data Preparation (`Experiment/Code/`) 
 
Raw data from multiple SSE survey waves, the WBG survey, and RAIS administrative records are cleaned individually, key composite variables (business practices score, competition index, past service take-up) are constructed, and everything is merged into one master dataset used by all downstream analyses. 
 
--- 
 
## 2. Experimental Analysis — RCT (`Experiment/Code/`, `Experiment/Output/`) 
 
Defines the experimental sample, checks baseline balance and differential attrition, and estimates the ITT effect. The stored result (`experiment_itt.ster`) is the benchmark every other method is compared against. 
 
--- 
 
## 3. Regression Discontinuity Design (`RDD/Code/`, `RDD/Output/`) 
 
Builds Sharp and Fuzzy RDD samples around the program eligibility cutoff, validates the design (covariate smoothness, placebo cutoffs, McCrary density test), and estimates the local treatment effect across multiple bandwidths. 
 
--- 
 
## 4. Matching Analysis (`Matching/Code/`, `Matching/Output/`) 
 
Constructs a non-experimental control group from RAIS data and estimates the treatment effect using seven methods, each following the same structure: load sample, check balance, apply method, estimate effect, record result. 
 
| Script | Method | Description | 
|---|---|---| 
| Setup | Session config | One-time session configuration — packages, shared globals, file paths. | 
| `code_09` | Diff-in-means | Unadjusted treated vs. control comparison, used as a naive baseline. | 
| `code_10` | Propensity Score Matching | Matches on estimated treatment probability across eight specifications; keeps the best-balanced result. | 
| `code_11` | CEM | Matches firms on key characteristics using coarsened exact matching, then estimates a cross-sectional treatment effect. | 
| `code_12` | CEM + DiD | Same matching approach but estimates a DiD effect on the matched panel. | 
| `code_13` | LASSO + CEM | Uses adaptive LASSO to select matching variables, then applies CEM on those variables. | 
| `code_14` | Entropy Balancing | Reweights the control group to match the treated group's covariate distribution without dropping observations. Standard errors are bootstrapped so weight-estimation uncertainty is accounted for. | 
| `code_15` | Doubly Robust | Combines propensity and outcome models across four specifications; keeps the best-balanced result. | 
| `code_16` | Comparison Plot | Plots all matching estimates against the RCT benchmark. Also writes a combined output to `Results/` for cross-pipeline comparison. | 
 
--- 
 
## 5. Difference-in-Differences (`Diff-in-Diff/Code/`, `Diff-in-Diff/Output/`) 
 
Estimates the treatment effect by comparing outcome changes over time between treated and control firms. 
 
- **`Diff_code_01` — Baseline DiD:** Core two-period DiD on business practices. 
- **`Diff_code_02` — Employees & Event Study:** Extends the analysis to number of employees, tests parallel trends, and adds an event-study specification showing year-by-year dynamic effects. 
- **`Diff_code_03` — Fully Interactive DiD:** Adds full covariate interactions to allow the treatment effect to vary with firm characteristics. Continuous covariates are demeaned so the DiD coefficient is interpretable at the sample mean rather than at zero. Run with and without firm fixed effects. 
 
--- 
 
## 6. Double Machine Learning (`DML/Code/`, `DML/Output/`) 
 
Uses Stata's `ddml`/`pystacked` to flexibly estimate nuisance functions and produce treatment effect estimates robust to model misspecification. 
 
- **`DML_code_00` — Shared Engine:** Central setup and estimation programs reused by all DML scripts. Handles both an ATE specification (partial model, multi-arm treatment) and an ATET specification (interactive model, binary treatment). Propensity-score diagnostics are only produced for the interactive model since they are not meaningful for the multi-arm partial model. 
- **`DML_code_01` — Full-Sample Analysis:** Runs both specifications on the full sample. 
- **`DML_code_02` — Subgroup Analysis:** Repeats both specifications for high-competition, low-competition, and matching-comparable subgroups. 
- **`DML_code_03` — Output Formatting:** Compiles all DML results and the RCT benchmark into summary CSVs. 
- **`DML_code_04` — Comparison Plot:** Plots all DML estimates against the RCT benchmark and writes a combined output to `Results/`. 
 
--- 
 
## 7. Final Results (`Results/`) 
 
`Results_combine_all.do` handles everything. It first loads `.ster` estimates from the original pipeline methods (RCT, old Matching, RDD, baseline DiD) and produces a coefplot and esttab tables (`.rtf` and `.tex`). It also imports and combines the comparison CSVs written by Matching and DML scripts, de-duplicates the RCT benchmark row that each pipeline adds, and writes a single unified CSV and colour-coded coefficient plot covering all methods across all pipelines. 
 
**Run order:** 
 
1. `Matching_code_16_comparison_plot.do` → `Results/matching_method_comparison.csv` 
2. `DML_code_04_comparison_plot.do` → `Results/dml_method_comparison.csv` 
3. `Results_combine_all.do` → `Results/treatment_table.rtf/.tex`, `Results/all_methods_combined.csv`, `Results/all_methods_combined_plot.png` 
 
> **Note:** `Results_combine_all.do` also reads `Results/treatment_table_original.csv` for the combined CSV. This file is not produced automatically — add `export delimited "Results/treatment_table_original.csv", replace` to the end of the original `Formatting_output_table.do` and run it once. 
 
--- 
 
## 8. Documentation (`Results/`) 
 
Project report with a summary of the analysis and suggested next steps.
