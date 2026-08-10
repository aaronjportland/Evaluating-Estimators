*============================================================================== 
* joint_balance_test 
* 
* Main steps: 
*   1. Run a joint F-test of covariates on treatment assignment. 
*   2. Run a multivariate (Hotelling's T2-type) test of equal covariate means. 
*============================================================================== 
program define joint_balance_test, rclass 
    args varlist wtvar touse label 
 
    di "" 
    di "--- Joint balance test: `label' ---" 
 
    // Step 1: Run a joint F-test of covariates on treatment assignment. 
    * H0: covariates jointly do NOT predict treatment assignment, i.e. 
    * balance holds jointly, not just variable-by-variable. Supports 
    * weights natively via regress. 
    if "`wtvar'" == "" { 
        cap noisily quietly regress $D `varlist' if `touse' 
    } 
    else { 
        cap noisily quietly regress $D `varlist' if `touse' [aw=`wtvar'] 
    } 
    if _rc { 
        di as error "WARNING: joint F-test regression failed (rc=`=_rc')." 
        return scalar f_stat = . 
        return scalar f_p = . 
    } 
    else { 
        quietly test `varlist' 
        local f_stat = r(F) 
        local f_p = r(p) 
        di "F-test of joint covariate balance (H0: covariates jointly unrelated to treatment):" 
        di "  F(`r(df)', `r(df_r)') = `f_stat',  p = `f_p'" 
        di "  (p > 0.05 is the desired result -- indicates no joint imbalance detected)" 
        return scalar f_stat = `f_stat' 
        return scalar f_p = `f_p' 
    } 
 
    // Step 2: Run a multivariate (Hotelling's T2-type) test of equal covariate means. 
    * NOTE: mvtest does not support weights. This is run UNWEIGHTED on the 
    * `touse' subsample, so for CEM (where weights mainly correct within- 
    * stratum counts) this is a reasonable approximation, but for PSM/entropy 
    * balancing (continuous weights) it is a weaker, approximate check -- not 
    * equivalent to the weighted balance table. 
    cap which mvtest 
    if _rc { 
        di as error "mvtest not installed -- run: ssc install mvtest. Skipping multivariate balance test." 
        return scalar mvtest_p = . 
    } 
    else { 
        cap noisily mvtest means `varlist' if `touse', by($D) 
        if _rc { 
            di as error "mvtest failed (rc=`=_rc'); skipping multivariate balance test." 
            return scalar mvtest_p = . 
        } 
        else { 
            return scalar mvtest_p = r(p) 
        } 
    } 
end 
