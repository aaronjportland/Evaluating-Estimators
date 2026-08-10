
 *============================================================================== 
* rank_vars_by_importance 
* 
* Ranks a varlist by |standardized coefficient| on the outcome, within the 
* sample defined by `touse'. Unweighted by design -- this is a ranking 
* heuristic for reporting only, separate from the headline weighted 
* treatment-effect estimate. 
* 
* Main steps: 
*   1. Run the standardized-beta regression of the outcome on the varlist. 
*   2. Post each covariate's absolute standardized coefficient. 
*   3. Sort covariates by importance and return the ordered list. 
*============================================================================== 
capture program drop rank_vars_by_importance 
program define rank_vars_by_importance, rclass 
 
    args yvar varlist touse 
 
    tempname rk 
    tempfile rank_raw 
 
    quietly postfile `rk' str32 varname double abscoef using "`rank_raw'", replace 
 
    // Step 1: Run the standardized-beta regression of the outcome on the varlist. 
    quietly regress `yvar' `varlist' if `touse', beta 
    matrix b = e(b) 
    local names : colnames b 
    local j = 0 
 
    // Step 2: Post each covariate's absolute standardized coefficient. 
    foreach v of local names { 
        local j = `j' + 1 
        if "`v'" == "_cons" continue 
        local c = b[1,`j'] 
        post `rk' ("`v'") (abs(`c')) 
    } 
 
    postclose `rk' 
 
    // Step 3: Sort covariates by importance and return the ordered list. 
    preserve 
    use "`rank_raw'", clear 
 
    if _N == 0 { 
        restore 
        di as error "rank_vars_by_importance: no non-constant coefficients to rank." 
        error 2001 
    } 
 
    gsort -abscoef 
    local n = _N 
    local ordered "" 
    forvalues i = 1/`n' { 
        local vname = varname[`i'] 
        if `i' == 1 local ordered "`vname'" 
        else local ordered "`ordered'; `vname'" 
    } 
    restore 
 
    return local ordered_vars "`ordered'" 
 
end 
