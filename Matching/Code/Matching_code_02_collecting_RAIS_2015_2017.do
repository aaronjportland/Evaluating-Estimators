********************************************************************************
* Date: 02/10/2023
* Author: Gabriela Monteiro Avelino
*
*	Code 02: Collecting additional RAIS information (from 2015 and 2017) for everyone
*		in the experimental sample (4,051 firms) and the comparison group (1,188 firms) 
*
*===============================================================================
*	Part 0: Settings
*===============================================================================

* setting the work directory

	cd "/Users/aaronjoseph/Downloads/Capstone/Felipe"
	
*===============================================================================
*	Part 1: Importing RAIS 2015
*===============================================================================
	
	clear all
	
	import delimited using "E:/EESP-01/RAIS_IDENTIFICADA/2015/ESTB2015ID.txt", ///
							delimiters(";")

* changing the name of the variables
	
	rename cnpjcei firm_id
	format firm_id %20.0g
	rename qtdvínculosativos number_employees_RAIS_2015 

* keeping only the relevant information

	keep firm_id number_employees_RAIS_2015 

* saving the dataset

	save "RAIS_2015.dta", replace
	
*===============================================================================
*	Part 2: Merging with the list of firms obtained from code 01 (5,239 firms)
*===============================================================================
	
	clear all
	
	import excel "firms_matching.xlsx", firstrow
	
	format firm_id %20.0g
	
	merge 1:m firm_id using "RAIS_2015.dta", gen(merge_RAIS_2015) keep(match master)

* there is one case of a firm with more than one appearance in RAIS 2015

	duplicates list firm_id

* since the information on number of employees is not the same in each of the
* 		appearances, I will report it as missing

	duplicates drop firm_id, force
	
	replace number_employees_RAIS_2015 = . if firm_id == 13671158000135
	replace merge_RAIS_2015 = 1 if firm_id == 13671158000135
	
	tab number_employees_RAIS_2015, missing
	
	save "firms_matching_RAIS_2015.dta", replace
	
*===============================================================================
*	Part 3: Importing RAIS 2017
*===============================================================================

* importing the first file

	clear all
	
	import delimited using "E:/EESP-01/RAIS_IDENTIFICADA/2017/ESTB2017ID.txt", ///
							delimiters(";")

* changing the name of the variables
	
	rename cnpjcei firm_id
	format firm_id %20.0g
	rename qtdvínculosativos number_employees_RAIS_2017 

* keeping only the relevant information

	keep firm_id number_employees_RAIS_2017 

* saving the dataset

	save "RAIS_2017_part1.dta", replace
	
* importing the second file

	clear all
	
	import delimited using "E:/EESP-01/RAIS_IDENTIFICADA/2017/ESTB2017ID-other.txt", ///
							delimiters(";")

* changing the name of the variables
	
	rename cnpjcei firm_id
	format firm_id %20.0g
	rename qtdvínculosativos number_employees_RAIS_2017 

* keeping only the relevant information

	keep firm_id number_employees_RAIS_2017 

* combining both datasets from 2017

	append using "RAIS_2017_part1.dta"

	duplicates drop
	
* saving the dataset

	save "RAIS_2017.dta", replace
	
*===============================================================================
*	Part 4: Merging with the list of firms used for matching
*===============================================================================
	
	clear all
	
	use "firms_matching_RAIS_2015.dta"
	
	merge 1:m firm_id using "RAIS_2017.dta", gen(merge_RAIS_2017) keep(match master)

* there are two cases of firms with more than one appearance in RAIS 2017

	duplicates list firm_id

* since the information on number of employees is not the same in each of the
* 		appearances, I will report it as missing

	duplicates drop firm_id, force
	
	replace number_employees_RAIS_2017 = . if firm_id ==  13671158000135 ///
											| firm_id == 7073022000120

	replace merge_RAIS_2017 = 1 if firm_id ==  13671158000135 ///
									| firm_id == 7073022000120
	
	
	tab number_employees_RAIS_2017, missing
	
	save "firms_matching_RAIS_2015_2017.dta", replace
