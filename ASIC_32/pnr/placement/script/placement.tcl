####################################################################################
           #########################################################
                  #### Section 1 : Config Definition ####
           #########################################################
####################################################################################
##### Project Name #####
set top_module "zigbee"
set proj_path "/home/ICer/Desktop/shared_folder/ROBO/Zigbee/ASIC_32"

##### Library Type #####
set lib_typ "syn"

set SSLIB "/home/ICer/Desktop/shared_folder/32nm_lib/dbs/hvt/saed32hvt_ss0p75vn40c.db"

set rate "fast"
if {$rate == "fast"} {
       set param "F"
} elseif {$rate == "slow"} {
       set param "S"
} elseif {$rate == "hybrid"} {
       set param "H"
}
##### Design Library #####
set dlib_dir "${proj_path}/pnr/design_lib/outputs/${rate}"

##### Stages #####
set prev_stage      "powerplan"
set current_stage   "placement"

##### Layers #####
set hm_top M9
set vm_top M8

##### Fanout #####
set max_fanout 5

###### Ideal Ports #####
set fun_clk_port "clk"

set fun_srst_port "rst_n"


set ideal_network [list $fun_clk_port  $fun_srst_port]

set removed_ideal_network [list $fun_srst_port]

###################################################################################
           #########################################################
                  #### Section 2 : Design Library Setup ####
           #########################################################
####################################################################################
##### Open The Last Stage's Block #####
open_block $dlib_dir/${top_module}_${param}.dlib:${top_module}_${param}_${prev_stage}.design

##### Copy The Last Stage's Block to a new one to start Editing #####
copy_block    -from_block   ${top_module}_${param}.dlib:${top_module}_${param}_${prev_stage}.design \
              -to           ${top_module}_${param}.dlib:${top_module}_${param}_${current_stage}.design

##### Change The Current Block #####
current_block ${top_module}_${param}_${current_stage}.design

###################################################################################
           #########################################################
                          #### Section 5 : Checks ####
           #########################################################
####################################################################################
check_pg_connectivity       -check_std_cell_pin none
check_pg_drc                -ignore_std_cells
check_pg_missing_vias
##### Check Legality before Macros Placement #####
#check_legality -verpose

check_design -checks pre_placement_stage

###################################################################################
           #########################################################
                  #### Section 6 : Placement Configuration ####
           #########################################################
####################################################################################
set_app_options -name place.legalize.enable_advanced_legalizer        -value true
set_app_options -name place.legalize.legalizer_search_and_repair      -value true

set_app_options -name place.coarse.auto_density_control                -value true
set_app_options -name place.coarse.auto_timing_control                -value true

set_app_options -name place.coarse.legalizer_driven_placement         -value true

##### Ignores Def Files #####
set_app_options -list {place.coarse.continue_on_missing_scandef      {true}}
set_app_options -list {place.coarse.detect_detours                    {true}}

##### Limit Fanout #####
set_app_options -list {opt.tie_cell.max_fanout 1}
set_app_options -list "opt.common.max_fanout ${max_fanout}"

##### Timing Enhancements #####
set_app_options -list {opt.timing.effort                {high}}

##### Congestion Enhancements #####
set_app_options -list {place_opt.congestion.effort      {high}}

##### Any Extra Added Cells Prefix #####
set_app_options -name opt.common.user_instance_name_prefix       -value "PLACE_"

##### Limit The Number of Clock Pins by adding multi bit ff #####
set_app_options -name place_opt.flow.enable_multibit -value true
set_app_options -name place.coarse.max_density -value 0.40
###################################################################################
           #########################################################
              #### Section 7 : Ideal Network Reconfiguration ####
           #########################################################
####################################################################################
report_ideal_network
remove_ideal_network $removed_ideal_network
report_ideal_network

###################################################################################
           #########################################################
                        #### Section 8 : Placement ####
           #########################################################
####################################################################################
create_placement_blockage   -type partial \
                            -blocked_percentage 40 \
                            -boundary {{80 240} {80 280} {350 280} {350 240}}

create_placement_blockage   -type partial \
                            -blocked_percentage 40 \
                            -boundary {{335 30} {335 140} {450 140} {450 30}}

create_placement_blockage   -type partial \
                            -blocked_percentage 40 \
                            -boundary {{330 350} {330 480} {480 480} {480 350}}

create_placement     -effort              high \
                     -timing_driven \
                     -congestion \
                     -congestion_effort    high
#                     -incremental \

legalize_placement   -incremental

report_net_fanout    -threshold 20

###################################################################################
           #########################################################
                        #### Section 9 : Attribute Cell ####
           #########################################################
####################################################################################
report_attributes -application -nosplit [get_lib_cell */TIEH*]  > ../reports/${rate}/TIEH_attr.rpt
report_attributes -application -nosplit [get_lib_cell */TIEL*]  > ../reports/${rate}/TIEL_attr.rpt

set_attribute [get_lib_cells */TIEH*] dont_touch false
set_attribute [get_lib_cells */TIEL*] dont_touch false

set_attribute [get_lib_cells */TIEH*] dont_use   false
set_attribute [get_lib_cells */TIEL*] dont_use   false

###################################################################################
           #########################################################
                  #### Section 10 : Spare Cells ####
           #########################################################
####################################################################################
add_spare_cells      -num_cells   {NAND2X1_HVT       4
                                   INVX1_HVT         4
                                   OR2X1_HVT         3
                                   SDFFX1_HVT        3
                                   MUX21X1_HVT       4}     \
                     -cell_name    spare_cell           \
                     -random_distribution               \
                     -input_pin_connect_type tie_low

set spare_cells [get_cells *spare_cell*]

spread_spare_cells -cells $spare_cells
place_eco_cells -cells $spare_cells -legalize_only

###################################################################################
           #########################################################
                  #### Section 11 : Tie Cells ####
           #########################################################
####################################################################################
set_dont_touch $spare_cells
set tie_cells_high   [get_lib_cells */*TIEH*]
set tie_cells_low    [get_lib_cells */*TIEL*]
add_tie_cells        -objects             $spare_cells \
                     -tie_low_lib_cells   $tie_cells_low \
                     -tie_high_lib_cells  $tie_cells_high 

###################################################################################
           #########################################################
                  #### Section 12 : Placement Optimisation ####
           #########################################################
####################################################################################
place_opt
sizeof_collection [get_cells PLACE_*]
##### Incremental Optimisation #####
#refine_opt

###################################################################################
           #########################################################
                     #### Section 13 : Connect ####
           #########################################################
####################################################################################
connect_pg_net -net "VDD" [get_pins -hierarchical */VDD]
connect_pg_net -net "VSS" [get_pins -hierarchical */VSS]

###################################################################################
           #########################################################
                     #### Section 14 : Reporting  ####
           #########################################################
####################################################################################
report_cell                               > ../reports/${rate}/cells.rpt
report_nets                               > ../reports/${rate}/nets.rpt
report_qor                                > ../reports/${rate}/qor.rpt
report_timing                             > ../reports/${rate}/timing.rpt
report_timing -delay max -max_paths 10    > ../reports/${rate}/crit_paths.rpt
report_utilization                        > ../reports/${rate}/utilization.rpt
get_placement_blockage                    > ../reports/${rate}/blockage.rpt
check_pg_drc                              > ../reports/${rate}/drc.rpt
check_pg_connectivity                     > ../reports/${rate}/connectivity.rpt
check_pg_missing_vias                     > ../reports/${rate}/missing_vias.rpt

###################################################################################
           #########################################################
                     #### Section 15 : Saving The Block  ####
           #########################################################
####################################################################################
write_def                          ../outputs/${rate}/${top_module}.write_def
write_verilog -include {all}       ../outputs/${rate}/${top_module}.v
write_sdc     -output              ../outputs/${rate}/${top_module}.sdc

save_block

