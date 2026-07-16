*========================================================================= 
* Matching_code_08b_entropy_balancing_analysis.do 
* 
* Entropy Balancing -- Balance Diagnostics and Effect Estimation 
* 
* Input:   Matching/Output/entropy_weighted_sample.dta 
* Output:  Matching/Output/entropy_balance.xlsx 
*          Matching/Output/entropy_itt.ster 
* 
* Author:  Aaron Joseph 
*========================================================================= 
clear all 
set more off 
cd "/Users/aaronjoseph/Downloads/Capstone/Felipe" 
 
global Y_main business_practices_sum_2019 
global D       treatment_assignment_binary 
global Xcand respondent_age_2018 respondent_gender_2018 /// 
    business_practices_sum_2018 years_functioning_2018 /// 
    competition_density_full_zipco total_services_2015_2018 /// 
    respondent_owner_2018 number_employees_RAIS_2016 sse_2018_only 
 
global out_match "Matching/Output" 
 
use "$out_match/entropy_weighted_sample.dta", clear 
 
* Weighted balance check -- should show near-zero differences on 
* every targeted covariate, since ebalance enforces exact moment match 
iebaltab $Xcand [aw = webal], grpvar($D) /// 
    save("$out_match/entropy_balance.xlsx") replace vce(robust) rowvarlabels 
 
* Weighted treatment effect estimate 
regress $Y_main $D [pweight = webal], robust 
 
estimates store entropy_itt 
estimates save "$out_match/entropy_itt.ster", replace 
 
di "Entropy balancing analysis complete." 
di "Estimates saved to $out_match/entropy_itt.ster" 
