********************************************************************************
* Date: 19/05/2023
* Author: Gabriela Monteiro Avelino
*
*		Code 01b: Cleaning data from the 2018 survey conducted by the World Bank
*
*		The questions from the survey translated to English can be found in 
*			the PDF file "Supplementary Survey - SSE 2018"
*
*===============================================================================
*	Part 0: Settings
*===============================================================================

* setting the work directory

	cd "/Users/aaronjoseph/Downloads/Capstone/Felipe"
	
* importing the database of firms who answered the survey from the World Bank

	import excel "Experiment\Data\SSE_2018_Survey_RAW.xlsx", firstrow clear

*===============================================================================
*	Part 1: Renaming the variables
*===============================================================================

* eliminating information that will not be used

drop 	deviceid subscriberid simid devicephonenum username caseid textaudit ///
			nome_regional nome_agente digit1- DV2

*-------------------------------------------------------------------------------
*** renaming the variables with the main questions -----------------------------
*-------------------------------------------------------------------------------

* Questions are numbered according to the order in which they appear in the
*		"Supplementary Survey - SSE 2018" file. Check the file for translation.

rename 				educ								Q1_respondent_educ_level_2018
label variable 		Q1_respondent_educ_level_2018		"Qual a sua escolaridade?"

rename 				exp									Q2_respondent_busin_experi_2018
label variable 		Q2_respondent_busin_experi_2018 	"Quantos anos de experiência em gestão de negócios você tem?"

rename				shared_tasks						Q3_task_distribution_2018
label variable 		Q3_task_distribution_2018			"Como são divididas as tarefas de gestão entre o proprietário e colaboradores?"

rename				franquia							Q4_franchise_2018
label variable 		Q4_franchise_2018 					"Seu negócio é uma franquia?"

rename				employees_hire						Q5_employees_hired_2018
label variable 		Q5_employees_hired_2018				"Nos últimos 6 meses, quantos funcionários a empresa contratou?"

rename				employees_fire						Q6_employees_fired_2018
label variable 		Q6_employees_fired_2018				"E quantos teve que demitir nesses últimos 6 meses?"

rename				competition_time					Q7_competition_time_2018
label variable 		Q7_competition_time_2018			"Se a empresa fechasse, em quanto tempo os clientes encontrariam um substituto?"

rename				competition_location				Q8_competitors_location_2018
label variable 		Q8_competitors_location_2018		"Onde se localiza o maior concorrente do seu negócio?"

rename				competition_bp						Q9_competitors_practices_2018
label variable 		Q9_competitors_practices_2018		"Como você avalia os seus principais concorrentes quanto ao nível de gestão?"

rename				expec								Q10_expected_profits_2018
label variable 		Q10_expected_profits_2018			"Suponha lucro atual de 1.000. Ao melhorar a gestão, o lucro mudaria?"

rename				expec_raise							Q11a_expec_profits_increase_2018
label variable 		Q11a_expec_profits_increase_2018	"O lucro aumentaria para quanto, considerando o valor inicial de R$ 1.000,00?"

rename				expec_low 							Q11b_expec_profits_decrease_2018
label variable 		Q11b_expec_profits_decrease_2018	"O lucro diminuiria para quanto, considerando o valor inicial de R$ 1.000,00?"

rename				sales								Q12_annual_sales_2018					
label variable 		Q12_annual_sales_2018				"Qual o faturamento anual do negócio?"

rename				risk								Q13_respondent_risk_averse_2018
label variable 		Q13_respondent_risk_averse_2018		"Você tem disposição em assumir riscos no seu negócio?"

rename				opportunity							Q14_entrepren_by_necessity_2018
label variable		Q14_entrepren_by_necessity_2018		"Você é empreendedor(a) para aproveitar uma oportunidade ou por falta de opção?"

rename				change_business						Q15_rather_be_employee_2018
label variable 		Q15_rather_be_employee_2018			"Trocaria seu negócio por um emprego com carteira assinada de mesma renda média?"

rename				change_business_50					Q16_rather_be_employee_50_2018
label variable 		Q16_rather_be_employee_50_2018		"E se fosse para ganhar 50% a mais?"

*-------------------------------------------------------------------------------
*** renaming the remaining variables -------------------------------------------
*-------------------------------------------------------------------------------

* formatting and renaming the firm identifier to make it consistent across databases

rename 				id									firm_id
label variable		firm_id 							"Taxpayer number (CNPJ)"
format 				firm_id 							%20.0g

* this assessment of interest in Sebrae made by the interviewer, not the respondent

rename				perception_agent					interest_in_sebrae_2018
label variable  	interest_in_sebrae_2018				"Entrevistador: de 1 a 5, o quanto o cliente demonstrou interesse no Sebrae?"

rename				starttime 							survey_starttime_2018
rename 				endtime								survey_endtime_2018
rename				SubmissionDate						submission_date_2018
rename				duration							survey_duration_2018
rename				regional							sebrae_region_offi_WBGsurvey2018
rename				agente								interviewer_2018

* reordering the variables in the database

order				firm_id sebrae_region_offi_WBGsurvey2018 interviewer_2018 ///
					interest_in_sebrae_2018 submission_date_2018 ///
					survey_starttime_2018 survey_endtime_2018 ///
					survey_duration_2018

order				GPSLatitude GPSLongitude GPSAltitude GPSAccuracy, last
						
*===============================================================================
*	Part 2: Labelling the answers for each question in the survey
*===============================================================================

* the "worst" scenario scores 1, and the highest score goes to the "best" scenario,
*		except for when there is an option "I don't know" -- then, the highest score goes
*		to that option. should "I don't know" score 0 instead? or be a missing value?

* Question 1

label define 		Q1_respondent_educ_level_2018 ///
					1		"Não frequentou escola" ///
					2		"Fundamental Incompleto" ///
					3		"Fundamental Completo" ///
					4		"Médio Incompleto" ///
					5		"Médio Completo" ///
					6		"Superior Incompleto" ///
					7		"Superior Completo" ///
					8		"Pós-Graduação Incompleta" ///
					9		"Pós-Graduação Completa"

* Question 2

label define		Q2_respondent_busin_experi_2018 ///
					1 		"Até 2 anos" ///
					2		"De 3 a 5 anos" ///
					3		"De 6 a 10 anos" ///
					4		"Mais de 10 anos"
					
* Question 3

label define		Q3_task_distribution_2018 ///
					1 		"Apenas o proprietário realiza esse tipo de tarefa" ///
					2		"Proprietário e funcionários familiares dividem esse tipo de tarefa" ///
					3		"Proprietário e outros funcionário (não familiares) dividem esse tipo de tarefa"			

* Question 4

* not sure what the scoring should be here.

label define		Q4_franchise_2018 ///
					0 		"Não" ///
					1 		"Sim"

* Question 7

label define		Q7_competition_time_2018 ///
					1		"Até um dia" ///
					2		"Entre um dia e uma semana" ///
					3		"Entre uma semana e um mês" ///
					4		"Mais de um mês" ///
					5		"Não encontraria alternativa" ///
					6		"Não sabe avaliar [Não ler essa alternativa]"

* Question 8

label define		Q8_competitors_location_2018 ///
					1 		"Dentro do seu bairro" ///
					2		"Nessa cidade, mas em outro bairro" ///
					3		"Em outra cidade, mas no Estado do Rio de Janeiro" ///
					4		"Em outro Estado" ///
					5		"Fora do Brasil" ///
					6		"Não sabe avaliar [Não ler essa alternativa]"

* Question 9					

* the scoring seems inconsistent. 3 should actually be 1, and 1 should be 3.

label define		Q9_competitors_practices_2018 ///
					1		"Eles possuem o nível de gestão menor" ///
					2		"Eles possuem o mesmo nível de gestão" ///
					3 		"Eles possuem o nível de gestão mais alto" ///
					4		"Não sabe responder (NÃO LER ESSA OPÇÃO)"

* Question 10

* it seems this scoring should be the other way around. score 3 should go to
*		those who believe their profits will go up if they improve their business
*		practices.

label define		Q10_expected_profits_2018 ///
					1 		"Aumentar" ///
					2		"Permanecer em R$ 1.000,00" ///
					3		"Diminuir"

* Question 12

label define		Q12_annual_sales_2018 ///
					0 		"Ainda não faturou nada"  ///
					1		"Até R$ 12.000,00 (+- R$ 1.000,00 mês)" ///
					2		"De R$ 12.000,01 a R$ 24.000,00  (+ de R$1.000,00 até R$ 2.000,00 mês)" ///
					3		"De R$ 24.000,01 a R$ 36.000,00  (+ de R$ 2.000,00 até R$ 3.000,00 mês)" ///
					4		"De R$ 36.000,01 a R$ 48.000,00 (+ de R$ 3.000,00 até R$ 4.000,00 mês)" ///
					5		"De R$ 48.000,01 a R$ 60.000,00 (+ de R$ 4.000,00 até R$ 5.000,00 mês)" ///
					6		"De R$ 60.000,01 a R$ 90.000,00 (+ de R$ 5.000,00 até R$ 7.500,00 mês)" ///
					7		"De R$ 90.000,01 a R$ 180.000,00 (+ de R$ 7.500,00 até R$ 15.000,00 mês)" ///
					8		"De R$ 180.000,01 a R$ 270.000,00 (+ de R$ 15.000,00 a R$ 22.500,00 mês)" ///
					9		"De R$ 270.000,01 a R$ 540.000,00 (+ de R$ 22.500,00 a R$ 45.000,00 mês)" ///
					10		"De R$ 540.000,01 a R$ 900.000,00 (+ de R$ 45.000,00 a R$ 75.000,00 mês)" ///
					11		"De R$ 900.000,01 a R$ 1.800.000,00 (+ de R$ 75.000,00 a R$ 150.000,00 mês)" ///
					12		"De R$ 1.800.000,01 a R$ 2.700.000,00 (+ de R$ 150.000,00 a R$ 225.000,00 mês)" ///
					13		"De R$ 2.700.000,01 a R$ 3.600.000,00 (+ de R$ 225.000,00 a R$ 300.000,00 mês)" ///
					14		"Acima de R$ 3.600.000,00 (+ de R$ 300.000,00 mês)" ///
					15		"Não Sabe (NÃO LER)" ///
					16		"Recusou (NÃO LER)"

* Question 13

* maybe the score should be the other way around; inclination to take on risks
*		seems important for entrepreneurship.

label define		Q13_respondent_risk_averse_2018 ///
					1 		"Totalmente inclinada a assumir riscos" ///
					2		"Moderadamente inclinada a assumir riscos" ///
					3		"Pouco inclinada a assumir riscos" ///
					4		"Nada inclinada a assumir riscos"

* Question 14

* this scoring also seems inconsistent. 1 should actually be 3, 2 should actually
*		be 1, and 3 should be 2.

label define		Q14_entrepren_by_necessity_2018 ///
					1 		"Para aproveitar uma oportunidade de negócio"  ///
					2		"Não tinha opção melhor de trabalho"  ///
					3		"Tinha trabalho, mas buscava melhores oportunidades" ///
					4		"Não sabe (NÃO LER)"

* Question 15

* this scoring also seems inconsistent. the other scores do not have a 0. 
*		0 should actually be 3.

label define		Q15_rather_be_employee_2018 ///
					0		"Não"  ///
					1 		"Sim"  ///
					2		"Já tem carteira assinada"  ///
					3		"Não sabe"

* Question 16

* again, this scoring seems inconsistent. the other scores do not have a 0. 
*		also, there is no 2. 0 should actually be 3.

label define		Q16_rather_be_employee_50_2018 ///
					0		"Não" ///
					1 		"Sim"  ///
					3		"Não sabe (Não LER)"

*-------------------------------------------------------------------------------
*** labelling the values of the other variables --------------------------------
*-------------------------------------------------------------------------------

label define 		sebrae_region_offi_WBGsurvey2018 ///
					1		"BAIXADA I - NOVA IGUAÇU" ///
					2		"BAIXADA II - ER CAXIAS" ///
					3		"LESTE FLUMINENSE - ER NITERÓI" ///
					4		"RIO DE JANEIRO I - ER CENTRO" ///
					5		"RIO DE JANEIRO II - ER BARRA" ///
					6		"RIO DE JANEIRO III - ER MÉIER"

*-------------------------------------------------------------------------------
*** adding the labels ----------------------------------------------------------
*-------------------------------------------------------------------------------
		
foreach 	var of varlist 		Q1_respondent_educ_level_2018 ///
								Q2_respondent_busin_experi_2018 ///
								Q3_task_distribution_2018 ///
								Q4_franchise_2018 ///
								Q7_competition_time_2018 ///
								Q8_competitors_location_2018 ///
								Q9_competitors_practices_2018 ///
								Q10_expected_profits_2018 ///
								Q12_annual_sales_2018 ///
								Q13_respondent_risk_averse_2018 ///
								Q14_entrepren_by_necessity_2018 ///
								Q15_rather_be_employee_2018 ///
								Q16_rather_be_employee_50_2018 ///
								sebrae_region_offi_WBGsurvey2018	{
								
			label values `var' `var'
			
			}

*===============================================================================
*	Part 3: Checking for firms that are repeated in the database
*===============================================================================

bysort firm_id (survey_starttime_2018): g survey_round_2018 = cond(_N==1,0,_n)

tabulate survey_round_2018

* entries with "survey_round" == 0 correspond to firms who only answered the 
*		survey once. entries with "survey_round" == 1 correspond to the first
*		answer of a firm who answered the survey more than once. 
*		"survey_round" == 2 is the second answer, and so on.

* why weren't the duplicates eliminated, as in "code_01a_cleaning_sse_2018"?

*===============================================================================
*	Part 4: Saving the product of this code (WBG survey 2018)
*===============================================================================

save "Experiment/Output/output_code_01b_WBG_survey_2018.dta", replace 
