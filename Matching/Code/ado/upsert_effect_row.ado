*============================================================================== 
* upsert_effect_row 
* 
* Named-option version -- avoids the whitespace-splitting bugs of positional 
* `args' when string values contain spaces, parentheses, or embedded quotes 
* (e.g. drop_cond = `Model == "CEM (PSM variables)"'). All string options 
* must be passed wrapped in compound double quotes. 
* 
* Main steps: 
*   1. Post the new result row to a temporary dataset. 
*   2. Load the current comparison CSV.
*   3. Append the new row and write the combined dataset back to the CSV. 
*============================================================================== 
capture program drop upsert_effect_row 
program define upsert_effect_row 
 
    // 1. Post the new result row to a temporary dataset. 
    syntax , CSVPath(string) MODEL(string) METHOD(string) /// 
        BETA(real) SE(real) PVAL(real) N1(integer) N2(integer) /// 
        VARSUsed(string) DROPCond(string) JOINTFp(real) 
 
    tempname newrow 
    tempfile newrow_dta 
    postfile `newrow' str40 Model str20 Method double Beta /// 
        double SE double PValue long N_Treated_or_Matched long N_Control_or_Dropped /// 
        long N_Total str200 Variables_Used double Joint_F_Pvalue str10 Estimand /// 
        using "`newrow_dta'", replace 
 
    post `newrow' ("`model'") ("`method'") (`beta') (`se') (`pval') /// 
        (`n1') (`n2') (`n1'+`n2') ("`varsused'") (`jointfp') ("ATET") 
    postclose `newrow' 
 
    // 2. Load the current comparison CSV. 
    preserve 
    cap confirm file "`csvpath'" 
    if !_rc { 
        import delimited "`csvpath'", clear varnames(1) stringcols(1 2 9 11) case(preserve)  
        cap confirm variable Variables_Used 
        if _rc gen str200 Variables_Used = "" 
        cap confirm variable Joint_F_Pvalue 
        if _rc gen double Joint_F_Pvalue = . 
        cap confirm variable Estimand 
        if _rc gen str10 Estimand = "ATET" 
        drop if `dropcond'                                                                  
        tempfile existing_dta 
        save `existing_dta' 
        use "`newrow_dta'", clear 
        append using `existing_dta' 
    } 
    else { 
        use "`newrow_dta'", clear 
    } 
 
    // 3. Write the combined dataset back to the CSV. 
    export delimited using "`csvpath'", replace 
    restore 
 
end 
