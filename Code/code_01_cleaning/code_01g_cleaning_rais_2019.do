********************************************************************************
* Date: 15/08/2025
* Author: Felipe Oliveira
*
*		Code 01g: cleaning RAIS data
*		
*
*===============================================================================
*	Part 0: Settings
*===============================================================================

    clear all
	
* setting the work directory
	cd "/Users/aaronjoseph/Downloads/Capstone/Felipe"

foreach year of numlist 2015 2017 2018 2019 {
	use "Experiment/Data/rais_estab-`year'.dta", clear
		
	keep cnpj_cei year employee_dez
	
	rename			cnpj_cei						firm_id
	rename			employee_dez				number_employees_RAIS_`year'
	
	destring firm_id, replace
	
	duplicates drop firm_id, force
	
	save "Experiment/Output/output_code_01g_rais_`year'.dta", replace
}
