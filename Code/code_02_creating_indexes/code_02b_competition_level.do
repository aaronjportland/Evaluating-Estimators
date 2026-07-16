********************************************************************************
* Date: 02/06/2023
* Author: Gabriela Monteiro Avelino
*
*		Code 02b: Creating competition/density variable using the all the firms 
*					on the 2016 RAIS dataset. This will be used to stratify 
*					firms on competition levels. 
*
*===============================================================================
*	Part 0: Settings
*===============================================================================

* setting the work directory

	cd "/Users/aaronjoseph/Downloads/Capstone/Felipe"
	
* importing 2016 RAIS database. Each observation is a firm, but there is no firm
*		ID (data is de-identified)

	use "Experiment/Data/rais_2016_not_ID.dta", clear

*===============================================================================
*	Part 1: Matching RAIS 2016 with SSE region/sector combinations
*===============================================================================

* adding region/sector combinations (CEP-CNAEs) that were found in SSE, but not in RAIS

/*
Each observation in the "using" database is a firm found in SSE, but there is no
firm ID (data is de-identified). We will merge m:m to keep track of how many
observations are found in each database (RAIS and SSE).
*/

	merge m:m		CEP CNAE		using "Experiment/Data/cnae_cep_SSE.dta"
	
* renaming variables

	rename			CEP							zipcode
	label variable	zipcode						"CEP"
	
	rename			CNAE						business_activity_code
	label variable	business_activity_code		"CNAE"
	
	rename			setor_sebrae				sebrae_strategic_business_sector
	
	rename			ibge_subsector				business_subsector_IBGE
	label variable	business_subsector_IBGE		"Business subsector, according to IBGE's definition"

* creating sector variable (it will be the same as Sebrae's definition of business
*		sectors, except when Sebrae's sector == other, in which case we will use
*		IBGE's definition)

	g				business_sector = sebrae_strategic_business_sector
	label variable	business_sector	"Sebrae's strategic sector, combined with IBGE's definition when sector == other"
	
	replace 		business_sector = 10 + business_subsector_IBGE ///
					if sebrae_strategic_business_sector == 6

	label define 	business_sector ///
					1 "Alimentos" ///
					2 "Base Tecnológica" ///
					3 "Construção Civil" ///
					4 "Economia Criativa" ///
					5 "Moda" ///
					7 "Petróleo e Gás" ///
					8 "Saúde, Bem Estar e Beleza" ///
					9 "Setor Financeiro" ///
					10 "Turismo" ///
					11 "Extrativa mineral" ///
					12 "Indústria de produtos minerais não metálicos" ///
					13 "Indústria metalúrgica" ///
					14 "Indústria mecânica" ///
					15 "Indústria do material elétrico e de comunicações" ///
					16 "Indústria do material de transporte" ///
					17 "Indústria da madeira e do mobiliário" ///
					18 "Indústria do papel, papelão, editorial e gráfica" ///
					19 "Ind. da borracha, fumo, couros, peles, similares, ind. diversas" ///
					20 "Ind. química de produtos farmacêuticos, veterinários, perfumaria" ///
					21 "Indústria têxtil do vestuário e artefatos de tecidos" ///
					22 "Indústria de calçados" ///
					23 "Indústria de produtos alimentícios, bebidas e álcool etílico" ///
					24 "Serviços industriais de utilidade pública" ///
					25 "Construção civil" ///
					26 "Comércio varejista" ///
					27 "Comércio atacadista" ///
					28 "Instituições de crédito, seguros e capitalização" ///
					29 "Com. e administração de imóveis, valores mobiliários, serv. Técnico" ///
					30 "Transportes e comunicações" ///
					31 "Serv. de alojamento, alimentação, reparação, manutenção, redação" ///
					32 "Serviços médicos, odontológicos e veterinários" ///
					33 "Ensino" ///
					34 "Administração pública direta e autárquica" ///
					35 "Agricultura, silvicultura, criação de animais, extrativismo vegetal"
							
	label values 	business_sector business_sector
	
/*

* saving sector variables and their respective business activity codes (CNAEs)
*		(this will be an input to later codes)

	keep 			business_activity_code business_sector
	duplicates drop
	drop if business_sector == .
	rename			business_activity_code		CNAE
	label variable	CNAE						"Business activity code"
	save 			"Experiment\Data\business_code_sector.dta", replace

*/
	
*===============================================================================
*	Part 2: Creating density variable for each region/sector combination
*===============================================================================	
* to run this part, you will need to re-run lines 20 to 95

* creating competition variable

	g 				competition_density = 1
	
* creating the broad region within which competition will be measured

	g 				broad_zipcode = floor(zipcode/1000)
	label variable	broad_zipcode "Only the first 5 digits of the zipcode"
	
	sort			zipcode business_activity_code
	order			zipcode business_activity_code
	
*-------------------------------------------------------------------------------
*** first measure of competition -----------------------------------------------
*------------------------------------------------------------------------------- 
	
* number of firms per full zipcode and business activity code

	collapse 		(sum) competition_density (first) broad_zipcode, ///
					by(zipcode business_activity_code)
					
	order			zipcode business_activity_code
					
	save 			"Experiment\Data\competition_full_zipcode.dta", replace

*-------------------------------------------------------------------------------
*** second measure of competition -----------------------------------------------
*------------------------------------------------------------------------------- 

* number of firms per broad zipcode and business activity code

	collapse (sum) 	competition_density, by(broad_zipcode business_activity_code)
	
	sort			broad_zipcode business_activity_code
	order			broad_zipcode business_activity_code
	
	rename 			competition_density competition_density_broad_zipco
	label variable	competition_density_broad_zipco	"Number of firms with same business activity code and first 5 digits of zipcode"

* merging with the first measure of competition

	merge 1:m 		broad_zipcode business_activity_code ///
					using "Experiment\Data\competition_full_zipcode.dta"

* organizing database	
				
	rename			competition_density competition_density_full_zipco
	label variable	competition_density_full_zipco	"Number of firms with same business activity code and zipcode"
	
	label variable	broad_zipcode	"First 5 digits of the zipcode (CEP)"
	sort			zipcode business_activity_code
	drop 			_merge
	order			broad_zipcode zipcode business_activity_code
	
	save "Experiment/Output/output_code_02b_competition_level.dta", replace
