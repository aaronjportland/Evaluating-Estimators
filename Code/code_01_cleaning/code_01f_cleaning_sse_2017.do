********************************************************************************
* Date: 25/05/2023
* Author: Gabriela Monteiro Avelino
*
*		Code 01f: Cleaning Sebrae's database of firms in the 2017 SSE program
*		
*		The database was previously merged with RAIS 2015
*		
*	(must confirm where the information referred to as "bigdata" is coming from)
*
*===============================================================================
*	Part 0: Settings
*===============================================================================

*-------------------------------------------------------------------------------
*** making special characters readable -----------------------------------------
*-------------------------------------------------------------------------------

* setting a temporary work directory for unicode translate

	clear all
	cd "/Users/aaronjoseph/Downloads/Capstone/Felipe/Experiment/Data"
	
* choosing the encoding for translation of the database

	unicode encoding set ISO-8859-1
	
* translating special characters (not changing the data, just variables names and
*		labels)
	
	unicode translate sse_2017.dta, nodata	
	
*-------------------------------------------------------------------------------
*** importing the data and setting work directory for the rest of the code -----
*-------------------------------------------------------------------------------

* setting the work directory

	cd "/Users/aaronjoseph/Downloads/Capstone/Felipe"
	
* importing the database of firms in the 2017 edition of the SSE program

	use "Experiment/Data/sse_2017.dta", clear
	
*===============================================================================
*	Part 1: Renaming and formatting the variables
*===============================================================================

	rename			CNPJ						firm_id
	label variable	firm_id						"Taxpayer number (CNPJ)"

	rename			CEP							firm_zipcode_2017
	
	rename			bairro						firm_neighborhood_2017
	label variable	firm_neighborhood_2017 // dropping unnecessary labels

	* I don't understand the purpose of the variable "bairro_rio".
	
	rename			cidade						firm_city_2017
	label variable	firm_city_2017 // dropping unnecessary labels
	
	rename			regional_sebrae				sebrae_regional_office_2017
	label variable	sebrae_regional_office_2017 // dropping unnecessary labels
	
	rename			CNAE						business_activity_code_2017
	
	rename			data_abertura				date_opening_2017
	label variable	date_opening_2017 // dropping unnecessary labels
	
	rename			data_nascimento				respondent_date_birth_2017
	label variable respondent_date_birth_2017 // dropping unnecessary labels
	
	label variable	years_functioning_2017 // dropping unnecessary labels
	
	rename			age_2017					respondent_age_2017
	
	rename			gender_2017					respondent_gender_2017
	label variable	respondent_gender_2017 // dropping unnecessary labels
	
	rename			owner_2017					respondent_type_2017
	
	rename			atendimento_duracao_2017	interview_duration_2017
	label variable	interview_duration_2017 // dropping unnecessary labels
	
	rename			ramo_atividade				activity_2017 // I don't know where this information/categories are coming from
	
	rename			nat_juridica				type_business_entity_2017
	label variable	type_business_entity // dropping unnecessary labels
	
	rename			matriz						parent_company_2017
	label variable	parent_company_2017 // dropping unnecessary labels
	
	rename			qtd_filiais					number_of_subsidiaries_2017
	label variable	number_of_subsidiaries_2017 // dropping unnecessary labels
	
	rename			RAIS_negativa				zero_employees_2015
	label variable	zero_employees_2015			"Indicates whether the firm had no employees in 2015, according to RAIS"
	
	rename			SIMPLES						simplified_tax_system_2017
	label variable	simplified_tax_system		"Indicates whether the firm opted for simplified taxation (the SIMPLES program)"
	
	rename			employees_RAIS				number_of_employees_2015
	rename			employees_bigdata			number_of_employees_2017
	rename			sales_bigdata				sales_2017
	label variable	sales_2017					"Sales (bigdata firm)"
	
	* creating a variable with interview start time, end time and duration
	
	generate	interview_starttime_2017		= clock(atendimento_inicio_2017, "DMYhms")
	generate	interview_endtime_2017			= clock(atendimento_fim_2017, "DMYhms")
	format 		interview_starttime_2017 interview_endtime_2017		%tc	
	
	* drop the unnecessary variables
	
	drop atendimento_inicio_2017 atendimento_fim_2017

*-------------------------------------------------------------------------------
*** renaming the variables corresponding to the questions in the survey --------
*-------------------------------------------------------------------------------

* The questions will be numbered according to the order in which they were asked
*		in the 2018 SSE edition.

* questions related to financial management ------------------------------------
	
	rename			GF_nivel						financial_management_level_2017
	label variable	financial_management_level_2017	"Level of maturity in financial management, as assessed by Sebrae"
		
	rename 			GF_Q1_2017 						financial_management_Q1_2017
	rename			dum_GF_Q1_2017					dum_financial_management_Q1_2017
	
	rename 			GF_Q2_2017 						financial_management_Q2_2017
	rename			dum_GF_Q2_2017					dum_financial_management_Q2_2017
	label variable	financial_management_Q2_2017	"Existe valor e frequência definidos para a remuneração do(s) dono(s) da empresa?"
	
	rename 			GF_Q9_2017 						financial_management_Q3_2017
	rename			dum_GF_Q9_2017					dum_financial_management_Q3_2017
	
	rename 			GF_Q5_2017 						financial_management_Q4_2017
	rename			dum_GF_Q5_2017					dum_financial_management_Q4_2017
	label variable	financial_management_Q4_2017	"Quantos produtos/serviços precisa vender para cobrir os custos?"
	
	rename			GF_Q10_2017 					financial_management_Q5_2017
	rename			dum_GF_Q10_2017					dum_financial_management_Q5_2017
	
	rename			GF_Q6_2017 						financial_management_Q6_2017
	rename			dum_GF_Q6_2017					dum_financial_management_Q6_2017
		
	rename			GF_Q7_2017 						financial_management_Q7_2017
	rename			dum_GF_Q7_2017					dum_financial_management_Q7_2017
	
	rename			GF_Q8_2017 						financial_management_Q8_2017
	rename			dum_GF_Q8_2017					dum_financial_management_Q8_2017

	rename			GF_Q3_2017 						financial_management_Q9_2017
	rename			dum_GF_Q3_2017					dum_financial_management_Q9_2017
	
	rename			GF_Q4_2017 						financial_management_Q10_2017
	rename			dum_GF_Q4_2017					dum_financial_managemen_Q10_2017 // this variable has a different name (missing "t") due to the limit of 32 characters

* questions related to strategic planning --------------------------------------

	* question 2 in SSE 2018 was not asked in SSE 2017

	rename			PE_nivel						strategic_planning_level_2017
	label variable	strategic_planning_level_2017	"Level of maturity in strategic planning, as assessed by Sebrae"
	
	rename 			PE_Q1_2017						strategic_planning_Q1_2017
	rename			dum_PE_Q1_2017					dum_strategic_planning_Q1_2017
	
	rename 			PE_Q2_2017						strategic_planning_Q3_2017
	rename			dum_PE_Q2_2017					dum_strategic_planning_Q3_2017
	
* questions related to market intelligence -------------------------------------

	rename			MERC_nivel						market_intelligence_level_2017
	label variable	market_intelligence_level_2017	"Level of maturity in market intelligence, as assessed by Sebrae"
	
	rename 			MERC_Q1_2017 					market_intelligence_Q1_2017
	rename			dum_MERC_Q1_2017				dum_market_intelligence_Q1_2017
	
	rename 			MERC_Q4_2017 					market_intelligence_Q2_2017
	rename			dum_MERC_Q4_2017				dum_market_intelligence_Q2_2017
	label variable	market_intelligence_Q2_2017		"Conhece seus concorrentes e a sua forma de atuação?"
	
	rename 			MERC_Q5_2017 					market_intelligence_Q3_2017
	rename			dum_MERC_Q5_2017				dum_market_intelligence_Q3_2017
	
	rename 			MERC_Q2_2017 					market_intelligence_Q4_2017
	rename			dum_MERC_Q2_2017				dum_market_intelligence_Q4_2017
	
	rename 			MERC_Q3_2017 					market_intelligence_Q5_2017
	rename			dum_MERC_Q3_2017				dum_market_intelligence_Q5_2017
	
	rename 			MERC_Q6_2017  					market_intelligence_Q6_2017
	rename			dum_MERC_Q6_2017				dum_market_intelligence_Q6_2017
	
* questions related to marketing -----------------------------------------------
	
	* question 4 in SSE 2018 was not asked in SSE 2017. 
	
	rename			MKT_nivel						marketing_level_2017
	label variable	marketing_level_2017			"Level of maturity in marketing, as assessed by Sebrae"
	
	rename 			MKT_Q2_2017						marketing_Q1_2017
	rename			dum_MKT_Q2_2017					dum_marketing_Q1_2017
	
	rename 			MKT_Q1_2017 					marketing_Q2_2017
	rename			dum_MKT_Q1_2017					dum_marketing_Q2_2017
		
	rename 			MKT_Q6_2017						marketing_Q3_2017
	rename			dum_MKT_Q6_2017					dum_marketing_Q3_2017
	label variable	marketing_Q3_2017				"Ao divulgar, sabe se a empresa está preparada para atender a demanda futura?"
	
	rename 			MKT_Q3_2017			 			marketing_Q5_2017
	rename			dum_MKT_Q3_2017					dum_marketing_Q5_2017
	
	rename 			MKT_Q4_2017	 					marketing_Q6_2017
	rename			dum_MKT_Q4_2017					dum_marketing_Q6_2017
	
	rename 			MKT_Q5_2017	 					marketing_Q7_2017
	rename			dum_MKT_Q5_2017					dum_marketing_Q7_2017
	
	rename 			MKT_Q7_2017	 					marketing_Q8_2017
	rename			dum_MKT_Q7_2017					dum_marketing_Q8_2017
	
	rename			MKT_Q9_2017						marketing_Q9_2017
	rename			dum_MKT_Q9_2017					dum_marketing_Q9_2017
	
	* SSE 2017 has one question that was not asked in SSE 2018, but was asked in
	* SSE 2015. I will use the same number I used for SSE 2015 (Question 10)
	
	rename			MKT_Q8_2017						marketing_Q10_2017
	rename			dum_MKT_Q8						dum_marketing_Q10_2017
	
*===============================================================================
*	Part 2: Reordering the variables
*===============================================================================

	order	firm_id type_business_entity_2017 years_functioning_2017 date_opening_2017 ///
		business_activity_code_2017 activity_2017 sales_2017 simplified_tax_system_2017 ///
		firm_zipcode_2017 firm_neighborhood_2017 firm_city_2017 parent_company_2017 ///
		number_of_subsidiaries_2017 zero_employees_2015 ///
		number_of_employees_2015 number_of_employees_2017 ///
		interview_starttime_2017 interview_endtime_2017 interview_duration_2017 ///
		sebrae_regional_office_2017 respondent_gender_2017 respondent_type_2017 ///
		respondent_age_2017 respondent_date_birth_2017 ///
		financial_management_level_2017	financial_management_Q1_2017 ///
		financial_management_Q2_2017 financial_management_Q3_2017 ///
		financial_management_Q4_2017 financial_management_Q5_2017 ///
		financial_management_Q6_2017 financial_management_Q7_2017 ///
		financial_management_Q8_2017 financial_management_Q9_2017 ///
		financial_management_Q10_2017 strategic_planning_level_2017 ///
		strategic_planning_Q1_2017 strategic_planning_Q3_2017 ///
 		market_intelligence_level_2017 market_intelligence_Q1_2017 ///
		market_intelligence_Q2_2017 market_intelligence_Q3_2017 ///
		market_intelligence_Q4_2017 market_intelligence_Q5_2017 ///
		market_intelligence_Q6_2017 marketing_level_2017 ///
		marketing_Q1_2017 marketing_Q2_2017 ///
		marketing_Q3_2017 marketing_Q5_2017 marketing_Q6_2017 marketing_Q7_2017 ///
		marketing_Q8_2017 marketing_Q9_2017 marketing_Q10_2017 ///
		dum_financial_management_Q1_2017 dum_financial_management_Q2_2017 ///
		dum_financial_management_Q3_2017 dum_financial_management_Q4_2017 ///
		dum_financial_management_Q5_2017 dum_financial_management_Q6_2017 ///
		dum_financial_management_Q7_2017 dum_financial_management_Q8_2017 ///
		dum_financial_management_Q9_2017 dum_financial_managemen_Q10_2017 ///
		dum_strategic_planning_Q1_2017 dum_strategic_planning_Q3_2017 ///
		dum_market_intelligence_Q1_2017 dum_market_intelligence_Q2_2017 ///
		dum_market_intelligence_Q3_2017 dum_market_intelligence_Q4_2017 ///
		dum_market_intelligence_Q5_2017 dum_market_intelligence_Q6_2017 ///
		dum_marketing_Q1_2017 dum_marketing_Q2_2017 dum_marketing_Q3_2017 ///
		dum_marketing_Q5_2017 dum_marketing_Q6_2017 dum_marketing_Q7_2017 ///
		dum_marketing_Q8_2017 dum_marketing_Q9_2017 dum_marketing_Q10_2017

	order 	bairro_rio, last
		
*===============================================================================
*	Part 3: Creating new variables to measure maturity
*===============================================================================

/*
To calculate the business practices indexes, questions that were not in all editions of the SSE program were excluded. This is the case of Q4 on marketing (only asked in 2018), Q10 on marketing also (not asked in 2018), and Q2 on strategic planning (only asked in 2018).

Questions were also excluded if they were considered by the WBG as not pertinent. This is (probably, must confirm) the case of Q5 and Q8 on financial management, and Q3 on strategic planning.

On total, 23 questions make up the business practices indexes, after the aforementioned exclusions.
*/

	rename		bp_2017				business_practices_mean_2017
	rename		bp_total_2017		business_practices_sum_2017

*===============================================================================
*	Part 4: Checking for firms that are repeated in the database
*===============================================================================

	bysort firm_id: g n_rep = cond(_N==1,0,_n)

	tabulate n_rep

* there is no repetition, so drop the useless variable

	drop n_rep

*===============================================================================
*	Part 5: Identifying firms that were treated in the 2017 impact evaluation
*===============================================================================

	merge 1:1 firm_id ///
	using "Experiment/Output/output_code_01e_impact_evaluation_2017.dta"
	
* dropping firms that were in the impact evaluation but were not found in SSE 2017

/* must understand why 23 firms were not found; the impact evaluation was supposed
to only involve firms in SSE 2017; why are those firms missing from SSE 2017 database?
*/

	drop if _merge == 2
	
	recode treated_impact_evaluation_2017 (.=0)
	
* dropping unnecessary variables

	drop _merge

*===============================================================================
*	Part 6: Saving the product of this code (SSE 2017 database)
*===============================================================================

	save "Experiment/Output/output_code_01f_sse_2017.dta", replace
