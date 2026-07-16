********************************************************************************
* Date: 07/07/2023
* Author: Gabriela Monteiro Avelino
*
*	Code 05a: Estimating treatment effect (sharp RD)
*
*===============================================================================
*	Part 0: Settings
*===============================================================================

* setting the work directory

	cd "/Users/aaronjoseph/Downloads/Capstone/Felipe" 
	
* importing the RDD sample

	use "RDD/Output/RDD_output_code_01a_sharp_RD_sample.dta", clear
	
*===============================================================================
*	Part 1: Estimating treatment effect
*===============================================================================	
	
* running the regression
gen treat_employees = treatment_sharp_RD*number_employees_recentered
	xi:reg business_practices_sum_2019 treat_employees
	
	* Store it in memory
estimates store rdd

* Save it to disk
estimates save "RDD/Output/rdd_sharp.ster", replace

* plotting the treatment effect

	rdplot business_practices_sum_2019 number_employees_RAIS_2016, c(11) p(1) ci(95) shade
