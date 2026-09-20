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

##### Technology #####
set tf_path "/home/ICer/Desktop/shared_folder/32nm_lib/tf/saed32nm_1p9m.tf"

##### TLU+ #####
set tech_map "/home/ICer/Desktop/shared_folder/32nm_lib/tech/saed32nm_tf_itf_tluplus.map"
set tluplus "/home/ICer/Desktop/shared_folder/32nm_lib/tech"

##### Libraries #####
set lib_path "/home/ICer/Desktop/shared_folder/32nm_lib/dbs/*"

set worst_library "saed32hvt_ss0p75vn40c"

set SSLIB "/home/ICer/Desktop/shared_folder/32nm_lib/dbs/hvt/saed32hvt_ss0p75vn40c.db"

##### Operating Conditions #####
set best_condition "BEST"
set worst_condition "WORST"

##### NDM #####
set reference_library [glob /home/ICer/Desktop/shared_folder/32nm_lib/ndm/*.ndm]

##### Target Library #####
set target_library          $SSLIB

##### Link Library #####
set_app_var link_library    [list * $SSLIB]

set rate "fast"
if {$rate == "fast"} {
       set param "F"
} elseif {$rate == "slow"} {
       set param "S"
} elseif {$rate == "hybrid"} {
       set param "H"
}

if {[file exists "/home/ICer/Desktop/shared_folder/32nm_lib/ndm/"]} {
   foreach file [glob -nocomplain "${proj_path}/pnr/design_lib/outputs/${rate}/*"] {
      file delete -force $file
   }
}
####################################################################################
           #########################################################
                  #### Section 2 : Design Library Creation ####
           #########################################################
#################################################################################### 
create_lib -technology $tf_path -ref_libs $reference_library ../outputs/${rate}/${top_module}_${param}.dlib

####################################################################################
           #########################################################
                     #### Section 3 : read netlist ####
           #########################################################
#################################################################################### 
read_verilog -top $top_module ${proj_path}/${lib_typ}/generated_files/${rate}/netlist/${top_module}_${param}.v
link_block

####################################################################################
           #########################################################
                     #### Section 4 : read SDC ####
           #########################################################
#################################################################################### 
read_sdc "${proj_path}/${lib_typ}/generated_files/${rate}/sdc/${top_module}_${param}.sdc"

####################################################################################
           #########################################################
                     #### Section 4 : read TLU+ File ####
           #########################################################
#################################################################################### 
read_parasitic_tech         -layermap     $tech_map \
                            -tlup         "${tluplus}/saed32nm_1p9m_Cmax.lv.tluplus" \
                            -name         tlup_max

# read_parasitic_tech         -layermap     $tech_map \
#                             -tlup         ${tluplus}/saed90nm_1p9m_1t_Cmin.tluplus \
#                             -name         tlup_min

set_parasitic_parameters    -late_spec    tlup_max \
                            -early_spec   tlup_max

####################################################################################
           #########################################################
                     #### Section 5 : Save Block ####
           #########################################################
####################################################################################
#                    Lable_Name           Lib_Name  :   Block_Name.Views
save_block -as ${top_module}_${param}_dlib ${top_module}_${param}.dlib:${top_module}.design