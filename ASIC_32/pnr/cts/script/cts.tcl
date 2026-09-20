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

###### Ideal Ports #####
set fun_clk_port "clk"

set fun_srst_port "rst_n"


set ideal_network [list $fun_clk_port  $fun_srst_port]

set removed_ideal_network [list $fun_srst_port]

set clock_names [list clk]
##### Layers #####
set hm_top M9
set vm_top M8
##### Stages #####
set prev_stage      "placement"
set current_stage   "cts"

##### NDR #####
set clk_spacing_mult 2
set clk_width_mult 2

set max_fanout 5
set max_wire_l 100
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
                  #### Section 3 : Tool Setup ####
           #########################################################
####################################################################################
##### For MultiThreading #####
set_host_options -max_cores 12

###################################################################################
           #########################################################
                  #### Section 3 : Checkers ####
           #########################################################
####################################################################################
report_qor -summary         > ../reports/${rate}/pre_cts_qor.rpt

report_clocks

set_ignored_layers -max_routing_layer M7 -min_routing_layer M3

###################################################################################
           #########################################################
                  #### Section 4 : Setting CTS Cells ####
           #########################################################
####################################################################################
##### Remove all Cells that CTS Can Use to assign other specific ones later #####
set_lib_cell_purpose -exclude cts   [get_lib_cells */*]
set_lib_cell_purpose -exclude hold  [get_lib_cells */*]

##### Assign Specific Cells For CTS (Should be Clock Buffers But It is not available in this EDK) #####
set_lib_cell_purpose -include cts   "*/IBUFFX2*  */IBUFFX4*    */IBUFFX8*    */IBUFFX16*"
set_lib_cell_purpose -include cts   "*/NBUFFX2*  */NBUFFX4*    */NBUFFX8*    */NBUFFX16*"
set_lib_cell_purpose -include cts   "*/INVX2*    */INVX4*      */INVX8*      */INVX16*"

set_lib_cell_purpose -include hold  "*/*DELLN*"

###################################################################################
           #########################################################
                            #### Section 5 : NDR ####
           #########################################################
####################################################################################
##### CLock Source #####
create_routing_rule clk_network_NDR_root        -multiplier_spacing $clk_spacing_mult -multiplier_width $clk_width_mult

##### Startinng From The First Level of Buffered Branches #####
create_routing_rule clk_network_NDR_internal    -multiplier_spacing $clk_spacing_mult -multiplier_width $clk_width_mult

##### From the Last Level of Buffers to Sinks (Leaf) #####
create_routing_rule clk_network_NDR_leaf -multiplier_spacing 1 -multiplier_width 1

#Root
set_clock_routing_rules -net_type           root \
                        -clocks             $clock_names \
                        -rules              clk_network_NDR_root \
                        -max_routing_layer  M7 \
                        -min_routing_layer  M6 

#Internal
set_clock_routing_rules -net_type           internal \
                        -clocks             $clock_names \
                        -rules              clk_network_NDR_internal \
                        -max_routing_layer  M6 \
                        -min_routing_layer  M3

#Leaf
set_clock_routing_rules -net_type           sink \
                        -clocks             $clock_names \
                        -rules              clk_network_NDR_leaf \
                        -max_routing_layer  M3 \
                        -min_routing_layer  M1

###################################################################################
           #########################################################
                        #### Section 6 : Constraints ####
           #########################################################
####################################################################################
report_ideal_network
remove_ideal_network -all
report_ideal_network

remove_clock_latency        [all_clocks]
remove_propagated_clock     [all_clocks]
remove_clock_tree_options   -all -target_skew -target_latency

###################################################################################
           #########################################################
                            #### Section 7 : DRC ####
           #########################################################
####################################################################################
set_max_transition  0.15    -clock_path [get_clocks $clock_names]
set_max_capacitance 20      -clock_path [get_clocks $clock_names]

###################################################################################
           #########################################################
                    #### Section 8 : Clock Tree Target CTO ####
           #########################################################
####################################################################################
set_clock_tree_options -target_skew 0.1 -clocks $clock_names
set_clock_tree_options -target_latency 0.0 -clocks $clock_names

##### Reports #####
report_clock_setting

report_clock_tree_options

###################################################################################
           #########################################################
                    #### Section 9 : CTS App Options ####
           #########################################################
####################################################################################
##### Signal Integrety #####
set_app_options -list {time.enable_si_timing_windows                        {true}}
set_app_options -list {time.si_enable_analysis                              {true}}

##### Removal Time #####
set_app_options -name time.disable_recovery_removal_checks          -value  false

##### CRPR #####
set_app_options -name time.remove_clock_reconvergence_pessimism     -value  true
#fanout
set_app_options -list "cts.common.max_fanout                                ${max_fanout}"
#Congestion Handling
set_app_options -list {cts.compile.enable_global_route                      true}
#Clean Buffers In Clock Path
set_app_options -name cts.compile.remove_existing_clock_trees       -value  true
#Hold Optimisation
set_app_options -list {clock_opt.hold.effort                                {high}}
#Apply NDR
set_app_options -name clock_opt.flow.optimize_ndr                   -value  true
#Area Optimization (Time Then Area)
set_app_options -name clock_opt.flow.enable_clock_power_recovery    -value  area

###################################################################################
           #########################################################
                            #### Section 10 : CCD ####
           #########################################################
####################################################################################
##### Enable CCD #####
set_app_options -list {clock_opt.flow.enable_ccd                            {true}}

##### Allow CCD To Optimize hold
set_app_options -name ccd.hold_control_effort                       -value  high

##### Wire Length Limitaion #####
set_app_options -list "cts.common.max_net_length                            ${max_wire_l}"

##### Perefix #####
set_app_options -name cts.common.user_instance_name_prefix          -value  "CTS_"
set_app_options -name opt.common.user_instance_name_prefix          -value  "OPT_"

###################################################################################
           #########################################################
                        #### Section 11 : Clock Network ####
           #########################################################
####################################################################################
#syn
clock_opt -from build_clock -to build_clock

#Assign Clock Network
clock_opt -from route_clock -to route_clock

#Optimise Clock Network
clock_opt -from final_opto -to final_opto

#Check Number Of Cells Inserted
sizeof_collection [get_cells "CTS_*"]
sizeof_collection [get_cells "OPT_*"]

###################################################################################
           #########################################################
                        #### Section 12 : Connect ####
           #########################################################
####################################################################################
connect_pg_net -net "VDD" [get_pins -hierarchical */VDD]
connect_pg_net -net "VSS" [get_pins -hierarchical */VSS]

###################################################################################
           #########################################################
                        #### Section 13 : Checks ####
           #########################################################
####################################################################################
check_pg_connectivity
check_pg_drc
check_pg_missing_vias
check_routes -drc true

###################################################################################
           #########################################################
                     #### Section 13 : Reporting  ####
           #########################################################
####################################################################################
report_cell                               > ../reports/${rate}/cells.rpt
report_nets                               > ../reports/${rate}/nets.rpt
report_qor                                > ../reports/${rate}/post_qor.rpt
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
