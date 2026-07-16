 

*========================================================================= 

* Date: 07/07/2023 

* Author: Gabriela Monteiro Avelino 

* Code 05b: Estimating treatment effect (fuzzy RD) 

*========================================================================= 

* Part 0: Settings 

*========================================================================= 

* setting the work directory 

cd "/Users/aaronjoseph/Downloads/Capstone/Felipe" 

* importing the RDD sample 

use "RDD/Output/RDD_output_code_01b_fuzzy_RD_sample.dta", clear 

*========================================================================= 

* Part 1: Estimating treatment effect 

*========================================================================= 

* creating the interaction term 

 

g interaction = number_employees_recentered*instrument_fuzzy_RD 

  

/* renaming the endogenous variable to avoid Stata's 32-character name limit 

   (ivregress with the "first" option generates internal names by appending 

   a prefix/suffix to the endogenous variable's name, which overflows the 

   limit when the original name "treatment_assignment_dummy" is used) */ 

  

rename treatment_assignment_dummy treat_assign_dum 

  
ivregress 2sls business_practices_sum_2019 number_employees_recentered interaction /// 
    (treat_assign_dum = instrument_fuzzy_RD number_employees_recentered /// 
    interaction), first 

  

* restoring the original variable name 

  

rename treat_assign_dum treatment_assignment_dummy 
