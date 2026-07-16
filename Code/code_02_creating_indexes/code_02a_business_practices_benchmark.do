********************************************************************************
* Date: 01/06/2023
* Author: Gabriela Monteiro Avelino
*
*	Code 02a: Creating business practices benchmark values using SSE 2015-2017
*
*===============================================================================
*	Part 0: Settings
*===============================================================================

* setting the work directory

	cd "/Users/aaronjoseph/Downloads/Capstone/Felipe"
	
* importing Sebrae's cleaned database of SSE 2015

	use "Experiment\Output\output_code_01c_sse_2015.dta", clear

	/* 	Create business practices benchmark values.  Reference groups: sebrae's 
	strategic groups and local competitors	
	
	Since we have bp data on only 12,000 firms for SSE 2017, we'll have very 
	little info	within CEP x sector clusters, maybe we can think on a broader 
	geographic	level such as the first 5 digits of the CEP code. The CEP number
	consists on 8 digits, but the first 5 indicates the	"subsector division".
	
	Also, instead of focusing only on the SSE 2017 we can use data gathered on 
	the SSE 2015 and SSE 2016 as well.
	*/
	
*===============================================================================
*	Part 1: Merge SSE 2015 with subsequent editions of the program (2016 and 2017)
*===============================================================================	

/*
Since each firm appears only once in each database, we can merge 1:1.

Questions were the same in all 3 editions of the program, so we can keep the 
value labels from the master dataset (2015).

The only variable in all 3 databases not identified by year is the firm ID, 
which is the one that remains constant across time, by definition. The other
variables (including address and business activity) could have changed between 
interviews, so they are indexed by the year in which they were collected, so they
wouldn't be lost in the merge.

*/

	merge 1:1 firm_id using "Experiment\Output\output_code_01d_sse_2016.dta", gen(merge15_16)

* from the universe of 18,609 + 12,369 - 3,129 = 27,849 unique firms interviewed in 2015 and
*		2016, only 3,129 were interviewed in both editions (11%)

	merge 1:1 firm_id using "Experiment\Output\output_code_01f_sse_2017.dta", gen(merge15_16_17)

* identifying the results from the merge

	generate byte 		SSE_editions =.
	label variable		SSE_editions	"Firm participation in multiple editions of the SSE program"

	replace		SSE_editions = 1 if	(merge15_16 == 1 & merge15_16_17 == 1 & SSE_editions ==.)
	replace		SSE_editions = 2 if	(merge15_16 == 2 & merge15_16_17 == 1 & SSE_editions ==.)
	replace		SSE_editions = 3 if	(merge15_16_17 == 2 & SSE_editions ==.)
	replace		SSE_editions = 4 if	(merge15_16 == 3 & merge15_16_17 == 1 & SSE_editions ==.)
	replace		SSE_editions = 5 if	(merge15_16 == 1 & merge15_16_17 == 3 & SSE_editions ==.)
	replace		SSE_editions = 6 if	(merge15_16 == 2 & merge15_16_17 == 3 & SSE_editions ==.)
	replace		SSE_editions = 7 if	(merge15_16 == 3 & merge15_16_17 == 3 & SSE_editions ==.)

	label define	SSE_editions ///
					1 "Firm interviewed only in 2015" ///
					2 "Firm interviewed only in 2016" ///
					3 "Firm interviewed only in 2017" ///
					4 "Firm interviewed in 2015 and 2016, but not in 2017" ///
					5 "Firm interviewed in 2015 and 2017, but not in 2016" ///
					6 "Firm interviewed in 2016 and 2017, but not in 2015" ///
					7 "Firm interviewed in 2015, 2016 and 2017"
				
	label values	SSE_editions SSE_editions

* dropping useless variables

	drop merge15_16 merge15_16_17

*===============================================================================
*	Part 2: Identifying firms in the strategic sectors prioritized by Sebrae
*===============================================================================	

/*
Must confirm that this was in fact the goal of this section of the code.

Here we use the database which contains the business activity codes (CNAEs) that 
are part of Sebrae's strategic sectors (must confirm that this is in fact the 
content of the database).

In the experiment, the business activity code that was used is the earlier one
(from the first interview). I will replicate what was previously done, but we 
should consider using the most recent one (from the latest interview).
*/

* generating the identifier to merge with

	generate 	CNAE =.
	replace		CNAE = business_activity_code_2015 if SSE_editions == 1
	replace		CNAE = business_activity_code_2016 if SSE_editions == 2
	replace		CNAE = business_activity_code_2017 if SSE_editions == 3
	replace		CNAE = business_activity_code_2015 if SSE_editions == 4
	replace		CNAE = business_activity_code_2015 if SSE_editions == 5
	replace		CNAE = business_activity_code_2016 if SSE_editions == 6
	replace		CNAE = business_activity_code_2015 if SSE_editions == 7

	label variable	CNAE "CNAE of the firm, as reported in the first interview"

* merging with Sebrae's database of strategic sectors

	merge m:1 CNAE using "Experiment/Data/cnae_sebrae", gen(sebrae_priority)

* dropping business activity codes that are considered strategic by Sebrae but
*		were not used by any firm interviewed in the SSE from 2015 to 2017

	rename			CNAE							business_activity_code
	drop if 		sebrae_priority == 2 

* identifying the results from the merge

	label variable 	sebrae_priority					"Is the business activity part of the strategic sectors prioritized by Sebrae?"

	recode 			sebrae_priority 				(3=1) (1=0)

	label define 	sebrae_priority ///
					0 "No" ///
					1 "Yes"
					
	label values 	sebrae_priority sebrae_priority
	
* renaming the new columns brought by the merge

	encode 			setor_estrategico_sebrae, 			g(sebrae_strategic_business_sector)
	drop 			setor_estrategico_sebrae
	label variable	sebrae_strategic_business_sector	"Sebrae's strategic sector to which the CNAE from first interview corresponds"
	
	replace			sebrae_strategic_business_sector = 0 if sebrae_strategic_business_sector ==.
	label define	sebrae_strategic_business_sector 0 "Activity not considered strategic by Sebrae", add
	label values 	sebrae_strategic_business_sector sebrae_strategic_business_sector

	rename			cnae_descricao						business_activity_code_descript
	label variable	business_activity_code_descript 	"Description of the CNAE reported in the first interview"

	rename			cnae_secao							business_activity_code_section
	label variable	business_activity_code_section 		"Section to which the CNAE reported in the first interview belongs to"

	rename			cnae_divisao						business_activity_code_division
	label variable	business_activity_code_division 	"Division to which the CNAE reported in the first interview belongs to"

	rename			cnae_classe							business_activity_code_class
	label variable	business_activity_code_class 		"Class to which the CNAE reported in the first interview belongs to"

	rename			cnae_grupo							business_activity_code_group
	label variable	business_activity_code_group 		"Group to which the CNAE reported in the first interview belongs to"
		
*===============================================================================
*	Part 3: Creating the business practices benchmark values
*===============================================================================	

*-------------------------------------------------------------------------------
*** benchmarking within region and sector --------------------------------------
*-------------------------------------------------------------------------------

* if a firm was surveyed in multiple occasions, use the most recent one

	g 			business_practices_sum = business_practices_sum_2017
	
	replace 	business_practices_sum = business_practices_sum_2016 if ///
				business_practices_sum ==.
				
	replace 	business_practices_sum = business_practices_sum_2015 if ///
				business_practices_sum ==. 

	label variable	business_practices_sum "Number of advanced practices adopted, as reported in the most recent interview"

	g 			business_practices_scale =.

	replace 	business_practices_scale = 1 if ///
				business_practices_scale==. & business_practices_sum <=4
				
	replace 	business_practices_scale = 2 if ///
				business_practices_scale==. & business_practices_sum <=8
				
	replace 	business_practices_scale = 3 if ///
				business_practices_scale==. & business_practices_sum <=13
				
	replace 	business_practices_scale = 4 if ///
				business_practices_scale==. & business_practices_sum <=18
				
	replace 	business_practices_scale = 5 if ///
				business_practices_scale==. & business_practices_sum <=23

	label variable	business_practices_scale "Scale of advanced adoption, calculated based on the most recent interview"

	g 			business_practices_sum_20_more = 1 if business_practices_sum>=20
	g 			business_practices_sum_21_more = 1 if business_practices_sum>=21
	g 			business_practices_sum_22_more = 1 if business_practices_sum>=22
	g 			business_practices_sum_23_more = 1 if business_practices_sum>=23
		
/*
Again, the experiment used the zipcode from the first interview. I will 
replicate what was previously done, but we should consider using the most 
recent zipcode (from the latest interview), specially since we keep the business
practices scores from the last interview (not the first).
*/
		
	generate 	firm_zipcode =.
	replace		firm_zipcode = firm_zipcode_2015 if SSE_editions == 1
	replace		firm_zipcode = firm_zipcode_2016 if SSE_editions == 2
	replace		firm_zipcode = firm_zipcode_2017 if SSE_editions == 3
	replace		firm_zipcode = firm_zipcode_2015 if SSE_editions == 4
	replace		firm_zipcode = firm_zipcode_2015 if SSE_editions == 5
	replace		firm_zipcode = firm_zipcode_2016 if SSE_editions == 6
	replace		firm_zipcode = firm_zipcode_2015 if SSE_editions == 7
			
	label variable firm_zipcode "Firm's zipcode, as reported in the first interview"
			
	g 				firm_broad_zipcode = floor(firm_zipcode/1000)
	label variable	firm_broad_zipcode "Only the first 5 digits of the zipcode, as reported in the first interview"

* creating dataset of frequency of adoption level by broad zipcode and business sector
	
	g 				total_firms = 1	
	tabulate 		business_practices_scale, g(business_practices_level_)

	collapse  	(sum) business_practices_level_* business_practices_sum_20_more ///
				business_practices_sum_21_more business_practices_sum_22_more ///
				business_practices_sum_23_more total_firms, ///
				by (sebrae_strategic_business_sector firm_broad_zipcode)
	
	label variable	business_practices_level_1	"Number of firms with up to 4 advanced practices"
	label variable	business_practices_level_2	"Number of firms with 5 to 8 advanced practices"
	label variable	business_practices_level_3	"Number of firms with 9 to 13 advanced practices"
	label variable	business_practices_level_4	"Number of firms with 14 to 18 advanced practices"
	label variable	business_practices_level_5	"Number of firms with 19 to 23 advanced practices"
	label variable	business_practices_sum_20_more	"Number of firms with at least 20 advanced practices"
	label variable	business_practices_sum_21_more	"Number of firms with at least 21 advanced practices"
	label variable	business_practices_sum_22_more	"Number of firms with at least 22 advanced practices"
	label variable	business_practices_sum_23_more	"Number of firms with at least 23 advanced practices"
	label variable	total_firms "Number of firms in the same broad zipcode and Sebrae strategic business sector"
	
	local count = 1
	foreach var of varlist business_practices_level_1-business_practices_level_5 {

			g	percentage_level_`count' = `var'/total_firms
			label variable percentage_level_`count' "Percentage of firms with level `count' business practices"
			local count = `count' + 1
			
	}
	
	local count = 20
	foreach var of varlist ///
			business_practices_sum_20_more business_practices_sum_21_more ///
			business_practices_sum_22_more business_practices_sum_23_more {

			g	percentage_`count'_more = `var'/total_firms
			label variable percentage_`count'_more "Percentage of firms with at least `count' advanced practices"
			local count = `count' + 1
			
	}
	
* saving the output
		
	save "Experiment\Output\output_code_02a_business_practices_benchmark1.dta", replace
	
*-------------------------------------------------------------------------------
*** benchmarking within sector only --------------------------------------------
*-------------------------------------------------------------------------------

* creating dataset of frequency of adoption level by sector only

	collapse  	(sum) business_practices_level_* business_practices_sum_20_more ///
				business_practices_sum_21_more business_practices_sum_22_more ///
				business_practices_sum_23_more total_firms, ///
				by (sebrae_strategic_business_sector)

	label variable	business_practices_level_1	"Number of firms with up to 4 advanced practices"
	label variable	business_practices_level_2	"Number of firms with 5 to 8 advanced practices"
	label variable	business_practices_level_3	"Number of firms with 9 to 13 advanced practices"
	label variable	business_practices_level_4	"Number of firms with 14 to 18 advanced practices"
	label variable	business_practices_level_5	"Number of firms with 19 to 23 advanced practices"
	label variable	business_practices_sum_20_more	"Number of firms with at least 20 advanced practices"
	label variable	business_practices_sum_21_more	"Number of firms with at least 21 advanced practices"
	label variable	business_practices_sum_22_more	"Number of firms with at least 22 advanced practices"
	label variable	business_practices_sum_23_more	"Number of firms with at least 23 advanced practices"
	label variable	total_firms "Number of firms in the same Sebrae strategic business sector"

	
	local count = 1
	foreach var of varlist business_practices_level_1-business_practices_level_5 {

			g	percentage_level_`count' = `var'/total_firms
			label variable percentage_level_`count' "Percentage of firms with level `count' business practices"
			local count = `count' + 1
			
	}
	
	local count = 20
	foreach var of varlist ///
			business_practices_sum_20_more business_practices_sum_21_more ///
			business_practices_sum_22_more business_practices_sum_23_more {

			g	percentage_`count'_more = `var'/total_firms
			label variable percentage_`count'_more "Percentage of firms with at least `count' advanced practices"
			local count = `count' + 1
			
	}	
	
* saving the output

	save "Experiment\Output\output_code_02a_business_practices_benchmark2.dta", replace

*-------------------------------------------------------------------------------
*** benchmarking with all firms (no region or sector cluster) ------------------
*-------------------------------------------------------------------------------

/* There is a sector category called "other". Firms in this sector will be 
compared to all firms (not only those classified as "other"). Then, we must
create the benchmark value for all firms.
*/

	collapse  	(sum) business_practices_level_* business_practices_sum_20_more ///
				business_practices_sum_21_more business_practices_sum_22_more ///
				business_practices_sum_23_more total_firms
				
	label variable	business_practices_level_1	"Number of firms with up to 4 advanced practices"
	label variable	business_practices_level_2	"Number of firms with 5 to 8 advanced practices"
	label variable	business_practices_level_3	"Number of firms with 9 to 13 advanced practices"
	label variable	business_practices_level_4	"Number of firms with 14 to 18 advanced practices"
	label variable	business_practices_level_5	"Number of firms with 19 to 23 advanced practices"
	label variable	business_practices_sum_20_more	"Number of firms with at least 20 advanced practices"
	label variable	business_practices_sum_21_more	"Number of firms with at least 21 advanced practices"
	label variable	business_practices_sum_22_more	"Number of firms with at least 22 advanced practices"
	label variable	business_practices_sum_23_more	"Number of firms with at least 23 advanced practices"
	label variable	total_firms "Total number of firms"

	
	local count = 1
	foreach var of varlist business_practices_level_1-business_practices_level_5 {

			g	percentage_level_`count' = `var'/total_firms
			label variable percentage_level_`count' "Percentage of firms with level `count' business practices"
			local count = `count' + 1
			
	}
	
	local count = 20
	foreach var of varlist ///
			business_practices_sum_20_more business_practices_sum_21_more ///
			business_practices_sum_22_more business_practices_sum_23_more {

			g	percentage_`count'_more = `var'/total_firms
			label variable percentage_`count'_more "Percentage of firms with at least `count' advanced practices"
			local count = `count' + 1
			
	}					

* replacing the within sector benchmark with the new comparison values for firms in "other"
*		(firms classified as "other" will be compared to all firms in the database)

	g sebrae_strategic_business_sector = 11

	append using "Experiment\Output\output_code_02a_business_practices_benchmark2.dta"

	label values sebrae_strategic_business_sector sebrae_strategic_business_sector

	drop if sebrae_strategic_business_sector == 6
	recode sebrae_strategic_business_sector (11 = 6)

	label define sebrae_strategic_business_sector 6 "All sectors", modify
	label values sebrae_strategic_business_sector sebrae_strategic_business_sector

* saving the output

	save "Experiment\Output\output_code_02a_business_practices_benchmark2.dta", replace

/* replacing the within region and sector benchmark with the new comparison values 
for firms in "other" (firms classified as "other" will be compared to all firms 
in the region)
*/

	use "Experiment\Output\output_code_02a_business_practices_benchmark1.dta", clear

	collapse  	(sum) business_practices_level_* business_practices_sum_20_more ///
				business_practices_sum_21_more business_practices_sum_22_more ///
				business_practices_sum_23_more total_firms, by (firm_broad_zipcode)
				
	label variable	business_practices_level_1	"Number of firms with up to 4 advanced practices"
	label variable	business_practices_level_2	"Number of firms with 5 to 8 advanced practices"
	label variable	business_practices_level_3	"Number of firms with 9 to 13 advanced practices"
	label variable	business_practices_level_4	"Number of firms with 14 to 18 advanced practices"
	label variable	business_practices_level_5	"Number of firms with 19 to 23 advanced practices"
	label variable	business_practices_sum_20_more	"Number of firms with at least 20 advanced practices"
	label variable	business_practices_sum_21_more	"Number of firms with at least 21 advanced practices"
	label variable	business_practices_sum_22_more	"Number of firms with at least 22 advanced practices"
	label variable	business_practices_sum_23_more	"Number of firms with at least 23 advanced practices"
	label variable	total_firms "Total number of firms"

	
	local count = 1
	foreach var of varlist business_practices_level_1-business_practices_level_5 {

			g	percentage_level_`count' = `var'/total_firms
			label variable percentage_level_`count' "Percentage of firms with level `count' business practices"
			local count = `count' + 1
			
	}
	
	local count = 20
	foreach var of varlist ///
			business_practices_sum_20_more business_practices_sum_21_more ///
			business_practices_sum_22_more business_practices_sum_23_more {

			g	percentage_`count'_more = `var'/total_firms
			label variable percentage_`count'_more "Percentage of firms with at least `count' advanced practices"
			local count = `count' + 1
			
	}					

	g sebrae_strategic_business_sector = 11

	append using "Experiment\Output\output_code_02a_business_practices_benchmark1.dta"

	label values sebrae_strategic_business_sector sebrae_strategic_business_sector

	drop if sebrae_strategic_business_sector == 6
	recode sebrae_strategic_business_sector (11 = 6)

	label define sebrae_strategic_business_sector 6 "All sectors", modify
	label values sebrae_strategic_business_sector sebrae_strategic_business_sector	
	
	label variable sebrae_strategic_business_sector "Sebrae's strategic sector to which the CNAE from first interview corresponds"
	
* saving the output
	
	order firm_broad_zipcode sebrae_strategic_business_sector
	sort firm_broad_zipcode sebrae_strategic_business_sector

	save "Experiment/Output/output_code_02a_business_practices_benchmark1.dta", replace
