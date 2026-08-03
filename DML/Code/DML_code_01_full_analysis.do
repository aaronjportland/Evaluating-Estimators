
*========================================================================= 
* DML_code_01_full_analysis.do 
* Runs BOTH the partial (ATE, multi-arm D) and interactive (ATET, binary 
* D) models on the full sample, using the shared engine. 
*========================================================================= 

do "/Users/aaronjoseph/Downloads/Capstone/Felipe/DML/Code/DML_code_00_shared.do" 
 
prep_dml, model(partial) 
run_ddml, model(partial) outname(dml_partial_full) label("Full sample (ATE)") 
 
prep_dml, model(interactive) 
run_ddml, model(interactive) outname(dml_int_full) label("Full sample (ATET)") 

 

 