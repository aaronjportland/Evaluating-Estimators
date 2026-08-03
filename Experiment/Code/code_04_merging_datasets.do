********************************************************************************
* Date: 10/06/2023
* Author: Gabriela Monteiro Avelino
*
*	Code 04: Merging databases to create the population of firms for sampling
*
*===============================================================================
*	Part 0: Settings
*===============================================================================

* setting the work directory

	cd "/Users/aaronjoseph/Downloads/Capstone/Felipe"	
	
* importing Sebrae's database of people interviewed in the 2018 edition of the 
* 		SSE program (output of code 01a)

	use "Experiment/Output/output_code_01a_sse_2018.dta", clear

*===============================================================================
*	Part 1: Combining SSE 2018 and WBG Survey 2018
*===============================================================================	

* merging with WBG survey from 2018 (product of code 01b)

	merge 1:m firm_id ///
	using "Experiment/Output/output_code_01b_WBG_survey_2018.dta", ///
	gen (merge_survey_WBG_2018)
	
	label define 	merge_survey_WBG_2018 ///
					1 "Firms in SSE 2018 who did not answer WBG Survey 2018" ///
					2 "Firms who answered WBG Survey 2018 but are not in SSE 2018" ///
					3 "Firms who are in SSE 2018 and answered WBG Survey 2018"
	
	label values merge_survey_WBG_2018 merge_survey_WBG_2018

* most firms that answered WBG survey but are not in SSE 2018 are MEIs
*	(individual entrepreneurs)
	
*-------------------------------------------------------------------------------
*** handling duplicates --------------------------------------------------------
*-------------------------------------------------------------------------------
	
/*
Entries with "survey_round_2018" == 0 correspond to firms who only answered the 
WBG survey once. Entries with "survey_round_2018" == 1 correspond to the first
answer of a firm who answered the survey more than once. "survey_round_2018" == 2 
is the second answer, and so on.
*/

* duplicates in SSE 2018: "repeated_firm_sse_2018" == 1
* duplicates in survey 2018: "survey_round_2018" >= 1
	
* From duplicates kept in SSE 2018, keep survey observations from the same date
	
	* creating dates for the survey and interview
	
	g interview_start_date_2018 = dofc(interview_starttime_2018)
	g survey_start_date_2018 = dofc(survey_starttime_2018)	
	
	* identifying cases when interview and survey started in the same day
	
	g same_survey_interview_date_2018 = 1 if ///
			interview_start_date_2018 == survey_start_date_2018
	
	* identifying number of matching survey and interview dates for each repeated firm
	
	bysort firm_id: egen n_matches_survey_interview_dates = ///
					sum(same_survey_interview_date_2018) if ///
					merge_survey_WBG_2018 == 3 & repeated_firm_sse_2018 == 1 ///
					& survey_round_2018 > 0
	
	* eliminating entries when there is another entry that matches survey and interview dates
	
	drop if same_survey_interview_date_2018 ==. & ///
			n_matches_survey_interview_dates == 1 & ///
			merge_survey_WBG_2018 == 3 & ///
			repeated_firm_sse_2018 == 1 & ///
			survey_round_2018 > 0
	
	* when dates do not coincide, checking how far apart they are
	
	g diff_survey_interview_date_2018 = ///
		(interview_start_date_2018 - survey_start_date_2018)^2 if ///
		n_matches_survey_interview_dates == 0
	
	* some interviewers ran the survey on paper to enter it in the system later
	* (so 4 days difference should be normal). dropping surveys too far apart 
	* from SSE interview
	
	drop if diff_survey_interview_date_2018 > 16 & ///
			n_matches_survey_interview_dates == 0 & ///
			merge_survey_WBG_2018 == 3 & repeated_firm_sse_2018 == 1 ///
			& survey_round_2018 > 0
	
	* firms that were only duplicated in survey but not on SSE 2018
	* keep the most recent response
	
	bysort firm_id (survey_round_2018): drop if survey_round_2018 >= 1 & ///
												survey_round_2018 < _N & ///
												merge_survey_WBG_2018 == 3 & ///
												repeated_firm_sse_2018 != 1
	
	* checking whether all duplicates were eliminated
	
	bysort firm_id: g n_rep = cond(_N==1,0,_n)
	
	tab n_rep
	
	/*
	There are still 379 firm IDs repeated. Previous code did not exclude them. 
	Must understand why. These are firms repeated in the survey who do not appear
	on SSE 2018 database. I drop them, keeping the most recent answer to the survey.
	*/
	
	bysort firm_id (survey_round_2018): drop if survey_round_2018 >= 1 & ///
												survey_round_2018 < _N & ///
												repeated_firm_sse_2018 != 1 & ///
												merge_survey_WBG_2018 == 2
	
	* checking whether all duplicates were eliminated
	
	tab n_rep
	
	* dropping unnecessary variables 
	
	drop interview_start_date_2018- n_rep
	
	* keeping only firms that were in SSE 2018
	
	keep if merge_survey_WBG_2018 == 1 | merge_survey_WBG_2018 == 3
	
*===============================================================================
*	Part 2: Identifying firms' size
*===============================================================================
	
	* don't know where this information about size came from. probably from the
	* Brazilian Revenue Services. must check.
		
	merge 1:1 firm_id using "Experiment/Data/sse_2018_type.dta", gen(merge_revenue_services)
	
	* dropping unused variables
	
	drop CNAE
	
	* renaming variables
	
	rename porte firm_size_BR_revenue_services
	
	* keeping only observations from SSE 2018
	
	drop if merge_revenue_services == 2
	
*===============================================================================
*	Part 3: Merging with RAIS 2016
*===============================================================================	

	merge 1:1 firm_id using "Experiment/Data/rais_2016_tag.dta", gen(merge_rais_2016)
	
	* keeping only firms in SSE 2018
	
	drop if merge_rais_2016 == 2
	
	* dropping unused variables
	
	drop cnpj_cei n_repetidas
	
	* renaming variables
	
	rename 			qtd_vinculos_31_12_2016 		number_employees_RAIS_2016
	label variable 	number_employees_RAIS_2016		"Number of active contracts in 31/12/2016"
	
	rename			tag_rais						appears_in_RAIS_2016
	label variable	appears_in_RAIS_2016			"Dummy indicating whether firm appears on RAIS database of contracts in 2016"
	
	* don't know what the other "tag" variable indicates.

*===============================================================================
*	Part 4: Merging with previous SSE editions
*===============================================================================

* merging with SSE 2015

	merge 1:1 firm_id using "Experiment/Output/output_code_01c_sse_2015.dta", ///
							gen(merge_sse_18_15)
	
* merging with SSE 2016

	merge 1:1 firm_id using "Experiment/Output/output_code_01d_sse_2016.dta", ///
							gen(merge_sse_18_15_16)
							
* merging with SSE 2017

	merge 1:1 firm_id using "Experiment/Output/output_code_01f_sse_2017.dta", ///
							gen(merge_sse_18_15_16_17)
							
* identifying the results from the merge

	generate byte 		merge_SSE_editions =.
	label variable		merge_SSE_editions	"Firm participation in multiple editions of the SSE program"

	replace	merge_SSE_editions = 1 if (merge_sse_18_15 == 2 & ///
										merge_sse_18_15_16 == 1 & ///
										merge_sse_18_15_16_17 == 1 & ///
										merge_SSE_editions ==.)
	
	replace	merge_SSE_editions = 2 if (merge_sse_18_15_16 == 2 & ///
										merge_sse_18_15_16_17 == 1 & ///
										merge_SSE_editions ==.)
	
	replace	merge_SSE_editions = 3 if (merge_sse_18_15_16_17 == 2 & ///
										merge_SSE_editions ==.)
										
	replace	merge_SSE_editions = 4 if (merge_sse_18_15 == 1 & ///
										merge_sse_18_15_16 == 1 & ///
										merge_sse_18_15_16_17 == 1 & ///
										merge_SSE_editions ==.)	
	
	replace	merge_SSE_editions = 5 if (merge_sse_18_15 == 2 & ///
										merge_sse_18_15_16 == 3 & ///
										merge_sse_18_15_16_17 == 1 & ///
										merge_SSE_editions ==.)
										
	replace	merge_SSE_editions = 6 if (merge_sse_18_15 == 2 & ///
										merge_sse_18_15_16 == 1 & ///
										merge_sse_18_15_16_17 == 3 & ///
										merge_SSE_editions ==.)									
	
	replace	merge_SSE_editions = 7 if (merge_sse_18_15 == 3 & ///
										merge_sse_18_15_16 == 1 & ///
										merge_sse_18_15_16_17 == 1 & ///
										merge_SSE_editions ==.)	
	
	replace	merge_SSE_editions = 8 if (merge_sse_18_15_16 == 2 & ///
										merge_sse_18_15_16_17 == 3 & ///
										merge_SSE_editions ==.)	
										
	replace	merge_SSE_editions = 9 if (merge_sse_18_15 == 1 & ///
										merge_sse_18_15_16 == 3 & ///
										merge_sse_18_15_16_17 == 1 & ///
										merge_SSE_editions ==.)										
	
	replace	merge_SSE_editions = 10 if (merge_sse_18_15 == 1 & ///
										merge_sse_18_15_16 == 1 & ///
										merge_sse_18_15_16_17 == 3 & ///
										merge_SSE_editions ==.)	
										
	replace	merge_SSE_editions = 11 if (merge_sse_18_15 == 2 & ///
										merge_sse_18_15_16 == 3 & ///
										merge_sse_18_15_16_17 == 3 & ///
										merge_SSE_editions ==.)			
										
	replace	merge_SSE_editions = 12 if (merge_sse_18_15 == 3 & ///
										merge_sse_18_15_16 == 3 & ///
										merge_sse_18_15_16_17 == 1 & ///
										merge_SSE_editions ==.)	
										
	replace	merge_SSE_editions = 13 if (merge_sse_18_15 == 3 & ///
										merge_sse_18_15_16 == 1 & ///
										merge_sse_18_15_16_17 == 3 & ///
										merge_SSE_editions ==.)	
										
	replace	merge_SSE_editions = 14 if (merge_sse_18_15 == 1 & ///
										merge_sse_18_15_16 == 3 & ///
										merge_sse_18_15_16_17 == 3 & ///
										merge_SSE_editions ==.)	
	
	replace	merge_SSE_editions = 15 if (merge_sse_18_15 == 3 & ///
										merge_sse_18_15_16 == 3 & ///
										merge_sse_18_15_16_17 == 3 & ///
										merge_SSE_editions ==.)	
	
	label define	merge_SSE_editions ///
					1 "Firm interviewed only in 2015" ///
					2 "Firm interviewed only in 2016" ///
					3 "Firm interviewed only in 2017" ///
					4 "Firm interviewed only in 2018" ///
					5 "Firm interviewed in 2015 and 2016, but not in 2017 and 2018" ///
					6 "Firm interviewed in 2015 and 2017, but not in 2016 and 2018" ///
					7 "Firm interviewed in 2015 and 2018, but not in 2016 and 2017" ///
					8 "Firm interviewed in 2016 and 2017, but not in 2015 and 2018" ///
					9 "Firm interviewed in 2016 and 2018, but not in 2015 and 2017" ///
					10 "Firm interviewed in 2017 and 2018, but not in 2015 and 2016" ///
					11 "Firm interviewed in 2015, 2016 and 2017, but not in 2018" ///
					12 "Firm interviewed in 2015, 2016 and 2018, but not in 2017" ///
					13 "Firm interviewed in 2015, 2017 and 2018, but not in 2016" ///
					14 "Firm interviewed in 2016, 2017 and 2018, but not in 2015" ///
					15 "Firm interviewed in 2015, 2016, 2017 and 2018"
				
	label values	merge_SSE_editions merge_SSE_editions

* dropping useless variables

	drop merge_sse_18_15 merge_sse_18_15_16 merge_sse_18_15_16_17
	
*===============================================================================
*	Part 5: Merging with database of Sebrae services' take-up from 2015 to 2018
*===============================================================================
	
	merge 1:1 firm_id ///
	using "Experiment/Output/output_code_02c_sebrae_services_takeup.dta", ///
	gen(merge_sebrae_services_2015_2018)
	
	* dropping firms that used Sebrae's services but were not in SSE sometime 
	*	between 2015 and 2018
	
	drop if merge_sebrae_services_2015_2018 == 2
	
*===============================================================================
*	Part 6: Merging with database of strategic sectors prioritized by Sebrae
*===============================================================================	
		
/*
Here we use the database which contains the business activity codes (CNAEs) that 
are part of Sebrae's strategic sectors (must confirm that this is in fact the 
content of the database).
*/

* generating the identifier to merge with

	generate 	CNAE =.
	replace		CNAE = business_activity_code_2015 if merge_SSE_editions == 1
	replace		CNAE = business_activity_code_2016 if merge_SSE_editions == 2
	replace		CNAE = business_activity_code_2017 if merge_SSE_editions == 3
	replace		CNAE = business_activity_code_2018 if merge_SSE_editions == 4
	replace		CNAE = business_activity_code_2016 if merge_SSE_editions == 5
	replace		CNAE = business_activity_code_2017 if merge_SSE_editions == 6
	replace		CNAE = business_activity_code_2018 if merge_SSE_editions == 7
	replace		CNAE = business_activity_code_2017 if merge_SSE_editions == 8
	replace		CNAE = business_activity_code_2018 if merge_SSE_editions == 9
	replace		CNAE = business_activity_code_2018 if merge_SSE_editions == 10
	replace		CNAE = business_activity_code_2017 if merge_SSE_editions == 11
	replace		CNAE = business_activity_code_2018 if merge_SSE_editions == 12
	replace		CNAE = business_activity_code_2018 if merge_SSE_editions == 13
	replace		CNAE = business_activity_code_2018 if merge_SSE_editions == 14
	replace		CNAE = business_activity_code_2018 if merge_SSE_editions == 15

	label variable	CNAE "CNAE of the firm, as reported in the latest SSE interview"

* merging with Sebrae's database of strategic sectors

	merge m:1 CNAE using "Experiment/Data/cnae_sebrae", gen(sebrae_priority)

* dropping business activity codes that are considered strategic by Sebrae but
*		were not used by any firm interviewed in the SSE from 2015 to 2018

	drop if 		sebrae_priority == 2 

* identifying the results from the merge

	label variable 	sebrae_priority				"Is the business activity part of the strategic sectors prioritized by Sebrae?"

	recode 			sebrae_priority 			(3=1) (1=0)

	label define 	sebrae_priority ///
					0 "No" ///
					1 "Yes"
					
	label values 	sebrae_priority sebrae_priority
	
* renaming the new columns brought by the merge

	encode 			setor_estrategico_sebrae, 			g(sebrae_strategic_business_sector)
	drop 			setor_estrategico_sebrae
	label variable	sebrae_strategic_business_sector	"Sebrae's strategic sector to which the CNAE from last SSE interview corresponds"

	rename			cnae_descricao						business_activity_code_descript
	label variable	business_activity_code_descript		"Description of the CNAE reported in the last SSE interview"

	rename			cnae_secao							business_activity_code_sector
	label variable	business_activity_code_sector		"Section to which the CNAE reported in the last SSE interview belongs to"

	rename			cnae_divisao						business_activity_code_division
	label variable	business_activity_code_division 	"Division to which the CNAE reported in the last SSE interview belongs to"

	rename			cnae_classe							business_activity_code_class
	label variable	business_activity_code_class		"Class to which the CNAE reported in the last SSE interview belongs to"

	rename			cnae_grupo							business_activity_code_group
	label variable	business_activity_code_group		"Group to which the CNAE reported in the last SSE interview belongs to"		
	
* sectors not prioritized by Sebrae will be classified as "other"

	replace	sebrae_strategic_business_sector = 6 if ///
			sebrae_strategic_business_sector ==.	

* adding the sector variable

/* It is the same as Sebrae's definition of business sectors, except when Sebrae's
sector == other, in which case it is IBGE's definition. This variable was created 
in lines 99-107 of code 02b (saved in "Experiment/Data/business_code_sector.dta").
*/
	
	merge m:1 CNAE using "Experiment/Data/business_code_sector.dta", ///
							gen(merge_busin_sector_IBGE_Sebrae)

	* keeping only sectors that appear in SSE 2015-2018
	
	drop if merge_busin_sector_IBGE_Sebrae == 2
	
	* defining results of the merge
	
	label define merge_busin_sector_IBGE_Sebrae ///
	1 "Business activity code unmatched with Sebrae's + IBGE sector variable" ///
	3 "Business activity code matched with Sebrae's + IBGE sector variable"
	
	label values merge_busin_sector_IBGE_Sebrae merge_busin_sector_IBGE_Sebrae
	
	* renaming variable
	
	rename			CNAE					business_activity_code
	
*===============================================================================
*	Part 7: Adding competition variable for each region/sector combination
*===============================================================================
			
* generating firm zipcode based on the latest SSE interview

	generate 	double	zipcode =.
	replace		zipcode = firm_zipcode_2015 if merge_SSE_editions == 1
	replace		zipcode = firm_zipcode_2016 if merge_SSE_editions == 2
	replace		zipcode = firm_zipcode_2017 if merge_SSE_editions == 3
	replace		zipcode = firm_zipcode_2018 if merge_SSE_editions == 4
	replace		zipcode = firm_zipcode_2016 if merge_SSE_editions == 5
	replace		zipcode = firm_zipcode_2017 if merge_SSE_editions == 6
	replace		zipcode = firm_zipcode_2018 if merge_SSE_editions == 7
	replace		zipcode = firm_zipcode_2017 if merge_SSE_editions == 8
	replace		zipcode = firm_zipcode_2018 if merge_SSE_editions == 9
	replace		zipcode = firm_zipcode_2018 if merge_SSE_editions == 10
	replace		zipcode = firm_zipcode_2017 if merge_SSE_editions == 11
	replace		zipcode = firm_zipcode_2018 if merge_SSE_editions == 12
	replace		zipcode = firm_zipcode_2018 if merge_SSE_editions == 13
	replace		zipcode = firm_zipcode_2018 if merge_SSE_editions == 14
	replace		zipcode = firm_zipcode_2018 if merge_SSE_editions == 15
	
	label variable	zipcode "Firm's zipcode, as reported in the latest SSE interview"
	
* merging with product of code 02b
	
	merge m:1 zipcode business_activity_code  ///
	using "Experiment/Output/output_code_02b_competition_level.dta" , ///
	gen(merge_competition_density)
	
* keeping only information relevant to the firms in SSE 2015-2018

	drop if merge_competition_density == 2
	
* creating broad zipcode for firms that did not match

	replace broad_zipcode = floor(zipcode/1000) if broad_zipcode == .
	format	broad_zipcode	%9.0g
	
* creating competition level variable for missing cases

	bysort broad_zipcode: gen competition_replace = _N

	replace competition_density_full_zipco = competition_replace ///
			if competition_density_full_zipco ==. & zipcode !=.
			
	drop competition_replace

* creating competition intervals

	g competition_intervals = 1 if competition_density_full_zipco == 1

	replace competition_intervals = 2 if competition_density_full_zipco == 2

	replace competition_intervals = 3 if ///
			competition_density_full_zipco >= 3 & competition_density_full_zipco <= 5
			
	replace competition_intervals = 4 if ///
			competition_density_full_zipco >= 6 & competition_density_full_zipco <= 15
			
	replace competition_intervals = 5 if ///
			competition_density_full_zipco >= 16 & competition_density_full_zipco <= 25
			
	replace competition_intervals = 6 if ///
			competition_density_full_zipco >= 26 & competition_density_full_zipco <= 50
			
	replace competition_intervals = 7 if ///
			competition_density_full_zipco >= 51 & competition_density_full_zipco <= 100
			
	replace competition_intervals = 8 if ///
			competition_density_full_zipco >= 101 & competition_density_full_zipco <= 250
			
	replace competition_intervals = 9 if ///
			competition_density_full_zipco >= 251 & competition_density_full_zipco <= 500
			
	replace competition_intervals = 10 if ///
			competition_density_full_zipco >= 501 & competition_density_full_zipco <= 5000

			
	label define competition_intervals ///
			1 "1 empresa" ///
			2 "2 empresas" ///
			3 "De 3 a 5 empresas" ///
			4 "De 6 a 15 empresas" ///
			5 "De 16 a 25 empresas" ///
			6 "De 26 a 50 empresas" ///
			7 "De 51 a 100 empresas" ///
			8 "De 101 a 250 empresas" ///
			9 "De 251 a 500 empresas" ///
			10 "Mais de 500 empresas"
			
	label values competition_intervals competition_intervals

*===============================================================================
*	Part 8: Merging with outcome (SSE 2019)
*===============================================================================
	
	merge 1:1 firm_id using "Experiment/Output/output_code_03a_sse_2019.dta", ///
							gen(attrition_outcome_sse_19)
	
	* keeping only the outcomes from firms in the population of interest
	
	drop if attrition_outcome_sse_19 == 2
	
	* labelling the result from the merge
	
	recode attrition_outcome_sse_19 (3=0)
	
	label define	attrition_outcome_sse_19 ///
					1 "Firm not found in SSE 2019" ///
					0 "Firm found in SSE 2019"
					
	label values attrition_outcome_sse_19 attrition_outcome_sse_19
					
*===============================================================================
*	Part 9: Saving final database
*===============================================================================

* eliminating variables that will not be used

	drop instanceID formdef_version KEY GPSLatitude GPSLongitude GPSAltitude ///
			GPSAccuracy ID_2015 ID_2016 bairro_rio Deficiência*

	save "Experiment/Output/output_code_04_full_population_sse_2015_2018.dta", replace
