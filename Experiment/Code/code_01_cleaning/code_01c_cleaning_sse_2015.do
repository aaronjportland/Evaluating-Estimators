********************************************************************************
* Date: 25/05/2023
* Author: Gabriela Monteiro Avelino
*
*		Code 01c: Cleaning Sebrae's database of firms in the 2015 SSE program
*
*===============================================================================
*	Part 0: Settings
*===============================================================================

*-------------------------------------------------------------------------------
*** making special characters readable -----------------------------------------
*-------------------------------------------------------------------------------

* clearing all data in memory
	
	clear all
	
* setting a temporary work directory for unicode translate

	cd "/Users/aaronjoseph/Downloads/Capstone/Felipe/Experiment/Data"
	
* choosing the encoding for translation of the database

	unicode encoding set ISO-8859-1
	
* translating special characters (not changing the data, just variables names and
*		labels)
	
	unicode translate sse_2015.dta, nodata	
	
*-------------------------------------------------------------------------------
*** importing the data and setting work directory for the rest of the code -----
*-------------------------------------------------------------------------------

* setting the work directory

	cd "/Users/aaronjoseph/Downloads/Capstone/Felipe"
	
* importing the database of firms in the 2015 edition of the SSE program

	use "Experiment/Data/sse_2015.dta", clear

*===============================================================================
*	Part 1: Renaming and formatting the variables
*===============================================================================

	rename			CNPJ				firm_id
	format 			firm_id 			%20.0g
	label variable	firm_id				"Taxpayer number (CNPJ)"
	
	rename			ID					ID_2015
	format			ID_2015					%20.0g // I don't know what this ID is.

	rename			CEP					firm_zipcode_2015
	rename			bairro				firm_neighborhood_2015
	rename			cidade				firm_city_2015
	rename			regional_sebrae		sebrae_regional_office_2015
	rename			CNAE				business_activity_code_2015

*-------------------------------------------------------------------------------
*** renaming the variables corresponding to the questions in the survey --------
*-------------------------------------------------------------------------------

* The questions will be numbered according to the order in which they were asked
*		in the 2018 SSE edition.

* To label the questions, I used the file "PDC 2015.xlsx" in the folder 
*		"Support files".

* questions related to financial management ------------------------------------
	
	rename 			GF_Q1_2015 						financial_management_Q1_2015
	rename			dum_GF_Q1_2015					dum_financial_management_Q1_2015
	label variable	financial_management_Q1_2015	"Separa o dinheiro pessoal do dinheiro da empresa?"
	
	rename 			GF_Q2_2015 						financial_management_Q2_2015
	rename			dum_GF_Q2_2015					dum_financial_management_Q2_2015
	label variable	financial_management_Q2_2015	"Existe valor e frequência definidos para a remuneração do(s) dono(s) da empresa?"
	
	rename 			GF_Q9_2015 						financial_management_Q3_2015
	rename			dum_GF_Q9_2015					dum_financial_management_Q3_2015
	label variable	financial_management_Q3_2015	"Você sabe calcular o preço de venda?"
	
	rename 			GF_Q5_2015 						financial_management_Q4_2015
	rename			dum_GF_Q5_2015					dum_financial_management_Q4_2015
	label variable	financial_management_Q4_2015	"Quantos produtos/serviços precisa vender para cobrir os custos?"
	
	rename			GF_Q10_2015 					financial_management_Q5_2015
	rename			dum_GF_Q10_2015					dum_financial_management_Q5_2015
	label variable	financial_management_Q5_2015	"Usa créditos (bancários ou não) para cobrir suas despesas?"
	
	rename			GF_Q6_2015 						financial_management_Q6_2015
	rename			dum_GF_Q6_2015					dum_financial_management_Q6_2015
	label variable	financial_management_Q6_2015	"Você analisa os resultados financeiros de sua empresa?"
		
	rename			GF_Q7_2015 						financial_management_Q7_2015
	rename			dum_GF_Q7_2015					dum_financial_management_Q7_2015
	label variable	financial_management_Q7_2015	"Sabe qual a necessidade de capital de giro para a sua empresa?"
	
	rename			GF_Q8_2015 						financial_management_Q8_2015
	rename			dum_GF_Q8_2015					dum_financial_management_Q8_2015
	label variable	financial_management_Q8_2015	"Você controla o seu estoque? Como?"

	rename			GF_Q3_2015 						financial_management_Q9_2015
	rename			dum_GF_Q3_2015					dum_financial_management_Q9_2015
	label variable	financial_management_Q9_2015	"Possui ferramentas para controle financeiro?"
	
	rename			GF_Q4_2015 						financial_management_Q10_2015
	rename			dum_GF_Q4_2015					dum_financial_managemen_Q10_2015 // this variable has a different name (missing "t") due to the limit of 32 characters
	label variable	financial_management_Q10_2015	"Sabe o custo fixo e variável da empresa?" 

* questions related to strategic planning --------------------------------------

	* question 2 in SSE 2018 was not asked in SSE 2015

	rename 			PE_Q1_2015						strategic_planning_Q1_2015
	rename			dum_PE_Q1_2015					dum_strategic_planning_Q1_2015
	label variable	strategic_planning_Q1_2015		"Possui planejamento estratégico para sua empresa?"
	
	rename 			PE_Q2_2015						strategic_planning_Q3_2015
	rename			dum_PE_Q2_2015					dum_strategic_planning_Q3_2015
	label variable	strategic_planning_Q3_2015		"Você tem interesse em expandir ou reposicionar o seu negócio?"
	
* questions related to market intelligence -------------------------------------

	rename 			MERC_Q1_2015 					market_intelligence_Q1_2015
	rename			dum_MERC_Q1_2015				dum_market_intelligence_Q1_2015
	label variable	market_intelligence_Q1_2015		"Você conhece os clientes (perfil) que compram o seu produto?"
	
	rename 			MERC_Q4_2015 					market_intelligence_Q2_2015
	rename			dum_MERC_Q4_2015				dum_market_intelligence_Q2_2015
	label variable	market_intelligence_Q2_2015		"Conhece seus concorrentes e a sua forma de atuação?"
	
	rename 			MERC_Q5_2015 					market_intelligence_Q3_2015
	rename			dum_MERC_Q5_2015				dum_market_intelligence_Q3_2015
	label variable	market_intelligence_Q3_2015		"Você analisa/compara seus fornecedores?"
	
	rename 			MERC_Q2_2015 					market_intelligence_Q4_2015
	rename			dum_MERC_Q2_2015				dum_market_intelligence_Q4_2015
	label variable	market_intelligence_Q4_2015		"Você possui cadastro desses clientes?"
	
	rename 			MERC_Q3_2015 					market_intelligence_Q5_2015
	rename			dum_MERC_Q3_2015				dum_market_intelligence_Q5_2015
	label variable	market_intelligence_Q5_2015		"Você sabe quantas vezes o cliente volta a comprar na sua empresa?"
	
	rename 			MERC_Q6_2015  					market_intelligence_Q6_2015
	rename			dum_MERC_Q6_2015				dum_market_intelligence_Q6_2015
	label variable	market_intelligence_Q6_2015		"Busca informações sobre o seu segmento?"
	
* questions related to marketing -----------------------------------------------
	
	* question 4 in SSE 2018 was not asked in SSE 2015. 
	
	rename 			MKT_Q2_2015						marketing_Q1_2015
	rename			dum_MKT_Q2_2015					dum_marketing_Q1_2015
	label variable	marketing_Q1_2015				"Realiza algum tipo de divulgação dos seus produtos?"
	
	rename 			MKT_Q1_2015 					marketing_Q2_2015
	rename			dum_MKT_Q1_2015					dum_marketing_Q2_2015
	label variable	marketing_Q2_2015				"Sua empresa possui marca registrada?"
		
	rename 			MKT_Q6_2015						marketing_Q3_2015
	rename			dum_MKT_Q6_2015					dum_marketing_Q3_2015
	label variable	marketing_Q3_2015				"Ao divulgar, sabe se a empresa está preparada para atender a demanda futura?"
	
	rename 			MKT_Q3_2015			 			marketing_Q5_2015
	rename			dum_MKT_Q3_2015					dum_marketing_Q5_2015
	label variable	marketing_Q5_2015				"Sabe se a divulgação traz retorno?"
	
	rename 			MKT_Q4_2015	 					marketing_Q6_2015
	rename			dum_MKT_Q4_2015					dum_marketing_Q6_2015
	label variable	marketing_Q6_2015				"Tem alguma ação pós venda?"
	
	rename 			MKT_Q5_2015	 					marketing_Q7_2015
	rename			dum_MKT_Q5_2015					dum_marketing_Q7_2015
	label variable	marketing_Q7_2015				"Você realiza trabalho de fidelização com o seu cliente?"
	
	rename 			MKT_Q7_2015	 					marketing_Q8_2015
	rename			dum_MKT_Q7_2015					dum_marketing_Q8_2015
	label variable	marketing_Q8_2015				"Possui plano de marketing para a empresa?"
	
	rename			MKT_Q9_2015						marketing_Q9_2015
	rename			dum_MKT_Q9_2015					dum_marketing_Q9_2015
	label variable 	marketing_Q9_2015				"Você busca alternativas digitais para chegar ao seu cliente?"
	
	* SSE 2015 has one question that was not asked in SSE 2018. To keep the
	* numbers consistent with SSE 2018, I will number this question as 10
	
	rename			MKT_Q8_2015						marketing_Q10_2015
	rename			dum_MKT_Q8_2015					dum_marketing_Q10_2015
	label variable	marketing_Q10_2015				"Possui interesse em comércio eletrônico?"
	
*===============================================================================
*	Part 2: Reordering the variables
*===============================================================================

order	firm_id business_activity_code_2015 firm_zipcode_2015 firm_neighborhood_2015 ///
		firm_city_2015 sebrae_regional_office_2015 financial_management_Q1_2015 ///
		financial_management_Q2_2015 financial_management_Q3_2015 ///
		financial_management_Q4_2015 financial_management_Q5_2015 ///
		financial_management_Q6_2015 financial_management_Q7_2015 ///
		financial_management_Q8_2015 financial_management_Q9_2015 ///
		financial_management_Q10_2015 strategic_planning_Q1_2015 ///
		strategic_planning_Q3_2015 market_intelligence_Q1_2015 ///
		market_intelligence_Q2_2015 market_intelligence_Q3_2015 ///
		market_intelligence_Q4_2015 market_intelligence_Q5_2015 ///
		market_intelligence_Q6_2015 marketing_Q1_2015 marketing_Q2_2015 ///
		marketing_Q3_2015 marketing_Q5_2015 marketing_Q6_2015 marketing_Q7_2015 ///
		marketing_Q8_2015 marketing_Q9_2015 marketing_Q10_2015 ///
		dum_financial_management_Q1_2015 dum_financial_management_Q2_2015 ///
		dum_financial_management_Q3_2015 dum_financial_management_Q4_2015 ///
		dum_financial_management_Q5_2015 dum_financial_management_Q6_2015 ///
		dum_financial_management_Q7_2015 dum_financial_management_Q8_2015 ///
		dum_financial_management_Q9_2015 dum_financial_managemen_Q10_2015 ///
		dum_strategic_planning_Q1_2015 dum_strategic_planning_Q3_2015 ///
		dum_market_intelligence_Q1_2015 dum_market_intelligence_Q2_2015 ///
		dum_market_intelligence_Q3_2015 dum_market_intelligence_Q4_2015 ///
		dum_market_intelligence_Q5_2015 dum_market_intelligence_Q6_2015 ///
		dum_marketing_Q1_2015 dum_marketing_Q2_2015 dum_marketing_Q3_2015 ///
		dum_marketing_Q5_2015 dum_marketing_Q6_2015 dum_marketing_Q7_2015 ///
		dum_marketing_Q8_2015 dum_marketing_Q9_2015 dum_marketing_Q10_2015

* putting ID at the end of the database

order 	ID_2015, last
		
*===============================================================================
*	Part 3: Creating new variables to measure maturity
*===============================================================================

/*
To calculate the business practices indexes, questions that were not in all editions of the SSE program were excluded. This is the case of Q4 on marketing (only asked in 2018), Q10 on marketing also (not asked in 2018), and Q2 on strategic planning (only asked in 2018).

Questions were also excluded if they were considered by the WBG as not pertinent. This is (probably, must confirm) the case of Q5 and Q8 on financial management, and Q3 on strategic planning.

On total, 23 questions make up the business practices indexes, after the aforementioned exclusions.

In 2015, some firms did not answer all questions in the survey; thus, there are some missing values. To calculate the "business_practices_mean" variable when there are missing values, the question is eliminated for that firm. Thus, the mean is calculated as the sum of the dummies, divided by 22 (instead of 23). To calculate the "business_practices_sum" variable, the missing value is replaced by the previously calculated mean. Then, all 23 variables are summed.

*/

rename		bp_2015				business_practices_mean_2015
rename		bp_total_2015		business_practices_sum_2015

*===============================================================================
*	Part 4: Checking for firms that are repeated in the database
*===============================================================================

bysort firm_id: g n_rep = cond(_N==1,0,_n)

tabulate n_rep

* there is no repetition, so drop the useless variable

drop n_rep

*===============================================================================
*	Part 5: Saving the product of this code (SSE 2015 database)
*===============================================================================

save "Experiment/Output/output_code_01c_sse_2015.dta", replace
