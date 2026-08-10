*========================================================================= 
* DML_code_02_subgroup_analysis.do 
* Date: 08/07/2026 
* Author: Aaron Joseph 
* 
* Runs both models across the three subgroups (high comp, low comp, 
* matching subsample) using the same engine as file 01. 
* 
* Main steps: 
*   1. Load the shared DML engine. 
*   2. For each model type, load its processed dataset and set the 
*     treatment global. 
*   3. Run the high-competition subgroup. 
*   4. Run the low-competition subgroup. 
*   5. Run the matching subsample. 
*========================================================================= 
 
// Step 1: Load the shared DML engine. 
do "/Users/aaronjoseph/Downloads/Capstone/Felipe/DML/Code/DML_code_00_shared.do" 
 
foreach model in partial interactive { 
 
    // Step 2: Load the processed dataset and set the treatment global. 
    use "$out_dml/dml_`model'_processed.dta", clear 
    if "`model'" == "partial" { 
        global D treatment_assignment 
        local prefix dml_partial_ 
    } 
    else { 
        global D any_treatment 
        local prefix dml_int_ 
    } 
 
    // Step 3: Run the high-competition subgroup. 
    run_ddml, model(`model') outname(`prefix'highcomp) /// 
        condition("competition_strata == 1") label("High competition subgroup") 
 
    // Step 4: Run the low-competition subgroup. 
    run_ddml, model(`model') outname(`prefix'lowcomp) /// 
        condition("competition_strata == 0") label("Low competition subgroup") 
 
    // Step 5: Run the matching subsample. 
    run_ddml, model(`model') outname(`prefix'match) /// 
        condition("appears_in_RAIS_2016==1 & number_employees_RAIS_2016>0 & number_employees_RAIS_2016<=10 & business_practices_sum_2018<=22 & treated_impact_evaluation_2017!=1") /// 
        label("Matching subsample") 
 
} 

 

 
