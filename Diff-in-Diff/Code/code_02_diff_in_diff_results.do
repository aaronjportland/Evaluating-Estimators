********************************************************************************
* Date: 08/15/2025
* Author: Felipe Oliveira
*
*   Code: Difference-in-Differences estimation for 2018–2019
********************************************************************************

clear all
cd "/Users/aaronjoseph/Downloads/Capstone/Felipe"
	
	
* Import data
use "Diff-in-Diff/Output/output_code_01_diff_sample.dta", clear

* Keep only relevant variables
keep firm_id treatment_assignment_binary number_employees_RAIS_* business_practices_sum_*
drop if missing(business_practices_sum_2019)
* Reshape to long format for DiD

reshape long number_employees_RAIS_ business_practices_sum_, i(firm_id) j(year)

xtset firm_id year


* Create post-treatment indicator (2019 = post)
keep if (year >= 2018) & (year <= 2019)
gen post = (year == 2019)
* drop if missing(business_practices_sum)

* drop if missing(business_practices_sum)
* Create effective treatment variable
gen did = post*treatment_assignment_binary


* Difference-in-differences regression

* Business practices
* Simple DiD without FE
reg business_practices_sum treatment_assignment_binary post did, vce(cluster firm_id)

* Two ways to run DiD with FE
xtreg business_practices_sum post did, fe vce(cluster firm_id)

xtdidreg (business_practices_sum) (did), group(firm_id) time(year)
* didreg (business_practices_sum) (did), group(id) time(year)

* Store it in memory
estimates store diff_in_diff

* Save it to disk
estimates save "Diff-in-Diff/Output/simple_diff_in_diff_business_practices.ster", replace


***** Number of employees
clear all
cd "/Users/aaronjoseph/Downloads/Capstone/Felipe"
	
use "Diff-in-Diff/Output/output_code_01_diff_sample.dta", clear

keep firm_id treatment_assignment_binary number_employees_RAIS_* business_practices_sum_*

drop if missing(number_employees_RAIS_2015, number_employees_RAIS_2016, number_employees_RAIS_2017, number_employees_RAIS_2018, number_employees_RAIS_2019)
* Reshape to long format for DiD

reshape long number_employees_RAIS_ business_practices_sum_, i(firm_id) j(year)

xtset firm_id year


* Create post-treatment indicator (2019 = post)
keep if (year <= 2019)
gen post = (year >= 2018)
* drop if missing(business_practices_sum)

* drop if missing(business_practices_sum)
* Create effective treatment variable
gen did = post*treatment_assignment_binary


didregress (number_employees_RAIS) (did), ///
    group(firm_id) time(year)
	
estat trendplots

graph export "Diff-in-Diff/Output/trendplots.png", replace

estat ptrends

* Store it in memory
estimates store diff_in_diff

* Save it to disk
estimates save "Diff-in-Diff/Output/diff_in_diff_employees.ster", replace
	   
********************************************************************************
* Event Study for DiD (2015–2018, baseline = 2017)
********************************************************************************


*------------------------------------------------------------
* Step 1. Define event time (relative to 2018 = baseline year)
*------------------------------------------------------------
gen rel_year = year - 2017

gen pre1 = year == 2015
gen pre2 = year == 2016
gen post1 = year == 2018

gen pre1_treat = pre1*treatment_assignment_binary
gen pre2_treat = pre1*treatment_assignment_binary
gen pre3_treat = pre1*treatment_assignment_binary
gen post1_treat = post1*treatment_assignment_binary


*------------------------------------------------------------
* Step 2. Estimate event-study regression
*   - Absorb firm fixed effects (id) and year fixed effects
*   - Interact treatment with relative year dummies
*------------------------------------------------------------
* Install reghdfe if you don't have it
cap which reghdfe
if _rc ssc install reghdfe

reghdfe number_employees_RAIS_ b2017.year##i.treatment_assignment_binary, absorb(firm_id year) 

*------------------------------------------------------------
* Step 3. Plot dynamic treatment effects
*   - Keep only interaction coefficients
*   - Rel_year = 0 (2018) is the omitted baseline
*------------------------------------------------------------
	
	
estimates store es

* Plotting estimates
coefplot es,                                                ///
    keep(*.treatment_assignment_binary) ///
	drop(1.treatment_assignment_binary) ///
	rename(2015.year#1.treatment_assignment_binary = "-2"                   ///
           2016.year#1.treatment_assignment_binary = "-1"                   ///
           2018.year#1.treatment_assignment_binary = "+1") ///
    vertical ciopts(recast(rcap) lwidth(medthick))               ///
    msymbol(O) mcolor(navy) msize(medium)                        ///
    yline(0, lcolor(red)  lwidth(medthick))                      ///
    xline(4.7, lcolor(navy) lpattern(dash) lwidth(medthick))        ///
    xtitle("Years")                              ///
    ytitle("Impact on number of employees")                   ///
    legend(off) scheme(plotplain)                                ///
	addplot(scatteri 0 2.5, msymbol(O) mcolor(navy) msize(medium))
	
