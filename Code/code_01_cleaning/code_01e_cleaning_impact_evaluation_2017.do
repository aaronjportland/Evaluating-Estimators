********************************************************************************
* Date: 15/06/2023
* Author: Gabriela Monteiro Avelino
*
*	Code 01e: Identifying firms that were treated in the 2017 impact evaluation
*
*===============================================================================
*	Part 0: Settings
*===============================================================================

* setting the work directory

	cd "/Users/aaronjoseph/Downloads/Capstone/Felipe"

* importing the data from the 2017 impact evaluation

	use "Experiment/Data/SSE_2017_followup_monitoring.dta", clear

*===============================================================================
*	Part 1: Cleaning
*===============================================================================	

* eliminating unnecessary variables

	drop ID InícioSurveyCTO TérminoSurveycTO Duração Agente InícioSSE ///
		TérminoSSE MotivoNéctar DataAtendimentoNéctar SurveyCTO ///
		bairro municipio CEP regional_rio random_number order franquia ///
		franquia_feed franquia_bench rank arm1_obs SSE_2018 SSE_2018_exported ///
		treat_original treat_arms treat Amostra_SSE2017 merge_sample2017

* renaming variables
	
	rename			CNPJ			firm_id

*===============================================================================
*	Part 2: Keeping only firms that were treated in the 2017 impact evaluation
*===============================================================================	
	
	keep if 		treat_2017 == 1
		
* renaming variable

	rename			treat_2017		treated_impact_evaluation_2017
	
	label variable 	treated_impact_evaluation_2017 "Firm treated in the 2017 impact evaluation"
	
*===============================================================================
*	Part 3: Saving the product of this code
*===============================================================================		

save "Experiment/Output/output_code_01e_impact_evaluation_2017.dta", replace
