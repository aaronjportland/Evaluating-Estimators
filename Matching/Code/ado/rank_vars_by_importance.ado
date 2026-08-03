capture program drop rank_vars_by_importance 
program define rank_vars_by_importance, rclass 
    * Ranks a varlist by |standardized coefficient| on the outcome, 
    * within the sample defined by `touse'. Unweighted by design -- this 
    * is a ranking heuristic for reporting only, separate from the 
    * headline weighted treatment-effect estimate. 
    args yvar varlist touse 
    tempname rk 
    tempfile rank_raw 
    postfile `rk' str32 varname double abscoef using "`rank_raw'", replace 
    quietly regress `yvar' `varlist' if `touse', beta 
    matrix b = e(b) 
    local names : colnames b 
    local names : subinstr local names "_cons" "", word 
    local j = 1 
    foreach v of local names { 
        local c = b[1,`j'] 
        post `rk' ("`v'") (abs(`c')) 
        local j = `j' + 1 
    } 
    postclose `rk' 
    preserve 
    use "`rank_raw'", clear 
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
