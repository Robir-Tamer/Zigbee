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
set prev_stage      "floorplan"
set current_stage   "powerplan"

##### Layers #####
set hm_top M9
set vm_top M8

##### Ring Config #####
set ring_offset 1
set ring_width 3
set ring_spacing 3
set name_strategy core_ring

##### Mesh Confif #####
set strap_width 2
set strap_pitch 15
set strap_offset 1
set pattern_name straps_vddvss

##### Rails Configuration #####
set rail_strategie   rails_M1
set rail_pattern     std_cell_rail
set rail_layer       M1
set rail_width       0.06
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

##### Initialization #####
remove_pg_via_master_rules  -all
remove_pg_patterns          -all
remove_pg_strategies        -all
remove_pg_strategy          -all

start_gui

###################################################################################
           #########################################################
                  #### Section 3 : Nets Creation ####
           #########################################################
####################################################################################
create_net -power VDD
create_net -ground VSS
##### if nets are already declared in rtl #####
# set_attribute [get_nets VDD] net_type power
# set_attribute [get_nets VSS] net_type ground
# set_app_options -name plan.pgroute.disable_via_creation -value true
###################################################################################
           #########################################################
                  #### Section 4 : Power Ring Setup ####
           #########################################################
####################################################################################
create_pg_region power_ring_region -core -expand_by_edge \
                     "{{side: 1} {offset: $ring_offset}} \
                      {{side: 2} {offset: $ring_offset}} \
                      {{side: 3} {offset: $ring_offset}} \
                      {{side: 4} {offset: $ring_offset}} "

create_pg_ring_pattern ring_pattern \
                            -horizontal_layer $hm_top -vertical_layer $vm_top \
                            -horizontal_width $ring_width -vertical_width $ring_width \
                            -horizontal_spacing $ring_spacing -vertical_spacing $ring_spacing

set_pg_strategy $name_strategy \
                     -pg_regions {power_ring_region} \
                     -pattern {{name: ring_pattern} {nets: "VSS VDD"}}

compile_pg -strategies $name_strategy

#To Get The Last Compile
#compile_pg -undo

###################################################################################
           #########################################################
                     #### Section 5 : Mesh Setup ####
           #########################################################
####################################################################################
create_pg_mesh_pattern $pattern_name \
  -layers \
    "{{vertical_layer: $vm_top} {width: $strap_width} {pitch: $strap_pitch} {spacing: interleaving} {offset: $strap_offset} {trim: true}} \
     {{horizontal_layer: $hm_top} {width: $strap_width} {pitch: $strap_pitch} {spacing: interleaving} {offset: $strap_offset} {trim: true}}"

set_pg_strategy mesh_vddvss -core \
  -pattern [list "pattern $pattern_name" "nets VDD VSS"] \
  -extension [list "stop design_boundary_and_generate_pin"]

compile_pg -strategies mesh_vddvss

#To Get The Last Compile
#compile_pg -undo

###################################################################################
           #########################################################
                     #### Section 6 : Rails Setup ####
           #########################################################
####################################################################################
create_pg_std_cell_conn_pattern $rail_pattern -layers $rail_layer -rail_width $rail_width
set_pg_strategy $rail_strategie -core  -pattern {{name: std_cell_rail} {nets: VDD VSS}}
compile_pg -strategies $rail_strategie

##### Connect pins to Rails #####
#hierarchical [include top module + sub modules]
connect_pg_net -net VDD [get_pins -hierarchical */VDD]
connect_pg_net -net VSS [get_pins -hierarchical */VSS]

##### Solve Floatin Wire Problem #####
set_app_options -name plan.pgroute.disable_via_creation -value true

create_pg_via -net "VDD VSS" -from_layers M9 -to_layers M8 -drc no_check
create_pg_via -net "VDD VSS" -from_layers M8 -to_layers M1 -drc no_check

set_app_options -name plan.pgroute.disable_via_creation -value false
##### Check DRCs and Connectivity#####
check_pg_drc
check_pg_connectivity
check_pg_missing_vias

###################################################################################
           #########################################################
                     #### Section 7 : VIAs VDD/VSS  ####
           #########################################################
####################################################################################
##### Create Stacked Via Connection From Layer 6 to Layer 1 #####
#set_pg_vias -nets {VDD VSS} -from_layers M6 -to_layers M1 -drc no_checks 

##### Vias Constraints #####
#set_via_def -via_def -pitch "X Y" -vias [get_vias * -filter via_def.name == *] -size "1 10"

###################################################################################
           #########################################################
                     #### Section 8 : Reporting  ####
           #########################################################
####################################################################################
check_pg_drc                    > ../reports/${rate}/pg_drc.rpt
check_pg_connectivity           > ../reports/${rate}/pg_connectivity.rpt
check_pg_missing_vias           > ../reports/${rate}/missing_via.rpt

#analyze_power_plan -voltage 0.7 -power_budget 690.576 -use_terminals_as_pads -nets {VDD VSS}

###################################################################################
           #########################################################
                     #### Section 9 : Saving The Block  ####
           #########################################################
####################################################################################
write_def                          ../outputs/${rate}/${top_module}.write_def
write_verilog -include {all}       ../outputs/${rate}/${top_module}.v
write_sdc     -output              ../outputs/${rate}/${top_module}.sdc

save_block