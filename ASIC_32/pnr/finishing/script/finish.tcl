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
set prev_stage      "routing"
set current_stage   "finishing"


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

##### DcapCell #####
set dcap_fillers [get_lib_cell */*DCAP*HVT]

##### Filler Cells #####
set std_filler [get_lib_cell */*SHFILL*HVT] 

set_app_options -list {place.legalize.enable_advanced_legalizer {false}}
###################################################################################
           #########################################################
                  #### Section 4 : Create DCAP Cells ####
           #########################################################
####################################################################################
set_attribute  [get_lib_cell */*DCAP*HVT]  dont_touch false
set_attribute  [get_lib_cell */*DCAP*HVT]  dont_use false
create_stdcell_fillers  -lib_cells      $dcap_fillers \
                        -utilization    50 \
                        -prefix         "DCAP_" \
                        -post_eco

###################################################################################
           #########################################################
                        #### Section 5 : Connect ####
           #########################################################
####################################################################################
connect_pg_net -net "VDD" [get_pins -hierarchical */VDD]
connect_pg_net -net "VSS" [get_pins -hierarchical */VSS]

connect_pg_net -automatic
route_eco
#remove_stdcell_fillers_with_violation

###################################################################################
           #########################################################
                #### Section 6 : Post-DCAP-Fillers Checking ####
           #########################################################
####################################################################################
check_routes 
check_lvs
check_legality
check_pg_drc

###################################################################################
           #########################################################
                #### Section 7 : Filler Cells ####
           #########################################################
####################################################################################
set_attribute  [get_lib_cells */*SHFILL*HVT]  dont_touch false
set_attribute  [get_lib_cells */*SHFILL*HVT]  dont_use false

set std_fillers_128  "saed32_hvt|saed32_hvt_std/SHFILL128_HVT "
set std_fillers_64   "saed32_hvt|saed32_hvt_std/SHFILL64_HVT"
set std_fillers_3    "saed32_hvt|saed32_hvt_std/SHFILL3_HVT"
set std_fillers_2    "saed32_hvt|saed32_hvt_std/SHFILL2_HVT"
set std_fillers_1    "saed32_hvt|saed32_hvt_std/SHFILL1_HVT"

create_stdcell_fillers  -lib_cells      $std_fillers_128 \
                        -prefix         "FILLER128_" \
                        -post_eco \
                        -continue_on_error

create_stdcell_fillers  -lib_cells  $std_fillers_64 \
                        -prefix     "FILLER64_" \
                        -post_eco \
                        -continue_on_error

create_stdcell_fillers  -lib_cells  $std_fillers_3 \
                        -prefix     "FILLER3_" \
                        -post_eco \
                        -continue_on_error

create_stdcell_fillers  -lib_cells  $std_fillers_2 \
                        -prefix     "FILLER2_" \
                        -post_eco \
                        -continue_on_error \
                        -ignore_hard_blockages\
                        -rules no_1x

create_stdcell_fillers  -lib_cells  $std_fillers_1 \
                        -prefix     "FILLER1_" \
                        -post_eco \
                        -continue_on_error \
                        -rules no_1x


sizeof_collection   [get_cells "*FILLER128_*"]
sizeof_collection   [get_cells "*FILLER64_*"]
sizeof_collection   [get_cells "*FILLER3_*"]
sizeof_collection   [get_cells "*FILLER2_*"]
sizeof_collection   [get_cells "*FILLER1_*"]

sizeof_collection   [get_cells "*DCAP_*"]
sizeof_collection   [get_cells "*FILLER*"]

###################################################################################
           #########################################################
                #### Section 8 : Post-Filler Checkers ####
           #########################################################
####################################################################################
check_routes
route_eco
check_routes
remove_stdcell_fillers_with_violation

###################################################################################
           #########################################################
                        #### Section 9 : Connect ####
           #########################################################
####################################################################################
connect_pg_net -net "VDD" [get_pins -hierarchical */VDD]
connect_pg_net -net "VSS" [get_pins -hierarchical */VSS]

###################################################################################
           #########################################################
                     #### Section 10 : Reporting  ####
           #########################################################
####################################################################################
report_congestion                         > ../reports/${rate}/Congestion.rpt
check_pg_drc                              > ../reports/${rate}/drc.rpt
report_qor                                > ../reports/${rate}/post_qor.rpt
# If there is a timing Violations go to prime time to solve them before proceeding to the next steps

report_timing                               > ../reports/${rate}/timing.rpt
report_timing -delay max -max_paths 10      > ../reports/${rate}/crit_paths.rpt
report_routing_status                       > ../reports/${rate}/routing_status.rpt
check_routes -drc true                                   > ../reports/${rate}/DRC.rpt
check_pg_connectivity                                    > ../reports/${rate}/pg_drc_connection.rpt
analyze_design_violations                                > ../reports/${rate}/setup_check_paths.rpt
report_design  -all                                      > ../reports/${rate}/design.rpt
check_legality                                           > ../reports/${rate}/leglaity.rpt
report_utilization                                       > ../reports/${rate}/Utilization.rpt

####################################################################################
           #########################################################
                     #### Section 11 : Saving The Block  ####
           #########################################################
####################################################################################
write_def                                               ../outputs/${rate}/${top_module}.write_def
write_verilog -include_physical_only_cells -output      ../outputs/${rate}/${top_module}.v
write_sdc     -output                                   ../outputs/${rate}/${top_module}.sdc
write_gds -output                                       ../outputs/${rate}/${top_module}.gds

# Extract the RC parasitics from the routed layout
#extract_parasitics

# Write out the SPEF file for signoff STA
write_parasitics -format spef -output ../outputs/${rate}/${top_module}.spef

save_block