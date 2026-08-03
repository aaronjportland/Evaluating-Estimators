********************************************************************************
* Date: 27/08/2023
* Author: Gabriela Monteiro Avelino
*
*	Code 04: McCrary test for the RDD estimation
*
*===============================================================================
*	Part 0: Settings
*===============================================================================

* setting the work directory

	cd "/Users/aaronjoseph/Downloads/Capstone/Felipe" 
	
* importing the full SSE population from 2015 to 2018

	use "RDD/Data/output_code_04_full_population_sse_2015_2018.dta", clear
	
*===============================================================================
*	Part 1: Plotting the distribution of employees
*===============================================================================	
		
/*
Criteria for being in the RDD sample: 
1) firm is in SSE 2018 and answered WBG survey in 2018;
2) firm appears in RAIS 2016 and is active;
3) firm has between 8 and 13 employees;
4) not having scored 100% (23);
5) not having been treated in the 2017 experiment.
*/	
	
* for the McCrary test, I will drop the 3) criterium and keep firms with a number
* 		of employees between 1 and 50.

	keep if	merge_survey_WBG_2018 == 3 & /// 
			appears_in_RAIS_2016 == 1 & /// 
			number_employees_RAIS_2016 > 0 & ///
			number_employees_RAIS_2016 <= 50 & /// 
			business_practices_sum_2018 <= 22 & ///
			treated_impact_evaluation_2017 != 1
	
	tabulate number_employees_RAIS_2016
	
	histogram number_employees_RAIS_2016, freq bin(50)

*===============================================================================
*	Part 2: Performing the McCrary test
*===============================================================================		

	rddensity number_employees_RAIS_2016, c(11)
