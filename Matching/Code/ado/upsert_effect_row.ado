capture program drop upsert_effect_row 
program define upsert_effect_row 
	* Named-option version -- avoids the whitespace-splitting bugs of 
	* positional `args' when string values contain spaces, parentheses, 
	* or embedded quotes (e.g. drop_cond = `Model == "CEM (PSM variables)"'). 
	* All string options must be passed wrapped in compound double quotes: 
	*   upsert_effect_row, csvpath(`"...'"') model(`"...'"') ... drop_cond(`"...'"') 
	syntax , CSVPath(string) MODEL(string) METHOD(string) COEFName(string) /// 
		BETA(real) SE(real) PVAL(real) N1(integer) N2(integer) /// 
		VARSUsed(string) DROPCond(string) JOINTFp(real) JOINTMVTESTp(real) 
 
	tempname newrow 
	tempfile newrow_dta 
	postfile `newrow' str40 Model str20 Method str12 Coef_Name double Beta /// 
		double SE double PValue long N_Treated_or_Matched long N_Control_or_Dropped /// 
		long N_Total str200 Variables_Used double Joint_F_Pvalue double Joint_MVTest_Pvalue /// 
		using "`newrow_dta'", replace 
	post `newrow' ("`model'") ("`method'") ("`coefname'") (`beta') (`se') (`pval') /// 
		(`n1') (`n2') (`n1'+`n2') ("`varsused'") (`jointfp') (`jointmvtestp') 
	postclose `newrow' 
 
	preserve 
	cap confirm file "`csvpath'" 
	if !_rc { 
		import delimited "`csvpath'", clear varnames(1) stringcols(1 2 3 10) case(preserve) 
		cap confirm variable Variables_Used 
		if _rc gen str200 Variables_Used = "" 
		cap confirm variable Joint_F_Pvalue 
		if _rc gen double Joint_F_Pvalue = . 
		cap confirm variable Joint_MVTest_Pvalue 
		if _rc gen double Joint_MVTest_Pvalue = . 
		drop if `dropcond' 
		tempfile existing_dta 
		save `existing_dta' 
		use "`newrow_dta'", clear 
		append using `existing_dta' 
	} 
	else { 
		use "`newrow_dta'", clear 
	} 
	export delimited using "`csvpath'", replace 
	restore 
end 
