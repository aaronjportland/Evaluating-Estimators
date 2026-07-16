********************************************************************************
* Date: 15/05/2023
* Author: Gabriela Monteiro Avelino
*
*		Code 01a: Cleaning Sebrae's database of firms in the 2018 SSE program
*
*===============================================================================
*	Part 0: Settings
*===============================================================================

* setting the work directory

	cd "/Users/aaronjoseph/Downloads/Capstone/Felipe"
	
* importing Sebrae's database of people interviewed in the 2018 edition of the 
* 		SSE program

	import excel "Experiment\Data\SSE_2018_all.xlsx", firstrow clear

*===============================================================================
*	Part 1: Creating and formatting additional variables
*===============================================================================
	
	generate	date_opening_2018					= date(DataAbertura, "DMY")
	format 		date_opening_2018					%td
	generate	years_functioning_2018				= floor((date("22/05/2018", "DM20Y")-date_opening)/365.25)
		
	generate	interview_starttime_2018			= clock(AtendimentoInício, "DMYhms")
	generate	interview_endtime_2018				= clock(AtendimentoFim, "DMYhms")
	format 		interview_starttime_2018 interview_endtime_2018		%tc
	
	generate	respondent_date_birth_2018			= date(Nascimento, "DMY")
	format 		respondent_date_birth_2018			%td
	generate	respondent_age_2018					= floor((date("22/05/2018", "DM20Y")-respondent_date_birth)/365.25)
	
* checking if age of the respondent makes sense
	
	tabulate	respondent_age_2018

* there are some people too young or too old; turning them into missing data

	recode 		respondent_age_2018			(-1/15 = .) (100/120 = .) //probably a typo
	

	generate	date_actionplan1_2018		= date(DataPlanodeAção1, "DMY")
	format 		date_actionplan1_2018		%td
	generate	date_actionplan2_2018		= date(DataPlanodeAção2, "DMY")
	format 		date_actionplan2_2018		%td
	
* the third action plan is missing in 4 entries
	
	generate	date_actionplan3_2018		= date(DataPlanodeAção3, "DMY")
	format 		date_actionplan3_2018		%td

* dropping unused variables

	drop 		DataAbertura AtendimentoInício AtendimentoFim ///
	Nascimento DataPlanode*
	
*===============================================================================
*	Part 2: Renaming and formatting the existing variables
*===============================================================================	

* turning string into numeric
	
	encode 				Setor, 						g(sector_IBGE_2018)
	label variable		sector_IBGE_2018			"Activity sector in 2018, according to IBGE's classification"
	
	encode 				Porte, 						g(size_2018)
	encode 				Regional, 					g(sebrae_regional_office_2018)
	encode 				Ação, 						g(sebrae_action_2018)
	encode 				VinculocomaEmpresa, 		g(respondent_type_2018)
	encode 				Sexo, 						g(respondent_gender_2018)

* dropping unused variables

	drop 				Setor Porte Regional Ação VinculocomaEmpresa Sexo
	
* formatting the firm's ID 	
	
	format 				CNPJ 						%20.0g
	rename				CNPJ						firm_id
	label variable		firm_id						"Taxpayer number (CNPJ)"

* renaming other variables	
	
	rename 			JurídicaCEP 						firm_zipcode_2018
	rename 			JurídicaLogradouroBairro 			firm_neighborhood_2018
	rename 			JurídicaLogradouroCidade 			firm_city_2018
	rename 			JurídicaLogradouroUF 				firm_state_2018
	rename 			NomeFantasia 						firm_name_2018
	rename 			NomeCliente 						respondent_name_2018
	rename 			FísicaCEP 							respondent_zipcode_2018

* the secondary address information is supposed to refer to the respondent, but
*		the answers seem to suggest it refers, in many cases, to the firm

	rename 			FísicaLogradouroComplemento	///
					respondent_sec_address_info_2018
					
	label variable	respondent_sec_address_info_2018 ///
					"Secondary Address Information (such as apartment or suite)"
	
	rename 			FísicaLogradouroBairro			respondent_neighborhood_2018
	rename 			FísicaLogradouroCidade 			respondent_city_2018
	rename 			FísicaLogradouroUF 				respondent_state_2018
	
	rename 			Nível_GF						financial_management_level_2018
	label variable	financial_management_level_2018	///
					"Level of maturity in financial management, as assessed by Sebrae"
	
	rename 			Solução_GF						financial_manag_solution_2018
	label variable	financial_manag_solution_2018 ///
					"Recommended products/services based on the firm's existing financial practices"
	
	rename 			Nível_PE						strategic_planning_level_2018
	label variable	strategic_planning_level_2018	"Level of maturity in strategic planning, as assessed by Sebrae"
	
	rename 			Solução_PE						strategic_planning_solution_2018
	label variable	strategic_planning_solution_2018 ///
					"Recommended products/services based on the firm's existing strategic planning"
	
	rename 			Nível_MERC						market_intelligence_level_2018
	label variable	market_intelligence_level_2018	///
					"Level of maturity in market intelligence, as assessed by Sebrae"
	
	rename 			Solução_MERC					market_intelligenc_solution_2018
	label variable	market_intelligenc_solution_2018	///
					"Recommended products/services based on the firm's existing market intelligence" // name of the variable is missing a letter due to character limitation
	
	rename 			Nível_MKT						marketing_level_2018
	label variable	marketing_level_2018 			"Level of maturity in marketing, as assessed by Sebrae"
	
	rename 			Solução_MKT						marketing_solution_2018
	label variable	marketing_solution_2018			"Recommended products/services based on the firm's existing marketing practices"
	
	rename 			PlanodeAção1 					action_plan1_2018
	rename 			PlanodeAção2 					action_plan2_2018
	rename 			PlanodeAção3 					action_plan3_2018
	rename			Agente							interviewer_name_2018
	
	rename			CNAE							business_activity_code_2018
	label variable	business_activity_code_2018		"CNAE number"
	
*-------------------------------------------------------------------------------
*** renaming the variables corresponding to the questions in the survey --------
*-------------------------------------------------------------------------------

* questions related to financial management ------------------------------------
	
	rename 			Separaodinheiropessoaldodin 		financial_management_Q1_2018
	rename 			Existevalorefrequênciadefini 		financial_management_Q2_2018
	rename 			Vocêsabecalcularopre	 			financial_management_Q3_2018
	rename 			Quantosprodutosprecisaproduzi 		financial_management_Q4_2018
	rename 			Usacréditosbancários				financial_management_Q5_2018
	rename 			Vocêanalisaosresultadosfinan 		financial_management_Q6_2018
	rename 			Sabequalanecessidadedecapit 		financial_management_Q7_2018
	rename 			VocêcontrolaoseuestoqueCom 			financial_management_Q8_2018
	rename 			Possuiferramentasavançadaspar 		financial_management_Q9_2018
	rename 			Sabeocustofixoevariávelda 			financial_management_Q10_2018

	* making some questions shorter so the labels fit
			
	label variable	financial_management_Q4_2018		"Quantos produtos/serviços precisa vender para cobrir os custos?"
	
	label variable	financial_management_Q7_2018		"Sabe qual a necessidade de capital de giro para a sua empresa?"
	
	label variable	financial_management_Q8_2018		"Você controla o seu estoque? Como?"
	
* questions related to strategic planning --------------------------------------

	rename 			Vocêjárealizoualgumtipode			strategic_planning_Q1_2018 
	rename 			Possuivisãodefuturoestrat 			strategic_planning_Q2_2018 // question added in SSE 2018
	rename 			Vocêteminteresseemexpandir	 		strategic_planning_Q3_2018
	
	* making some questions shorter so the labels fit
	
	label variable	strategic_planning_Q2_2018			"Possui visão de futuro, estratégia e monitoramento em plano de ação/indicadores?"

* questions related to market intelligence -------------------------------------

	rename 			Vocêconheceosclientesper 			market_intelligence_Q1_2018
	rename 			Conheceseusconcorrenteseasu 		market_intelligence_Q2_2018
	rename 			Vocêanalisacomparaseusfornec 		market_intelligence_Q3_2018
	rename 			Vocêpossuicadastrodessesclie 		market_intelligence_Q4_2018
	rename 			Vocêsabequantasvezesoclient 		market_intelligence_Q5_2018
	rename 			Buscainformaçõessobreos 			market_intelligence_Q6_2018
	
	* making some questions shorter so the labels fit
	
	label variable	market_intelligence_Q2_2018			"Conhece seus concorrentes e a sua forma de atuação?"
	
	label variable	market_intelligence_Q3_2018			"Você analisa/compara seus fornecedores?"

* questions related to marketing -----------------------------------------------
	
	rename 			Realizaaçõescampanhas				marketing_Q1_2018
	rename 			Suaempresapossuimarcaregistr 		marketing_Q2_2018
	rename 			Aorealizardivulga					marketing_Q3_2018
	rename 			Temmecanismodeacompanhamen	 		marketing_Q4_2018 	// question added in SSE 2018	
	rename 			Sabeoretornodadivulga	 			marketing_Q5_2018
	rename 			Temalgumaação	 					marketing_Q6_2018
	rename 			Vocêrealizatrabalhodefidel	 		marketing_Q7_2018
	rename 			Possuiplanodemarketingpara	 		marketing_Q8_2018
	rename 			Desenvolvenovoscanaisdecom	 		marketing_Q9_2018
	
/*
Question 9 in SSE 2018 ("Desenvolve novos canais de comercialização (midia digital, p ex.) ou parcerias para aumentar seu acesso a cliente?") is considerably different from Question 9 in SSE 2015 ("Você busca alternativas digitais para chegar ao seu cliente?").
Still, since Question 9 goes into the business practices index in both years, I believe it was considered sufficiently equivalent across periods.
*/

	* making some questions shorter so the labels fit
	
	label variable 	marketing_Q3_2018					"Ao divulgar, sabe se a empresa está preparada para atender à demanda futura?"
	
*===============================================================================
*	Part 3: Formatting the answers to the survey
*===============================================================================

* turning string into numeric for the answers in the survey. the best practice 
* 		scores 3, the worst scores 1.

*-------------------------------------------------------------------------------
*** questions related to financial management ----------------------------------
*-------------------------------------------------------------------------------

* Question 1

replace financial_management_Q1_2018 = "1" if ///
	financial_management_Q1_2018 == "Não separo."
	
replace financial_management_Q1_2018 = "2" if ///
	financial_management_Q1_2018 == "Separo, porém misturo transações pessoais e da empresa."
	
replace financial_management_Q1_2018 = "3" if ///
	financial_management_Q1_2018 == "Separo completamente."
	
label define financial_management_Q1_2018 ///		
		1		"Não separo."	 ///
		2		"Separo, porém misturo transações pessoais e da empresa." ///
		3		"Separo completamente."

* Question 2

replace financial_management_Q2_2018 = "1" if ///
	financial_management_Q2_2018 == "Não há frequência nem valor definido."
	
replace financial_management_Q2_2018 = "2" if ///
	financial_management_Q2_2018 == "Existe frequência definida porém não há valores determinados. Ou existe valor mas não há frequência."
	
replace financial_management_Q2_2018 = "3" if ///
	financial_management_Q2_2018 == "Existem valores e frequência definidos."
	
label define financial_management_Q2_2018 ///
		1		"Não há frequência nem valor definido." ///
		2		"Existe frequência definida porém não há valores determinados. Ou existe valor mas não há frequência."  ///
		3		"Existem valores e frequência definidos."
		
* Question 3
	
replace financial_management_Q3_2018 = "1" if ///
	financial_management_Q3_2018 == "Não sei calcular."

replace financial_management_Q3_2018 = "2" if ///
	financial_management_Q3_2018 == "Calculo conforme o mercado."
	
replace financial_management_Q3_2018 = "3" if ///
	financial_management_Q3_2018 == "Sei calcular."

label define financial_management_Q3_2018 ///
		1		"Não sei calcular."  ///
		2		"Calculo conforme o mercado."  ///
		3		"Sei calcular."

* Question 4

replace financial_management_Q4_2018 = "1" if ///
	financial_management_Q4_2018 == "Não sei."
	
replace financial_management_Q4_2018 = "2" if ///
	financial_management_Q4_2018 == "Sei mas não sei se faço da forma correta."
	
replace financial_management_Q4_2018 = "3" if ///
	financial_management_Q4_2018 == "Sei a quantidade de produtos que preciso vender."

label define financial_management_Q4_2018 ///		
		1		"Não sei."  ///
		2		"Sei mas não sei se faço da forma correta." ///
		3		"Sei a quantidade de produtos que preciso vender."

* Question 5

* using borrowed money to cover expenses is a good practice? apparently yes, if
* 		having access to credit in the first place means the firm is relatively mature.
* 		I kept the scores used in 2018 for the experiment.

replace financial_management_Q5_2018 = "1" if ///
	financial_management_Q5_2018 == "Não utilizo."
	
replace financial_management_Q5_2018 = "2" if ///
	financial_management_Q5_2018 == "Utilizo créditos de vez em quando."
	
replace financial_management_Q5_2018 = "3" if ///
	financial_management_Q5_2018 == "Utilizo créditos para cobrir despesas."

label define financial_management_Q5_2018 ///
		1		"Não utilizo."  ///
		2		"Utilizo créditos de vez em quando."  ///
		3		"Utilizo créditos para cobrir despesas."						
						
* Question 6

replace financial_management_Q6_2018 = "1" if ///
	financial_management_Q6_2018 == "Não realizo."
	
replace financial_management_Q6_2018 = "2" if ///
	financial_management_Q6_2018 == "Realizo análises mas não sei se faço da forma correta."

replace financial_management_Q6_2018 = "3" if ///
	financial_management_Q6_2018 == "Realizo análises com frequência."

label define financial_management_Q6_2018 ///
		1		"Não realizo."  ///
		2		"Realizo análises mas não sei se faço da forma correta." ///
		3		"Realizo análises com frequência."

* Question 7

replace financial_management_Q7_2018 = "1" if ///
	financial_management_Q7_2018 == "Não sei."

replace financial_management_Q7_2018 = "2" if ///
	financial_management_Q7_2018 == "Faço uma previsão, mas não sei se faço de forma correta."
	
replace financial_management_Q7_2018 = "3" if ///
	financial_management_Q7_2018 == "Sei qual a necessidade de capital de giro."

label define financial_management_Q7_2018 ///
		1		"Não sei."  ///
		2		"Faço uma previsão, mas não sei se faço de forma correta."  ///
		3		"Sei qual a necessidade de capital de giro."

* Question 8

replace financial_management_Q8_2018 = "1" if /// 
	financial_management_Q8_2018 == "Não realizo nenhum controle."
	
replace financial_management_Q8_2018 = "2" if ///
	financial_management_Q8_2018 == "Controlo meu estoque de maneira informal ou desestruturada."
	
replace financial_management_Q8_2018 = "3" if ///
	financial_management_Q8_2018 == "Controlo meu estoque por meio de métodos ou sistemas estruturados. Não possuo estoques."

label define financial_management_Q8_2018 ///
		1		"Não realizo nenhum controle." ///
		2		"Controlo meu estoque de maneira informal ou desestruturada." ///
		3		"Controlo meu estoque por meio de métodos ou sistemas estruturados. Não possuo estoques."

* Question 9

replace financial_management_Q9_2018 = "1" if ///
	financial_management_Q9_2018 == "Não possuo."
	
replace financial_management_Q9_2018 = "2" if ///
	financial_management_Q9_2018 == "Possuo, mas tenho dúvidas quanto à forma."

replace financial_management_Q9_2018 = "3" if ///
	financial_management_Q9_2018 == "Possuo controles por meio de planilhas robustas e/ou sistema. "
	
label define financial_management_Q9_2018 ///
 		1		"Não possuo."  ///
		2		"Possuo, mas tenho dúvidas quanto à forma." ///
		3		"Possuo controles por meio de planilhas robustas e/ou sistema."

* Question 10
						
replace financial_management_Q10_2018 = "1" if ///
	financial_management_Q10_2018 ==	"Não sei."
	
replace financial_management_Q10_2018 = "2" if /// 
	financial_management_Q10_2018 ==	"Sei mas não sei se faço da forma correta."
	
replace financial_management_Q10_2018 = "3" if ///
	financial_management_Q10_2018 == "Tenho calculado."

label define financial_management_Q10_2018 ///
 		1		"Não sei."  ///
		2		"Sei mas não sei se faço da forma correta."  ///
		3		"Tenho calculado."

*-------------------------------------------------------------------------------
*** questions related to strategic planning ------------------------------------
*-------------------------------------------------------------------------------

* Question 1

replace strategic_planning_Q1_2018 = "1" if ///
	strategic_planning_Q1_2018 == "Não, nunca fiz estudos para isso. "
	
replace strategic_planning_Q1_2018 = "2" if ///
	strategic_planning_Q1_2018 == "Sim, mas não o considerei confiável. "
	
replace strategic_planning_Q1_2018 = "3" if ///
	strategic_planning_Q1_2018 == "Sim, quando abri a empresa"

label define strategic_planning_Q1_2018 ///
 		1		"Não, nunca fiz estudos para isso." ///
		2		"Sim, mas não o considerei confiável." ///
		3		"Sim, quando abri a empresa."

* Question 2

replace strategic_planning_Q2_2018 = "1" if ///
	strategic_planning_Q2_2018 == "Não possuo. "

replace strategic_planning_Q2_2018 = "2" if ///
	strategic_planning_Q2_2018 == "Possuo, mas parcialmente "
	
replace strategic_planning_Q2_2018 = "3" if ///
	strategic_planning_Q2_2018 == "Possuo."

label define strategic_planning_Q2_2018 ///
		1		"Possuo, mas parcialmente." ///
 		2		"Não possuo." ///
		3		"Possuo."

* Question 3

* It is not clear what the hierarchy between the answers should be. I believe it
* 		should be the other way around. Still, I kept the scores used in 2018 
*		for the experiment.

replace strategic_planning_Q3_2018 = "1" if ///
	strategic_planning_Q3_2018 == "Não tenho interesse ou já sei fazer a expansão ou reposicionamento."

replace strategic_planning_Q3_2018 = "2" if ///
	strategic_planning_Q3_2018 == "Já iniciei, mas de forma desestruturada."
	
replace strategic_planning_Q3_2018 = "3" if ///
	strategic_planning_Q3_2018 == "Tenho interesse, mas não sei como fazer."

label define strategic_planning_Q3_2018 ///
		1		"Não tenho interesse ou já sei fazer a expansão ou reposicionamento." ///
		2		"Já iniciei, mas de forma desestruturada." ///
		3		"Tenho interesse, mas não sei como fazer."

*-------------------------------------------------------------------------------
*** questions related to market intelligence -----------------------------------
*-------------------------------------------------------------------------------

* Question 1

replace market_intelligence_Q1_2018 = "1" if ///
	market_intelligence_Q1_2018 == "Não conheço."
	
replace market_intelligence_Q1_2018 = "2" if ///
	market_intelligence_Q1_2018 == "Já pesquisei, mas de forma informal e pouco estruturada."
	
replace market_intelligence_Q1_2018 = "3" if ///
	market_intelligence_Q1_2018 == "Conheço bem o meu cliente."

label define market_intelligence_Q1_2018 ///
		1		"Não conheço." ///
		2		"Já pesquisei, mas de forma informal e pouco estruturada." ///
		3		"Conheço bem o meu cliente."
						
* Question 2					

replace market_intelligence_Q2_2018 = "1" if ///
	market_intelligence_Q2_2018 ==	"Não conheço."
	
replace market_intelligence_Q2_2018 = "2" if ///
	market_intelligence_Q2_2018 ==	"Conheço mas não comparo todas as formas de atuação."
	
replace market_intelligence_Q2_2018 = "3" if ///
	market_intelligence_Q2_2018 ==	"Conheço."

label define market_intelligence_Q2_2018 ///
		1		"Não conheço." ///
		2		"Conheço mas não comparo todas as formas de atuação." ///
		3		"Conheço."

* Question 3

replace market_intelligence_Q3_2018 = "1" if ///
	market_intelligence_Q3_2018 == "Não analiso."

replace market_intelligence_Q3_2018 = "2" if ///
	market_intelligence_Q3_2018 == "Analiso, mas não comparo."
	
replace market_intelligence_Q3_2018 = "3" if ///
	market_intelligence_Q3_2018 == "Analiso e faço as comparações."
	
label define market_intelligence_Q3_2018 ///
		1		"Não analiso." ///
		2		"Analiso, mas não comparo." ///
		3		"Analiso e faço as comparações."

* Question 4

replace market_intelligence_Q4_2018 = "1" if ///
	market_intelligence_Q4_2018 == "Não possui."
	
replace market_intelligence_Q4_2018 = "2" if ///
	market_intelligence_Q4_2018 == "Possui um cadastro dos clientes, mas considera este incompleto/desatualizado ou não é utilizado."

replace market_intelligence_Q4_2018 = "3" if ///
	market_intelligence_Q4_2018 == "Possui cadastro e utiliza."

label define market_intelligence_Q4_2018 ///
		1		"Não possui." ///
		2		"Possui um cadastro dos clientes, mas considera este incompleto/desatualizado ou não é utilizado." ///
		3		"Possui cadastro e utiliza."

* Question 5

replace market_intelligence_Q5_2018 = "1" if ///
	market_intelligence_Q5_2018 == "Não sei."

replace market_intelligence_Q5_2018 = "2" if ///
	market_intelligence_Q5_2018 == "Sei, mas não acompanho de forma estruturada."
	
replace market_intelligence_Q5_2018 = "3" if ///
	market_intelligence_Q5_2018 == "Sei e faço o acompanhamento."

label define market_intelligence_Q5_2018 ///
		1		"Não sei." ///
		2		"Sei, mas não acompanho de forma estruturada." ///
		3		"Sei e faço o acompanhamento."

* Question 6

replace market_intelligence_Q6_2018 = "1" if ///
	market_intelligence_Q6_2018 == "Não busco."
	
replace market_intelligence_Q6_2018 = "2" if ///
	market_intelligence_Q6_2018 == "Acompanho de forma superficial."
	
replace market_intelligence_Q6_2018 = "3" if ///
	market_intelligence_Q6_2018 == "Busco constantemente."

label define market_intelligence_Q6_2018 ///
		1		"Não busco." ///
		2		"Acompanho de forma superficial."	///
		3		"Busco constantemente."

*-------------------------------------------------------------------------------
*** questions related to marketing ---------------------------------------------
*-------------------------------------------------------------------------------

* Question 1

replace marketing_Q1_2018 = "1" if ///
	marketing_Q1_2018 ==	"Não realizo."

replace marketing_Q1_2018 = "2" if ///
	marketing_Q1_2018 ==	"Realizo, mas não sei se faço da forma correta."
	
replace marketing_Q1_2018 = "3" if ///
	marketing_Q1_2018 ==	"Realizo. "

label define marketing_Q1_2018 ///
		1		"Não realizo." ///
		2		"Realizo, mas não sei se faço da forma correta." ///
		3		"Realizo."
		
* Question 2						

replace marketing_Q2_2018 = "1" if ///
	marketing_Q2_2018 ==	"Não possui."
	
replace marketing_Q2_2018 = "2" if ///
	marketing_Q2_2018 ==	"Já iniciei, mas estou com dificuldades."
	
replace marketing_Q2 = "3" if ///
	marketing_Q2 ==	"Possui."

label define marketing_Q2_2018 ///
		1		"Não possui." ///
		2		"Já iniciei, mas estou com dificuldades." ///
		3		"Possui."

* Question 3

replace marketing_Q3_2018 = "1" if ///
	marketing_Q3_2018 ==	"Não realizo nenhuma análise da demanda."
	
replace marketing_Q3_2018 = "2" if ///
	marketing_Q3_2018 ==	"Faço a análise mas não sei se é de forma correta."

replace marketing_Q3_2018 = "3" if ///
	marketing_Q3_2018 ==	"Realizo e analiso a demanda."

label define marketing_Q3_2018 /// 	
		1		"Não realizo nenhuma análise da demanda." ///
		2		"Faço a análise mas não sei se é de forma correta."  ///
		3		"Realizo e analiso a demanda."

* Question 4

replace marketing_Q4_2018 = "1" if ///
	marketing_Q4_2018 ==	"Não possuo "
	
replace marketing_Q4_2018 = "2" if ///
	marketing_Q4_2018 ==	"Possuo, mas utilizo de forma parcial "
	
replace marketing_Q4_2018 = "3" if ///
	marketing_Q4_2018 ==	"Possuo"

label define marketing_Q4_2018 ///
		1		"Não possuo" ///
		2		"Possuo, mas utilizo de forma parcial" ///
		3		"Possuo"

* Question 5

replace marketing_Q5_2018 = "1" if ///
	marketing_Q5_2018 ==	"Não sei."
	
replace marketing_Q5_2018 = "2" if ///
	marketing_Q5_2018 ==	"Sei, mas não sei se faço da forma correta."
	
replace marketing_Q5_2018 = "3" if ///
	marketing_Q5_2018 ==	"Sei e analiso."

label define marketing_Q5_2018 ///
		1		"Não sei." ///
		2		"Sei, mas não sei se faço da forma correta." ///
		3		"Sei e analiso."

* Question 6

replace marketing_Q6_2018 = "1" if ///
	marketing_Q6_2018 ==	"Não possuo."
	
replace marketing_Q6_2018 = "2" if ///
	marketing_Q6_2018 ==	"Possuo, mas não sei se faço da forma correta."
	
replace marketing_Q6_2018 = "3" if ///
	marketing_Q6_2018 ==	"Possuo."

label define marketing_Q6_2018 ///
		1		"Não possuo." ///
		2		"Possuo, mas não sei se faço da forma correta." ///
		3		"Possuo."

* Question 7

replace marketing_Q7_2018 = "1" if ///
	marketing_Q7_2018 ==	"Não realizo."
	
replace marketing_Q7_2018 = "2" if ///
	marketing_Q7_2018 ==	"Realizo, mas não sei se é da forma correta."
	
replace marketing_Q7_2018 = "3" if ///
	marketing_Q7_2018 ==	"Realizo."

label define marketing_Q7_2018 ///
		1		"Não realizo." ///
		2		"Realizo, mas não sei se é da forma correta." ///
		3		"Realizo."

* Question 8

replace marketing_Q8_2018 = "1" if ///
	marketing_Q8_2018 ==	"Não possuo."
	
replace marketing_Q8_2018 = "2" if ///
	marketing_Q8_2018 ==	"Possuo mas desestruturado."
	
replace marketing_Q8_2018 = "3" if ///
	marketing_Q8_2018 ==	"Possuo."

label define marketing_Q8_2018 ///
		1		"Não possuo." ///
		2		"Possuo mas desestruturado." ///
		3		"Possuo."

* Question 9
				
replace marketing_Q9_2018 = "1" if ///
	marketing_Q9_2018 ==	"Não busco novos canais nem parcerias."
	
replace marketing_Q9_2018 = "2" if ///
	marketing_Q9_2018 ==	"Busco novos canais e parcerias, mas sem sucesso."
	
replace marketing_Q9_2018 = "3" if ///
	marketing_Q9_2018 ==	"Sim, desenvolvo novos canais. "

label define marketing_Q9_2018 ///
		1		"Não busco novos canais nem parcerias." ///
		2		"Busco novos canais e parcerias, mas sem sucesso." ///
		3		"Sim, desenvolvo novos canais."

*-------------------------------------------------------------------------------
*** turning the string variables in the survey into numeric variables ----------
*-------------------------------------------------------------------------------

foreach var of varlist *_Q* {
	
	destring `var', replace
	
	label values `var' `var'

}

*-------------------------------------------------------------------------------
*** reordering the variables in the database -----------------------------------
*-------------------------------------------------------------------------------

order firm_id firm_name_2018 years_functioning_2018 date_opening_2018 ///
		business_activity_code_2018 ///
		sector_IBGE_2018 size_2018 firm_zipcode_2018 firm_neighborhood_2018 ///
		firm_city_2018 firm_state_2018 ///
		interview_starttime_2018 interview_endtime_2018 interviewer_name_2018 ///
		sebrae_regional_office_2018 respondent_name_2018 respondent_gender_2018 ///
		respondent_type_2018 ///
		respondent_age_2018 respondent_date_birth_2018 respondent_zipcode_2018 ///
		respondent_sec_address_info_2018 respondent_neighborhood_2018 ///
		respondent_city_2018 ///
		respondent_state_2018 sebrae_action_2018 date_actionplan1_2018 ///
		action_plan1_2018 ///
		date_actionplan2_2018 action_plan2_2018 date_actionplan3_2018 action_plan3_2018

*===============================================================================
*	Part 4: Creating new variables to measure maturity
*===============================================================================

* Sebrae classifies each practice in three levels of maturity: basic, 
* 		intermediary and advanced. We'll create our own assessment using a 
* 		dummy which indicates the advanced level.

*-------------------------------------------------------------------------------
*** creating the dummies for each question in the survey -----------------------
*-------------------------------------------------------------------------------

foreach var of varlist *_Q* {
		
	generate	d_`var' = 1 if `var' == 3
	replace 	d_`var' = 0 if `var' < 3
	
}

*-------------------------------------------------------------------------------	
*** creating the first global index of business practices ----------------------
*-------------------------------------------------------------------------------

* the first index will be the mean of all dummies created earlier

	egen business_practices_mean_2018 = ///
	rowmean(d_financial_management_Q1_2018		///
			d_financial_management_Q2_2018		///
			d_financial_management_Q3_2018		///
			d_financial_management_Q4_2018	///
			d_financial_management_Q6_2018		///
			d_financial_management_Q7_2018		///
			d_financial_management_Q9_2018		///
			d_financial_management_Q10_2018	///	questions 5 and 8 on financial management are not included in the index (must check why)
			d_market_intelligence_Q1_2018		///
			d_market_intelligence_Q2_2018		///
			d_market_intelligence_Q3_2018		///	
			d_market_intelligence_Q4_2018		///
			d_market_intelligence_Q5_2018		///
			d_market_intelligence_Q6_2018		///
			d_marketing_Q1_2018		///
			d_marketing_Q2_2018		///
			d_marketing_Q3_2018		///
			d_marketing_Q5_2018		///
			d_marketing_Q6_2018		///
			d_marketing_Q7_2018		///
			d_marketing_Q8_2018		///
			d_marketing_Q9_2018		/// question 4 on marketing is not included in the index (must check why). probably because it was not asked in previous editions of the SSE program.
			d_strategic_planning_Q1_2018) // questions 2 and 3 on strategic planning are not included (must check why). only question 2 was missing from previous editions of the SSE.

*-------------------------------------------------------------------------------	
*** creating the second global index of business practices ---------------------
*-------------------------------------------------------------------------------

* the second index will be the sum of all dummies created earlier

	egen business_practices_sum_2018 = ///
	rowtotal(d_financial_management_Q1_2018		///
			d_financial_management_Q2_2018		///
			d_financial_management_Q3_2018		///
			d_financial_management_Q4_2018		///
			d_financial_management_Q6_2018		///
			d_financial_management_Q7_2018		///
			d_financial_management_Q9_2018		///
			d_financial_management_Q10_2018	///	questions 5 and 8 on financial management are not included in the index (must check why)
			d_market_intelligence_Q1_2018		///
			d_market_intelligence_Q2_2018		///
			d_market_intelligence_Q3_2018		///	
			d_market_intelligence_Q4_2018		///
			d_market_intelligence_Q5_2018		///
			d_market_intelligence_Q6_2018		///
			d_marketing_Q1_2018		///
			d_marketing_Q2_2018		///
			d_marketing_Q3_2018		///
			d_marketing_Q5_2018		///
			d_marketing_Q6_2018		///
			d_marketing_Q7_2018		///
			d_marketing_Q8_2018		///
			d_marketing_Q9_2018		/// question 4 on marketing is not included in the index (must check why). probably because it was not asked in previous editions of the SSE program.
			d_strategic_planning_Q1_2018) // questions 2 and 3 on strategic planning are not included (must check why). only question 2 was missing from previous editions of the SSE.

*-------------------------------------------------------------------------------	
*** creating the third global index of business practices ----------------------
*-------------------------------------------------------------------------------										
* the third index will create categories for the second index

		generate		business_practices_scale_2018 = .
		replace 		business_practices_scale_2018 = 1 if ///
			business_practices_scale_2018 == . & business_practices_sum_2018 <=4
						
		replace 		business_practices_scale_2018 = 2 if ///
			business_practices_scale_2018 == . & business_practices_sum_2018 <=8
			
		replace 		business_practices_scale_2018 = 3 if ///
			business_practices_scale_2018 == . & business_practices_sum_2018 <=13
			
		replace 		business_practices_scale_2018 = 4 if ///
			business_practices_scale_2018 == . & business_practices_sum_2018 <=18
			
		replace 		business_practices_scale_2018 = 5 if ///
			business_practices_scale_2018 == . & business_practices_sum_2018 <=23
		
		label define business_practices_scale_2018 ///
						1 "Até 4 práticas" ///
						2 "De 5 a 8 práticas" ///
						3 "De 9 a 13 práticas" ///
						4 "De 14 a 18 práticas" ///
						5 "De 19 a 23 práticas"
						
		label values business_practices_scale_2018 business_practices_scale_2018

*===============================================================================
*	Part 5: Checking for firms that are repeated in the database
*===============================================================================

* checking for duplicated entries

duplicates report firm_id interview_starttime_2018 interview_endtime_2018 ///
			interviewer_name_2018 business_practices_sum_2018
	
duplicates drop firm_id interview_starttime_2018 interview_endtime_2018 ///
			interviewer_name_2018 business_practices_sum_2018, force
	
* checking if the firm ID is unique

bysort firm_id: g n_rep = cond(_N==1,0,_n)

tabulate n_rep // after eliminating duplicated entries, repeated firms appear only twice

* identifying cases of repetead firm ID

g repeated_firm_sse_2018 = 1 if n_rep > 0

replace repeated_firm_sse_2018 = 0 if repeated_firm_sse_2018 == .

* handling cases when different people answered for the same firm

bysort firm_id: g different_respondents = 1 if ///
					respondent_type_2018[1]!=respondent_type_2018[2]

drop if repeated_firm_sse_2018 == 1 & different_respondents == 1 & respondent_type_2018 == 5 // if repeated, keep the manager's opinion

* keeping the most recent interview

bysort firm_id (interview_starttime_2018): g interview_round = cond(_N==1,0,_n)
drop if interview_round == 1

* after eliminating repeated firms, drop the useless variables

drop n_rep interview_round different_respondents

*===============================================================================
*	Part 6: Saving the product of this code (SSE 2018 database)
*===============================================================================

save "Experiment/Output/output_code_01a_sse_2018.dta", replace 
