********************************************************************************
* Date: 12/06/2023
* Author: Gabriela Monteiro Avelino
*
*	Code 05: Sampling firms for the 2018 experiment (one-pager)
*
*===============================================================================
*	Part 0: Settings
*===============================================================================

* setting the work directory

	cd "/Users/aaronjoseph/Downloads/Capstone/Felipe"	
	
* importing the full population of firms in SSE 2015-2018

	use "Experiment/Output/output_code_04_full_population_sse_2015_2018.dta", clear

*===============================================================================
*	Part 1: Creating sampling universe
*===============================================================================	
	
	g 				sampling_universe = .
	label variable	sampling_universe "Indicator of firm's participation in the 2018 experiment (information sheet)"

/*
Criteria for being in the sample: 
1) firm is in SSE 2018 and answered WBG survey in 2018;
2) firm appears in RAIS 2016 and is active;
3) firm has a positive number of employees, but at most 10;
4) drop firms who scored 100% (23);
5) drop firms who were treated in the 2017 experiment.
*/	
	replace			sampling_universe = 1 if ///
						merge_survey_WBG_2018 == 3 & /// 
						appears_in_RAIS_2016 == 1 & /// 
						number_employees_RAIS_2016 > 0 & ///
						number_employees_RAIS_2016 <= 10 & /// 
						business_practices_sum_2018 <= 22 & ///
						treated_impact_evaluation_2017 != 1
	
	recode 			sampling_universe (.=0)

	label define 	sampling_universe ///
						1 "Firms participating in the experiment (experimental sample)" ///
						0 "Other firms in the population of SSE 2015-2018"
					
	label values 	sampling_universe sampling_universe
	
	keep if 		sampling_universe == 1

*===============================================================================
*	Part 2: Creating strata variable
*===============================================================================		

*-------------------------------------------------------------------------------
*** Competition stratification variable ----------------------------------------
*-------------------------------------------------------------------------------
	
	summarize 		competition_density_full_zipco, detail
	
	g 				competition_strata = 0 if competition_density_full_zipco <= r(p50)  
	replace 		competition_strata = 1 if competition_density_full_zipco > r(p50)
	
	label variable 	competition_strata "Indicates the firm faces more competition than the median firm in the sample"
	
*-------------------------------------------------------------------------------
*** Business practices stratification variable ---------------------------------
*-------------------------------------------------------------------------------	
	
	tabulate business_practices_scale_2018
	
	* the first two positions in the scale will be merged
		
	g 		business_practices_strata = 0 if ///
			business_practices_scale_2018 == 1 | business_practices_scale_2018 == 2
			
	replace business_practices_strata = 1 if business_practices_scale_2018 == 3 
	
	replace business_practices_strata = 2 if business_practices_scale_2018 == 4
	
	replace business_practices_strata = 3 if business_practices_scale_2018 == 5
	
*-------------------------------------------------------------------------------
*** Stratification on "entrepreneur by necessity" ------------------------------
*-------------------------------------------------------------------------------	

/* Q14 of 2018 WBG survey asks whether the respondent is an entrepeneur due to 
lack of job options. Q15 of 2018 WBG survey asks whether the respondent would
prefer to be an employee rather than an entrepeneur. Finally, Q16 asks the same
question, but under a scenario where the respondent could earn 50% more if they
were an employee.

We will use those 3 questions to assess whether the respondent is an entrepeneur
by necessity, and use this information to stratify firms.
*/ 	

	g 			entrepren_by_necessity_strata = 1 if ///
					Q14_entrepren_by_necessity_2018 == 2 | ///
					Q15_rather_be_employee_2018 == 1 | ///
					Q16_rather_be_employee_50_2018 == 1

	recode 		entrepren_by_necessity_strata (.=0)

*-------------------------------------------------------------------------------
*** Stratification on previous participation in SSE ----------------------------
*-------------------------------------------------------------------------------
	
	g 			previous_SSE_editions_strata = 0 if merge_SSE_editions == 4
	recode		previous_SSE_editions_strata (.=1)

*-------------------------------------------------------------------------------
*** Creating strata variable ---------------------------------------------------
*-------------------------------------------------------------------------------

	egen randomization_strata = group(competition_strata business_practices_strata ///
						previous_SSE_editions_strata entrepren_by_necessity_strata)
	
*===============================================================================
*	Part 3: Randomization (treatment assignment)
*===============================================================================	

/*
Design: 4000 firms from the sampling universe randomized into 5 treatment
	arms and the control:
	
	1 - Benchmark (FNQ ranking) 		(600)
	2 - Benchmark (Sebrae ranking) 		(600)	
	3 - Competition (FNQ ranking) 		(600)
	4 - Competition (Sebrae ranking) 	(600)
	5 - Coaching						(200)
	C - Status Quo - Control Group		(1400)
*/

* ssc install randtreat

	version 13.0
	sort randomization_strata firm_id
	
	randtreat if sampling_universe == 1, generate(treatment_assignment) ///
											strata(randomization_strata) ///
											unequal(7/20 3/20 3/20 3/20 3/20 1/20) ///
											misfits(wstrata) setseed(312953867)


	label define treatment_assignment ///
						1 	"Benchmark (FNQ Ranking)" ///
						2	"Benchmark (Sebrae Ranking)" ///
						3	"Competition (FNQ Ranking)" ///
						4	"Competition (Sebrae Ranking)" ///
						5 	"Coaching" ///
						0	"Control"
						
	
	label values treatment_assignment treatment_assignment
	
* my replication gives a slightly different randomization than the original
*	experiment(possibly because of misfits). must understand why this happens.

*===============================================================================
*	Part 4: Saving the product of this code
*===============================================================================

	save "Experiment/Output/output_code_05_sample.dta", replace
