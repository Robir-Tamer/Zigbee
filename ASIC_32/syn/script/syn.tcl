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
# set best_condition "BEST"
# set worst_condition "WORST"
##### Zigbee Related Parameters #####
set rtl_path  "/mnt/hgfs/Shared_Folder/ROBO/Zigbee/RTL"
set rate      "F";   #F or S or H
####################################################################################
           #########################################################
                  #### Section 2 : Formality Setup file ####
           #########################################################
####################################################################################
if {$rate == "F"} {
       set_svf ../generated_files/fast/svf/${top_module}_${rate}.svf 
} elseif {$rate == "S"} {
       set_svf ../generated_files/slow/svf/${top_module}_${rate}.svf 
} elseif {$rate == "H"} {
       set_svf ../generated_files/hybrid/svf/${top_module}_${rate}.svf 
}

####################################################################################
           #########################################################
           #### Section 3 : Design Compiler Library Files Setup ####
           #########################################################
####################################################################################
##### Search Path #####
lappend search_path $lib_path
lappend search_path "/mnt/hgfs/Shared_Folder/ROBO/Zigbee/RTL"

##### Target Library #####
set_app_var target_library  $SSLIB

##### Link Library #####
set_app_var link_library [list * $SSLIB]

##### Min Library #####
#set_min_library ${best_library}.db -min_version ${worst_library}.db

####################################################################################
           #########################################################
                            #### Section 4 : Reading Files ####
           #########################################################
####################################################################################
analyze       -library work -format verilog             [glob ${rtl_path}/*.v]
analyze       -library work -format sverilog            [glob ${rtl_path}/*.sv]
elaborate     -lib work     $top_module   -parameters   "rate_mode = \"${rate}\""
elaborate -lib work $top_module -parameters "rate_mode = \"${rate}\""

# Force your custom design name here
rename_design [current_design] ${top_module}
##### Specify The Current Design #####
current_design $top_module

####################################################################################
           #########################################################
                            #### Section 5 : Linking Files ####
           #########################################################
####################################################################################
#link

####################################################################################
           #########################################################
                            #### Section 6 : Checking Design ####
           #########################################################
####################################################################################
check_design

####################################################################################
           #########################################################
                            #### Section 7 : Path Groups ####
           #########################################################
####################################################################################
#group_path -name INREG -from [all_inputs]
#group_path -name REGOUT -to [all_outputs]
#group_path -name INOUT -from [all_inputs] -to [all_outputs]

####################################################################################
           #########################################################
                            #### Section 8 : Constraints ####
           #########################################################
####################################################################################
source -echo ../cons/cons.tcl

####################################################################################
           #########################################################
                            #### Section 9 : Compile ####
           #########################################################
####################################################################################
set_fix_multiple_port_nets -all -buffer_constants 

compile -map_effort high
#compile_ultra                

##### Another Compilation iterations to solve violations #####
#compile -incremental -map_effort high

####################################################################################
           #########################################################
                            #### Section 10 : Generate Files ####
           #########################################################
####################################################################################
if {$rate == "F"} {
       write_file -format verilog  -hierarchy -output ../generated_files/fast/netlist/${top_module}_${rate}.v
       write_file -format ddc      -hierarchy -output ../generated_files/fast/netlist/${top_module}_${rate}.ddc
       write_sdc  -nosplit ../generated_files/fast/sdc/${top_module}_${rate}.sdc
       write_sdf           ../generated_files/fast/sdf/${top_module}_${rate}.sdf
} elseif {$rate == "S"} {
       write_file -format verilog  -hierarchy -output ../generated_files/slow/netlist/${top_module}_${rate}.v
       write_file -format ddc      -hierarchy -output ../generated_files/slow/netlist/${top_module_}${rate}.ddc
       write_sdc  -nosplit ../generated_files/slow/sdc/${top_module}_${rate}.sdc
       write_sdf           ../generated_files/slow/sdf/${top_module}_${rate}.sdf
} elseif {$rate == "H"} {
       write_file -format verilog  -hierarchy -output ../generated_files/hybrid/netlist/${top_module}_${rate}.v
       write_file -format ddc      -hierarchy -output ../generated_files/hybrid/netlist/${top_module}_${rate}.ddc
       write_sdc  -nosplit ../generated_files/hybrid/sdc/${top_module}_${rate}.sdc
       write_sdf           ../generated_files/hybrid/sdf/${top_module}_${rate}.sdf
}
##### Close Formality Setup File #####
set_svf -off

####################################################################################
           #########################################################
                            #### Section 11 : Reporting ####
           #########################################################
####################################################################################
if {$rate == "F"} {
       report_area          -hierarchy                                                            > ../reports/fast/area.rpt
       report_power         -hierarchy                                                            > ../reports/fast/power.rpt
       report_timing        -max_paths 100 -delay_type min -slack_lesser_than 0                   > ../reports/fast/violated_hold.rpt
       report_timing        -max_paths 100 -delay_type min -slack_greater_than 0                  > ../reports/fast/met_hold.rpt
       report_timing        -max_paths 100 -delay_type max -capacitance \
                            -transition -slack_greater_than 0                                     > ../reports/fast/met_setup.rpt
       report_timing        -max_paths 100 -delay_type max -capacitance \
                            -transition -slack_lesser_than 0                                      > ../reports/fast/violated_setup.rpt
       report_clock         -attributes                                                           > ../reports/fast/clocks.rpt
       report_constraint    -all_violators                                                        > ../reports/fast/constraints.rpt
} elseif {$rate == "S"} {
       report_area          -hierarchy                                                            > ../reports/slow/area.rpt
       report_power         -hierarchy                                                            > ../reports/slow/power.rpt
       report_timing        -max_paths 100 -delay_type min -slack_lesser_than 0                   > ../reports/slow/violated_hold.rpt
       report_timing        -max_paths 100 -delay_type min -slack_greater_than 0                  > ../reports/slow/met_hold.rpt
       report_timing        -max_paths 100 -delay_type max -capacitance \
                            -transition -slack_greater_than 0                                     > ../reports/slow/met_setup.rpt
       report_timing        -max_paths 100 -delay_type max -capacitance \
                            -transition -slack_lesser_than 0                                      > ../reports/slow/violated_setup.rpt
       report_clock         -attributes                                                           > ../reports/slow/clocks.rpt
       report_constraint    -all_violators                                                        > ../reports/slow/constraints.rpt
} elseif {$rate == "H"} {
       report_area          -hierarchy                                                            > ../reports/hybrid/area.rpt
       report_power         -hierarchy                                                            > ../reports/hybrid/power.rpt
       report_timing        -max_paths 100 -delay_type min -slack_lesser_than 0                   > ../reports/hybrid/violated_hold.rpt
       report_timing        -max_paths 100 -delay_type min -slack_greater_than 0                  > ../reports/hybrid/met_hold.rpt
       report_timing        -max_paths 100 -delay_type max -capacitance \
                            -transition -slack_greater_than 0                                     > ../reports/hybrid/met_setup.rpt
       report_timing        -max_paths 100 -delay_type max -capacitance \
                            -transition -slack_lesser_than 0                                      > ../reports/hybrid/violated_setup.rpt
       report_clock         -attributes                                                           > ../reports/hybrid/clocks.rpt
       report_constraint    -all_violators                                                        > ../reports/hybrid/constraints.rpt
}

####################################################################################
           #########################################################
                            #### Section 12 : GUI ####
           #########################################################
####################################################################################
gui_start
