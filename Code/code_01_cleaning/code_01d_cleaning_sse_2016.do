********************************************************************************
* Date: 01/06/2023
* Author: Gabriela Monteiro Avelino
*
*		Code 01d: Cleaning Sebrae's database of firms in the 2016 SSE program
*
*===============================================================================
*	Part 0: Settings
*===============================================================================

*-------------------------------------------------------------------------------
*** making special characters readable -----------------------------------------
*-------------------------------------------------------------------------------

* setting a temporary work directory for unicode translate

	cd "/Users/aaronjoseph/Downloads/Capstone/Felipe/Experiment/Data"
	
* choosing the encoding for translation of the database

	unicode encoding set ISO-8859-1
	
* translating special characters (not changing the data, just variables names and
*		labels)
	
	unicode translate sse_2016.dta, nodata	
	
*-------------------------------------------------------------------------------
*** importing the data and setting work directory for the rest of the code -----
*-------------------------------------------------------------------------------

* setting the work directory

	cd "/Users/aaronjoseph/Downloads/Capstone/Felipe"
	
* importing the database of firms in the 2017 edition of the SSE program

	use "Experiment/Data/sse_2016.dta", clear

*===============================================================================
*	Part 1: Renaming and formatting the variables
*===============================================================================

	rename			CNPJ						firm_id
	label variable	firm_id						"Taxpayer number (CNPJ)"

	rename			CEP							firm_zipcode_2016
	label variable	firm_zipcode_2016			"CEP"
	
	rename			logradouro					firm_street_2016
	label variable	firm_street_2016	// dropping unnecessary labels
	
	rename			logradouro_numero			firm_street_number_2016
	label variable	firm_street_number_2016	// dropping unnecessary labels
	
	rename			logradouro_complemento		firm_sec_address_info_2016
	label variable	firm_sec_address_info_2016	"Secondary Address Information (such as apartment or suite)"
	
	rename			logradouro_bairro			firm_neighborhood_2016
	label variable	firm_neighborhood_2016 // dropping unnecessary labels
	
	rename			cidade						firm_city_2016
	label variable	firm_city_2016 // dropping unnecessary labels
	
	rename			regional_sebrae				sebrae_regional_office_2016
	label variable	sebrae_regional_office_2016 // dropping unnecessary labels
	
	rename			CNAE							business_activity_code_2016
	label variable	business_activity_code_2016		"CNAE"
	
	rename			ID								ID_2016

*-------------------------------------------------------------------------------
*** renaming the variables corresponding to the questions in the survey --------
*-------------------------------------------------------------------------------

* The questions will be numbered according to the order in which they were asked
*		in the 2018 SSE edition.

* questions related to financial management ------------------------------------
			
	rename 			GF_Q1_2016 						financial_management_Q1_2016
	rename			dum_GF_Q1_2016					dum_financial_management_Q1_2016
	
	rename 			GF_Q2_2016 						financial_management_Q2_2016
	rename			dum_GF_Q2_2016					dum_financial_management_Q2_2016
	label variable	financial_management_Q2_2016	"Existe valor e frequência definidos para a remuneração do(s) dono(s) da empresa?"
	
	rename 			GF_Q9_2016 						financial_management_Q3_2016
	rename			dum_GF_Q9_2016					dum_financial_management_Q3_2016
	
	rename 			GF_Q5_2016 						financial_management_Q4_2016
	rename			dum_GF_Q5_2016					dum_financial_management_Q4_2016
	label variable	financial_management_Q4_2016	"Quantos produtos/serviços precisa vender para cobrir os custos?"
	
	rename			GF_Q10_2016 					financial_management_Q5_2016
	rename			dum_GF_Q10_2016					dum_financial_management_Q5_2016
	
	rename			GF_Q6_2016 						financial_management_Q6_2016
	rename			dum_GF_Q6_2016					dum_financial_management_Q6_2016
		
	rename			GF_Q7_2016 						financial_management_Q7_2016
	rename			dum_GF_Q7_2016					dum_financial_management_Q7_2016
	
	rename			GF_Q8_2016 						financial_management_Q8_2016
	rename			dum_GF_Q8_2016					dum_financial_management_Q8_2016

	rename			GF_Q3_2016 						financial_management_Q9_2016
	rename			dum_GF_Q3_2016					dum_financial_management_Q9_2016
	
	rename			GF_Q4_2016 						financial_management_Q10_2016
	rename			dum_GF_Q4_2016					dum_financial_managemen_Q10_2016 // this variable has a different name (missing "t") due to the limit of 32 characters

* questions related to strategic planning --------------------------------------

	* question 2 in SSE 2018 was not asked in SSE 2016
	
	rename 			PE_Q1_2016						strategic_planning_Q1_2016
	rename			dum_PE_Q1_2016					dum_strategic_planning_Q1_2016
	
	rename 			PE_Q2_2016						strategic_planning_Q3_2016
	rename			dum_PE_Q2_2016					dum_strategic_planning_Q3_2016
	
* questions related to market intelligence -------------------------------------
	
	rename 			MERC_Q1_2016 					market_intelligence_Q1_2016
	rename			dum_MERC_Q1_2016				dum_market_intelligence_Q1_2016
	
	rename 			MERC_Q4_2016 					market_intelligence_Q2_2016
	rename			dum_MERC_Q4_2016				dum_market_intelligence_Q2_2016
	label variable	market_intelligence_Q2_2016		"Conhece seus concorrentes e a sua forma de atuação?"
	
	rename 			MERC_Q5_2016 					market_intelligence_Q3_2016
	rename			dum_MERC_Q5_2016				dum_market_intelligence_Q3_2016
	
	rename 			MERC_Q2_2016 					market_intelligence_Q4_2016
	rename			dum_MERC_Q2_2016				dum_market_intelligence_Q4_2016
	
	rename 			MERC_Q3_2016 					market_intelligence_Q5_2016
	rename			dum_MERC_Q3_2016				dum_market_intelligence_Q5_2016
	
	rename 			MERC_Q6_2016					market_intelligence_Q6_2016
	rename			dum_MERC_Q6_2016				dum_market_intelligence_Q6_2016
	
* questions related to marketing -----------------------------------------------
	
	* question 4 in SSE 2018 was not asked in SSE 2016. 
	
	rename 			MKT_Q2_2016						marketing_Q1_2016
	rename			dum_MKT_Q2_2016					dum_marketing_Q1_2016
	
	rename 			MKT_Q1_2016 					marketing_Q2_2016
	rename			dum_MKT_Q1_2016					dum_marketing_Q2_2016
		
	rename 			MKT_Q6_2016						marketing_Q3_2016
	rename			dum_MKT_Q6_2016					dum_marketing_Q3_2016
	label variable	marketing_Q3_2016				"Ao divulgar, sabe se a empresa está preparada para atender a demanda futura?"
	
	rename 			MKT_Q3_2016			 			marketing_Q5_2016
	rename			dum_MKT_Q3_2016					dum_marketing_Q5_2016
	
	rename 			MKT_Q4_2016						marketing_Q6_2016
	rename			dum_MKT_Q4_2016					dum_marketing_Q6_2016
	
	rename 			MKT_Q5_2016	 					marketing_Q7_2016
	rename			dum_MKT_Q5_2016					dum_marketing_Q7_2016
	
	rename 			MKT_Q7_2016	 					marketing_Q8_2016
	rename			dum_MKT_Q7_2016					dum_marketing_Q8_2016
	
	rename			MKT_Q9_2016						marketing_Q9_2016
	rename			dum_MKT_Q9_2016					dum_marketing_Q9_2016
	
	* SSE 2016 has one question that was not asked in SSE 2018, but was asked in
	* SSE 2015 and 2017. I will use the same number I used for SSE 2015 (Question 10)
	
	rename			MKT_Q8_2016						marketing_Q10_2016
	rename			dum_MKT_Q8_2016					dum_marketing_Q10_2016
	
*===============================================================================
*	Part 2: Reordering the variables
*===============================================================================


order	firm_id business_activity_code_2016 firm_zipcode_2016 firm_street_2016 ///
		firm_street_number_2016 firm_sec_address_info_2016 firm_neighborhood_2016 ///
		firm_city_2016 sebrae_regional_office_2016 financial_management_Q1_2016 ///
		financial_management_Q2_2016 financial_management_Q3_2016 ///
		financial_management_Q4_2016 financial_management_Q5_2016 ///
		financial_management_Q6_2016 financial_management_Q7_2016 ///
		financial_management_Q8_2016 financial_management_Q9_2016 ///
		financial_management_Q10_2016 strategic_planning_Q1_2016 ///
		strategic_planning_Q3_2016 market_intelligence_Q1_2016 ///
		market_intelligence_Q2_2016 market_intelligence_Q3_2016 ///
		market_intelligence_Q4_2016 market_intelligence_Q5_2016 ///
		market_intelligence_Q6_2016 marketing_Q1_2016 marketing_Q2_2016 ///
		marketing_Q3_2016 marketing_Q5_2016 marketing_Q6_2016 marketing_Q7_2016 ///
		marketing_Q8_2016 marketing_Q9_2016 marketing_Q10_2016 ///
		dum_financial_management_Q1_2016 dum_financial_management_Q2_2016 ///
		dum_financial_management_Q3_2016 dum_financial_management_Q4_2016 ///
		dum_financial_management_Q5_2016 dum_financial_management_Q6_2016 ///
		dum_financial_management_Q7_2016 dum_financial_management_Q8_2016 ///
		dum_financial_management_Q9_2016 dum_financial_managemen_Q10_2016 ///
		dum_strategic_planning_Q1_2016 dum_strategic_planning_Q3_2016 ///
		dum_market_intelligence_Q1_2016 dum_market_intelligence_Q2_2016 ///
		dum_market_intelligence_Q3_2016 dum_market_intelligence_Q4_2016 ///
		dum_market_intelligence_Q5_2016 dum_market_intelligence_Q6_2016 ///
		dum_marketing_Q1_2016 dum_marketing_Q2_2016 dum_marketing_Q3_2016 ///
		dum_marketing_Q5_2016 dum_marketing_Q6_2016 dum_marketing_Q7_2016 ///
		dum_marketing_Q8_2016 dum_marketing_Q9_2016 dum_marketing_Q10_2016

* putting ID at the end of the database

order 	ID_2016, last
		
*===============================================================================
*	Part 3: Creating new variables to measure maturity
*===============================================================================

/*
To calculate the business practices indexes, questions that were not in all editions of the SSE program were excluded. This is the case of Q4 on marketing (only asked in 2018), Q10 on marketing also (not asked in 2018), and Q2 on strategic planning (only asked in 2018).

Questions were also excluded if they were considered by the WBG as not pertinent. This is (probably, must confirm) the case of Q5 and Q8 on financial management, and Q3 on strategic planning.

On total, 23 questions make up the business practices indexes, after the aforementioned exclusions.
*/

rename		bp_2016				business_practices_mean_2016
rename		bp_total_2016		business_practices_sum_2016

*===============================================================================
*	Part 4: Checking for firms that are repeated in the database
*===============================================================================

bysort firm_id: g n_rep = cond(_N==1,0,_n)

tabulate n_rep

* there is no repetition, so drop the useless variable

drop n_rep

*===============================================================================
*	Part 5: Saving the product of this code (SSE 2016 database)
*===============================================================================

save "Experiment/Output/output_code_01d_sse_2016.dta", replace
