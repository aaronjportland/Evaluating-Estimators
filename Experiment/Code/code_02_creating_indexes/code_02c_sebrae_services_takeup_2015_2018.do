********************************************************************************
* Date: 10/06/2023
* Author: Gabriela Monteiro Avelino
*
*			Code 01f: Cleaning Sebrae's database of clients from 2015 to 2018
*
*===============================================================================
*	Part 0: Settings
*===============================================================================

* setting the work directory

	cd "/Users/aaronjoseph/Downloads/Capstone/Felipe"	
	
* importing Sebrae's database of people interviewed in the 2018 edition of the 
* 		SSE program

	use "Experiment/Data/Sebrae Services.dta", clear

*===============================================================================
*	Part 1: Classifying the types of services offered by Sebrae
*===============================================================================

* renaming variables

	rename				CNPJ		firm_id
	label variable		firm_id		"Taxpayer number (CNPJ)"
	
* listing existing value labels for Sebrae's services

	label list sebrae_service

* creating a broader category of services

	g service_type = "Consulting" if sebrae_service == 2 | sebrae_service == 3
	
	replace service_type = "Course" if sebrae_service == 4 | sebrae_service == 5
	
	replace service_type = "Information" if sebrae_service == 7 | sebrae_service == 8
	
	replace service_type = "Workshop" if sebrae_service == 10
	
	replace service_type = "TechnicalGuidance" if sebrae_service == 11 | sebrae_service == 12 | sebrae_service == 13 | sebrae_service == 14 
	
	replace service_type = "Seminar" if sebrae_service == 15
	
	replace service_type = "Seminar" if service == "" // don't understand why every other type of service was classified as "seminar" 
	
* specifying whether the service was offered in person or remotely

	g type_interaction = "Remotely" if sebrae_service == 3 | sebrae_service == 5 | sebrae_service == 8 | sebrae_service == 12
	
	replace type_interaction = "InPerson" if type == ""

*===============================================================================
*	Part 2: Creating summary variables to measure service take-up
*===============================================================================

* creating a dummy for each combination of service type, year and type of interaction

	forvalues year = 2015/2018 {
		
		foreach service in "Consulting" "Course" "Information" "Workshop" ///
		"TechnicalGuidance" "Seminar" {
		
			foreach interaction in "InPerson" "Remotely" {
		
				bysort firm_id: gen `service'_`interaction'_`year' = 1 if ///
				service == "`service'" & type =="`interaction'" & ///
				year_service ==`year'

	}

	}

	}

* creating a dummy for each year

	forvalues year = 2015/2018 {
		
		bysort firm_id: gen total_services_`year' = 1 if year_service == `year'
		
	}

* creating a dummy for each year and type of interaction

	forvalues year = 2015/2018 {
		
		foreach interaction in "InPerson" "Remotely" {
			
			bysort firm_id: gen total_services_`interaction'_`year' = 1 if ///
			year_service ==`year' & type_interaction == "`interaction'"
	}
	
	}

* aggregating results per firm
	
	collapse (sum) Consulting_InPerson_2015 - total_services_2018, by(firm_id)

	g total_services_2015_2018 = total_services_2015 + total_services_2016 + ///
									total_services_2017 + total_services_2018

* creating categories for service take-up

	g		total_services_level = 1 if ///
			total_services_2015_2018 >= 1 & total_services_2015_2018 <= 5
			
	replace total_services_level = 2 if ///
			total_services_2015_2018 >= 6 & total_services_2015_2018 <= 10
	
	replace total_services_level = 3 if ///
			total_services_2015_2018 >= 11 & total_services_2015_2018 <= 20
	
	replace total_services_level = 4 if ///
			total_services_2015_2018 >= 21 & total_services_2015_2018 <= 30
	
	replace total_services_level = 5 if ///
			total_services_2015_2018 >= 31 & total_services_2015_2018 <= 40
	
	replace total_services_level = 6 if ///
			total_services_2015_2018 >= 41 & total_services_2015_2018 <= 50
	
	replace total_services_level = 7 if ///
			total_services_2015_2018 >= 51

label define total_services_level	 	1 "From 1 to 5 services"	///
										2 "From 6 to 10 services"	///
										3 "From 11 to 20 services" ///
										4 "From 21 to 30 services" ///
										5 "From 31 to 40 services" ///
										6 "From 41 to 50 services" ///
										7 "More than 50 services"

label values total_services_level total_services_level

*===============================================================================
*	Part 3: Saving the output of this code
*===============================================================================

save "Experiment/Output/output_code_02c_sebrae_services_takeup.dta", replace
