*========================================================================= 
* DML_code_03_format_output.do 
*========================================================================= 
do "/Users/aaronjoseph/Downloads/Capstone/Felipe/DML/Code/DML_code_00_shared.do" 
 
global KNOWN_TREATVARS "treatment_assignment any_treatment treatment_y itt treatment treatment_assignment_binary" 
 
local partial_models  dml_partial_full dml_partial_highcomp dml_partial_lowcomp dml_partial_match 
local int_models      dml_int_full dml_int_highcomp dml_int_lowcomp dml_int_match 
 
local avail_partial 
foreach m of local partial_models { 
    capture estimates use "$out_dml/`m'.ster" 
    if !_rc { 
        estimates store `m' 
        local avail_partial `avail_partial' `m' 
    } 
    else di as error "NOTE: `m'.ster not found -- skipped." 
} 
 
local avail_int 
foreach m of local int_models { 
    capture estimates use "$out_dml/`m'.ster" 
    if !_rc { 
        estimates store `m' 
        local avail_int `avail_int' `m' 
    } 
    else di as error "NOTE: `m'.ster not found -- skipped." 
} 
 
capture estimates use "Experiment/Output/experiment_itt.ster" 
local have_rct = 0 
if !_rc { 
    estimates store rct_itt 
    local have_rct = 1 
} 
else di as error "NOTE: experiment_itt.ster not found -- RCT ITT comparison will be skipped." 
 
if "`avail_partial'" == "" & "`avail_int'" == "" { 
    di as error "ERROR: no DML .ster files found. Run the DML analysis scripts first." 
    exit 601 
} 
 
local rct_tok 
if `have_rct' local rct_tok rct_itt 
 
local partial_list  `rct_tok' `avail_partial' 
local int_list      `rct_tok' `avail_int' 
local combined_list `rct_tok' `avail_partial' `avail_int' 
 
write_results_csv, models("`partial_list'") csvfile("$out_dml/output_dml_partial_results_table.csv") estimand(ATE) 
write_results_csv, models("`int_list'") csvfile("$out_dml/output_dml_interactive_results_table.csv") estimand(ATET) 
write_results_csv, models("`combined_list'") csvfile("$out_dml/output_dml_method_comparison_table.csv") 
 
di "DML output formatting complete -- schema matches Matching pipeline CSVs." 
di "Partial models included: `avail_partial'" 
di "Interactive models included: `avail_int'" 
di "RCT ITT included: " cond(`have_rct'==1, "yes", "no") 
