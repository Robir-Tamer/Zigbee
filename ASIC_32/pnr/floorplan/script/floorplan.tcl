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
set prev_stage      "dlib"
set current_stage   "floorplan"

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

start_gui

###################################################################################
           #########################################################
                  #### Section 3 : Layers Setup ####
           #########################################################
####################################################################################
##### Odd Layers >>>> Horizontal #####
set_attribute [get_layers {M1 M3 M5 M7 M9        }] routing_direction horizontal

##### Even Layers >>>>> Vertical #####
set_attribute [get_layers {M2 M4 M6 M8 MRDL      }] routing_direction vertical

##### Site Def Attribute #####
set Name_unit [get_site_defs]
set_attribute $Name_unit is_default true

##### Flipping Symmetry #####
# Alternate between VDD and VSS
set_attribute $Name_unit Symmetry {Y}

##### Put and shift offset so wires are alligned with pins if not declared in tf file #####
#set_attribute [get_layers {M1}] track_offset .037

###################################################################################
           #########################################################
                  #### Section 4 : Initailise Floor Plan ####
           #########################################################
####################################################################################
#set my_boundary {
#    {0 0}    {100 0}    {100 400}  {300 0}  {300 100} 
#    {100 500} {300 900} {300 1000}  {100 600}  {100 1000}   
#    {0 1000}   {0 0} 
#}

initialize_floorplan    -control_type          core \
                        -core_utilization      0.3 \
                        -shape                  R \
                        -core_offset           {10} \
                        -flip_first_row        true \
                        -side_ratio            {1 1}
                        #-orientation
                        #-boundary $my_boundary 
                        #-side_length

###################################################################################
           #########################################################
                  #### Section 5 : Pin Placment ####
           #########################################################
####################################################################################
#create_placement_blockage -boundary {{30 30} {50 50}}  -name B1 -type hard
#create_placement_blockage -boundary {{5 3} {7 5}}      -name B2 -type partial -blocked_percentage 40
#create_placement_blockage -boundary {{7 3} {9 5}}       -name B3 -type soft 
place_pins -self -ports [get_ports *]
###################################################################################
           #########################################################
                  #### Section 6 : TapCell Placement ####
           #########################################################
####################################################################################
#create_tap_cells -lib_cell [get_lib_cell */SAEDRVT14_TAPDS]   -pattern stagger       -distance 40
#sizeof_collection [get_cells tap*]
#remove_cell tap*

#create_tap_cells -lib_cell [get_lib_cell */SAEDRVT14_TAPDS]   -pattern every_row     -distance 10
#sizeof_collection [get_cells tap*]
#remove_cell tap*

#create_tap_cells -lib_cell [get_lib_cell */SAEDRVT14_TAPDS]   -pattern every_other_row     -distance 10
#sizeof_collection [get_cells tap*]
#remove_cell tap*

###################################################################################
           #########################################################
                  #### Section 7 : Reporting ####
           #########################################################
####################################################################################
report_qor                  > ../reports/${rate}/qor.rpt
report_utilization          > ../reports/${rate}/untilization.rpt
get_placement_blockages     > ../reports/${rate}/blockage.rpt

###################################################################################
           #########################################################
                  #### Section 8 : Save Block ####
           #########################################################
####################################################################################
save_block -as ${top_module}_${param}_${current_stage} ${top_module}_${param}.dlib:${top_module}_${param}_${current_stage}.design