*========================================================================= 
* DML_code_01_full_analysis.do 
* Date: 08/07/2026 
* Author: Aaron Joseph 
* 
* Runs BOTH the partial (ATE, multi-arm D) and interactive (ATET, binary D) 
* models on the full sample, using the shared engine. 
* 
* Main steps: 
*   1. Load the shared DML engine (globals + rank_vars_by_importance, 
*     prep_dml, run_ddml, write_results_csv). 
*   2. Run the partial (ATE) model on the full sample. 
*   3. Run the interactive (ATET) model on the full sample. 
*   4. Write partial and interactive results to CSV
*========================================================================= 
 
// Step 1: Load the shared DML engine. 
do "/Users/aaronjoseph/Downloads/Capstone/Felipe/DML/Code/DML_code_00_shared.do" 
 
// Step 2: Run the partial (ATE) model on the full sample. 
prep_dml, model(partial) 
run_ddml, model(partial) outname(dml_partial_full) label("Full sample (ATE)") 
 
// Step 3: Run the interactive (ATET) model on the full sample. 
prep_dml, model(interactive) 
run_ddml, model(interactive) outname(dml_int_full) label("Full sample (ATET)") 

// 4. Write partial and interactive results to CSV immediately after estimation. 
write_results_csv, /// 
    models("dml_partial_full dml_int_full") /// 
    csvfile("$out_dml/output_dml_full_results_table.csv") 

 
 

 
