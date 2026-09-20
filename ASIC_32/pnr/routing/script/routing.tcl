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

set clock_names [list clk]
##### Layers #####
set hm_top M9
set vm_top M8
##### Stages #####
set prev_stage      "cts"
set current_stage   "routing"

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
                  #### Section 4 : Pre_Route Checks ####
           #########################################################
####################################################################################
check_routability
check_design  -checks pre_route_stage
set_ignored_layers -max M9 -min M2

###################################################################################
           #########################################################
                  #### Section 5 : App Options ####
           #########################################################
####################################################################################
##### Enable Timing Driven #####
set_app_options -name route.global.timing_driven                            -value true
set_app_options -name route.track.timing_driven                             -value true
set_app_options -name route.detail.timing_driven                            -value true

##### Enable Cross-Talk aware Routing #####
set_app_options -name route.global.crosstalk_driven                         -value true
set_app_options -name route.track.crosstalk_driven                          -value true

##### Timing Analysis #####
set_app_options -name time.si_enable_analysis                               -value true
set_app_options -name time.all_clocks_propagated                            -value true

##### Improve DRC Convergence #####
set_app_options -name route.detail.eco_max_number_of_iterations             -value 60
set_app_options -name route.detail.drc_convergence_effort_level             -value high
set_app_options -name route.detail.check_patchable_drc_from_fixed_shapes    -value true

##### Enable CCD #####
set_app_options -name route_opt.flow.enable_ccd                             -value true
set_app_options -name route_opt.flow.enable_ccd_clock_drc_fixing            -value auto
set_app_options -name refine_opt.hold.effort                                -value "high"
set_app_options -list {route_opt.flow.enable_cto                                    {true}}
set_app_options -list {route_opt.flow.enable_targeted_ccd_wns_optimization          {true}}
set_app_options -list {route_opt.flow.enable_ccd                                    {true}}

##### Prefix Routing #####
set_app_options -name opt.common.user_instance_name_prefix                          -value "ROUTE_"

###################################################################################
           #########################################################
                  #### Section 6 : Routing Optimisation ####
           #########################################################
####################################################################################
route_opt

sizeof_collection   [get_cells "ROUTE_*"]
sizeof_collection   [get_cells "CTS_*"]
sizeof_collection   [get_cells "PLACE_*"]
sizeof_collection   [get_cells "OPT_*"]


###################################################################################
           #########################################################
                        #### Section 7 : Connect ####
           #########################################################
####################################################################################
connect_pg_net -net "VDD" [get_pins -hierarchical */VDD]
connect_pg_net -net "VSS" [get_pins -hierarchical */VSS]

###################################################################################
           #########################################################
                  #### Section 8 : Post_Route Checks ####
           #########################################################
####################################################################################
check_routes 
check_lvs
check_pg_connectivity

###################################################################################
           #########################################################
                     #### Section 9 : Reporting  ####
           #########################################################
####################################################################################
report_congestion                                       > ../reports/${rate}/Congestion.rpt
check_pg_drc                                            > ../reports/${rate}/drc.rpt
report_qor                                              > ../reports/${rate}/post_qor.rpt
# If there is a timing Violations go to prime time to solve them before proceeding to the next steps

report_timing                                           > ../reports/${rate}/timing.rpt
report_timing -delay max -max_paths 10                  > ../reports/${rate}/crit_paths.rpt
check_routes -drc true                                  > ../reports/${rate}/DRC.rpt
check_pg_connectivity                                   > ../reports/${rate}/pg_drc_connection.rpt
analyze_design_violations                               > ../reports/${rate}/setup_check_paths.rpt
report_design  -all                                     > ../reports/${rate}/design.rpt
check_legality                                          > ../reports/${rate}/leglaity.rpt
report_utilization                                      > ../reports/${rate}/Utilization.rpt

####################################################################################
           #########################################################
                     #### Section 10 : Saving The Block  ####
           #########################################################
####################################################################################
write_def                          ../outputs/${rate}/${top_module}.write_def
write_verilog -include {all}       ../outputs/${rate}/${top_module}.v
write_sdc     -output              ../outputs/${rate}/${top_module}.sdc

# Extract the RC parasitics from the routed layout
#extract_parasitics

# Write out the SPEF file for signoff STA
write_parasitics -format spef -output ../outputs/${rate}/${top_module}.spef

save_block