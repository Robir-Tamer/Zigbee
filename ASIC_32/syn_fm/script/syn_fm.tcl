####################################################################################
           #########################################################
                  #### Section 1 : Config Definition ####
           #########################################################
#################################################################################### 
##### Top Module #####
set top_module "zigbee"

##### Work Library #####
define_design_lib work -path ./work

##### Libraries #####
set lib_path "/home/ICer/Desktop/shared_folder/32nm_lib/dbs/*"

set worst_library "saed32hvt_ss0p75vn40c"

set SSLIB "/home/ICer/Desktop/shared_folder/32nm_lib/dbs/hvt/saed32hvt_ss0p75vn40c.db"

##### Operating Conditions #####
# set best_condition  "BEST"
# set worst_condition "WORST"

##### Formality Type #####
set fm_type "syn" ; #syn or dft 

##### Reference Files #####
set ref_type "rtl" ; #rtl or netlist
set rtl_path  "/mnt/hgfs/Shared_Folder/ROBO/Zigbee/RTL"
set rate "fast"
remove_container -all
####################################################################################
           #########################################################
                  #### Section 2 : Guidance ####
           #########################################################
#################################################################################### 
##### Synopsys setup variable ####
#set hdlin_ignore_full_case true
#set hdlin_ignore_parallel_case false
#set hdlin_warn_on_mismatch_message "FMR_ELAB-147"
#set hdlin_error_on_mismatch_message false
#set hdlin_unresolved_modules black_box
#set hdlin_enable_hier_naming true
#set verification_verify_unread_bbox_inputs false
#set verification_verify_unread_compare_points false
#set verification_ignore_unmatched_implementation_blackbox_input true
#set verification_set_undriven_signals X
#set verification_verify_directly_undriven_output false
#set verification_constant_prop_mode auto
#set verification_verify_directly_undriven_output true
set synopsys_auto_setup true

##### Formality Setup File #####
if {$rate == "fast"} {
       set param "F"
} elseif {$rate == "slow"} {
       set param "S"
} elseif {$rate == "hybrid"} {
       set param "H"
}

set_svf "../../$fm_type/generated_files/${rate}/svf/${top_module}_${param}.svf"

####################################################################################
           #########################################################
                  #### Section 4 : Reference Container ####
           #########################################################
####################################################################################
create_container ref 
current_container ref 
if {$ref_type == "rtl"} {
    read_verilog -libname work -container ref "${rtl_path}/*.*v"
} else {
    read_verilog -libname work -netlist -container ref "../../$fm_type/generated_files/${rate}/$ref_type/$top_module.v"
}

##### Read Reference technology libraries #####
read_db -container ref $SSLIB

##### set the top Reference Design #####
set_top ref:/work/$top_module -parameter {rate_mode "F"}
set_reference_design ref:/work/zigbee_rate_moderate_modeF

####################################################################################
           #########################################################
                  #### Section 5 : Implementation Container ####
           #########################################################
#################################################################################### 
create_container imp 
current_container imp 
##### Read Reference technology libraries #####
read_db -container imp $SSLIB
read_verilog -libname work -netlist -container imp "../../$fm_type/generated_files/${rate}/netlist/${top_module}_${param}.v"

##### set the top Reference Design #####
set_implementation_design imp:/work/$top_module
set_top imp:/work/$top_module

####################################################################################
           #########################################################
                  #### Section 6 : Start Matching ####
           #########################################################
####################################################################################
##### Turn off DFT #####
# set_constant ref:/work/*/test_mode 0
# set_constant imp:/work/*/test_mode 0
 
match

####################################################################################
           #########################################################
                  #### Section 7 : Start Verification ####
           #########################################################
####################################################################################
set successful [verify]
if {!$successful} {
diagnose 
analyze_points -failing
}

####################################################################################
           #########################################################
                  #### Section 8 : Reporting ####
           #########################################################
####################################################################################
report_passing_points       > "../reports/${rate}/passing_points.rpt"
report_failing_points       > "../reports/${rate}/failing_points.rpt"
report_aborted_points       > "../reports/${rate}/aborted_points.rpt"
report_unverified_points    > "../reports/${rate}/unverified_points.rpt"
report_unmatched_points     > "../reports/${rate}/unmatched_points.rpt"
report_error_candidates     > "../reports/${rate}/error_candidates.rpt"
analyze_points -failing     > "../reports/${rate}/failing_analysis.rpt"

start_gui














