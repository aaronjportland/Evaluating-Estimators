*========================================================================= 
* DML_code_02_subgroup_analysis.do 
* Runs both models across the three subgroups (high comp, low comp, 
* matching subsample) using the same engine as file 01. 
*========================================================================= 
do "/Users/aaronjoseph/Downloads/Capstone/Felipe/DML/Code/DML_code_00_shared.do" 
 
foreach model in partial interactive { 
    use "$out_dml/dml_`model'_processed.dta", clear 
 
    if "`model'" == "partial" { 
        global D treatment_assignment 
        local prefix dml_partial_ 
    } 
    else { 
        global D any_treatment 
        local prefix dml_int_ 
    } 
 
    run_ddml, model(`model') outname(`prefix'highcomp) /// 
        condition("competition_strata == 1") label("High competition subgroup") 
 
    run_ddml, model(`model') outname(`prefix'lowcomp) /// 
        condition("competition_strata == 0") label("Low competition subgroup") 
 
    run_ddml, model(`model') outname(`prefix'match) /// 
        condition("appears_in_RAIS_2016==1 & number_employees_RAIS_2016>0 & number_employees_RAIS_2016<=10 & business_practices_sum_2018<=22 & treated_impact_evaluation_2017!=1") /// 
        label("Matching subsample") 
} 
