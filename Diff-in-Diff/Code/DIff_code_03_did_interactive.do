*============================================================================== 
* Diff_code_03_full_interactive_analysis.do 
* Date: 08/15/2025 
* Author: Aaron Joseph 
* 
* Code 03: Fully interactive DiD estimation (covariates + treatment x X + 
* post x X), 2018-2019. 
* 
* Note: the covariate list reuses Matching's Xcand from 
* Matching_code_08_setup.do verbatim, rather than a union with DML's 
* covariates. A fully interactive regression has no regularization (unlike 
* DML's pystacked learners), so every treat x X and post x X term costs a 
* degree of freedom directly -- a compact, theoretically-motivated covariate 
* set is preferred over a saturated one, and reusing Xcand keeps this model 
* directly comparable to the Matching pipeline. No region/sector dummy 
* expansion. 
* 
* Main steps: 
*   1. Load the DiD sample and keep only relevant variables. 
*   2. Generate missing-indicators for the covariates. 
*   3. Demean continuous covariates.
*   4. Reshape to long format and build the post/treatment indicators. 
*   5. Build treatment x X and post x X interaction terms. 
*   6. Estimate the fully interactive DiD without firm fixed effects. 
*   7. Estimate the fully interactive DiD with firm fixed effects. 
*============================================================================== 
 
clear all 
cd "/Users/aaronjoseph/Downloads/Capstone/Felipe" 
 
// Step 1: Load the DiD sample and keep only relevant variables. 
use "Diff-in-Diff/Output/output_code_01_diff_sample.dta", clear 
 
local covariates respondent_age_2018 respondent_gender_2018 /// 
    business_practices_sum_2018 years_functioning_2018 /// 
    competition_density_full_zipco total_services_2015_2018 /// 
    respondent_owner_2018 number_employees_RAIS_2016 sse_2018_only 
 
keep firm_id treatment_assignment_binary number_employees_RAIS_* /// 
    business_practices_sum_* `covariates' 
drop if missing(business_practices_sum_2019) 
 
// Step 2: Generate missing-indicators for the covariates. 
* Missing-indicator generation (same logic as DML_code_00_shared) 
local missnames 
foreach var of local covariates { 
    capture confirm numeric variable `var' 
    if !_rc { 
        local missname = substr("`var'", 1, 27) + "_miss" 
        cap drop `missname' 
        gen `missname' = missing(`var') 
        replace `var' = 0 if missing(`var') 
        local missnames `missnames' `missname' 
    } 
} 
local covariates `covariates' `missnames' 

// Step 3: Demean continuous covariates so the did coefficient is evaluated 
// at the sample mean rather than at zero. 
* Binary and missing-indicator variables are not demeaned -- their mean is 
* not a meaningful centering point and the zero-vs-one contrast should 
* remain as-is. Continuous variables are identified by having more than 
* two distinct values. 
foreach var of local covariates { 
    capture confirm numeric variable `var' 
    if !_rc { 
        * Skip binary variables and missing indicators. 
        quietly tab `var' 
        if r(r) > 2 { 
            quietly summarize `var' 
            replace `var' = `var' - r(mean) 
        } 
    } 
} 

// Step 4: Reshape to long format and build the post/treatment indicators. 
* Covariates are 2018 cross-sectional (time-invariant), so they are kept 
* as-is (not reshaped) and stay constant across a firm's year-rows after reshape. 
reshape long number_employees_RAIS_ business_practices_sum_, i(firm_id) j(year) 
xtset firm_id year 
 
keep if (year >= 2018) & (year <= 2019) 
gen post = (year == 2019) 
drop if missing(business_practices_sum_) 
 
gen did = post*treatment_assignment_binary 
 
// Step 5: Build treatment x X and post x X interaction terms. 
* Covariate names are truncated to 24 characters before adding the treat_X_/ 
* post_X_ prefixes (8 chars each) to respect Stata's 32-character varname 
* limit. A counter is appended if truncation causes a name collision (e.g. a 
* variable and its miss indicator sharing the same first 24 characters). 
local treatX 
local postX 
local usednames 
foreach var of local covariates { 
    local shortname = substr("`var'", 1, 24) 
    local dupcount : list posof "`shortname'" in usednames 
    if `dupcount' > 0 { 
        local shortname = substr("`var'", 1, 22) + "_" + string(`dupcount' + 1) 
    } 
    local usednames `usednames' `shortname' 
 
    cap drop treat_X_`shortname' 
    cap drop post_X_`shortname' 
    gen treat_X_`shortname' = treatment_assignment_binary * `var' 
    gen post_X_`shortname' = post * `var' 
    local treatX `treatX' treat_X_`shortname' 
    local postX `postX' post_X_`shortname' 
} 
 
// Step 6: Estimate the fully interactive DiD without firm fixed effects. 
* Fully interactive DiD without FE 
reg business_practices_sum_ treatment_assignment_binary post did `covariates' `treatX' `postX', vce(cluster firm_id) 
estimates store did_full_int 
estimates save "Diff-in-Diff/Output/diff_in_diff_full_interactive_business_practices.ster", replace 
 
// Step 6: Estimate the fully interactive DiD with firm fixed effects. 
* With firm FE, treatment_assignment_binary and the covariate main effects 
* and treat x X terms are collinear with the FE (all are time-invariant), 
* so only post, did, and post x X are identified here. 
xtreg business_practices_sum_ post did `postX', fe vce(cluster firm_id) 
estimates store did_full_int_fe 
estimates save "Diff-in-Diff/Output/diff_in_diff_full_interactive_fe_business_practices.ster", replace 

 

 

 
