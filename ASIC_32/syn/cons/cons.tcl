####################################################################################
           #########################################################
                  #### Section 1 : Config Definition ####
           #########################################################
#################################################################################### 
##### Clock Names #####
set fun_clk_name clk

##### Clock Periods #####
set fun_period 31.25
#### Clock Uncertainty ####
set fun_su_uncertainty [expr 0.03 * $fun_period]
set fun_hold_uncertainty [expr 0.02 * $fun_period]

set fun_clk_rise 0.0
set fun_clk_fall 0.0 

set fun_clk_latency 0

##### Input Ports Configurations #####
set input_delay [expr 0.2 * $fun_period]
#set input_pad "NBUFFX2_HVT"
#set input_pad_opin "Z"

##### Output Ports Configurations #####
set output_delay [expr 0.2 * $fun_period]
set output_load 100

##### Transition and Capacitance Configurations #####
set max_transition 3.636620
set max_capacitance 100

##### Fanout Configurations #####
set max_fanout 10

##### Clock Edges #####
set fun_edge [expr $fun_period / 2]

##### Ideal Ports #####
set fun_clk_port "clk"

set fun_srst_port "rst_n"


set ideal_network [list $fun_clk_port  $fun_srst_port]

##### Wire Load Model #####
#set wire_model "ForQA"

####################################################################################
           #########################################################
                  #### Section 2 : Clock Constriants ####
           #########################################################
#################################################################################### 
##### Clock Creation #####
create_clock -name $fun_clk_name   -period $fun_period  -waveform [list 0 $fun_edge]       [get_ports $fun_clk_port]

##### Clock Latency #####
set_clock_latency $fun_clk_latency        [get_clocks $fun_clk_name]

##### Clock Uncertainty #####
set_clock_uncertainty -setup       $fun_su_uncertainty         [get_clocks $fun_clk_name]
set_clock_uncertainty -hold        $fun_hold_uncertainty       [get_clocks $fun_clk_name]

##### Clock Transition #####
set_clock_transition -rise  $fun_clk_rise [get_clocks $fun_clk_name]
set_clock_transition -fall  $fun_clk_fall [get_clocks $fun_clk_name]

##### Clock Grouping #####
#No Multi Clocks

##### Ideal Network #####
#set_dont_touch_network $ideal_network
set_ideal_network $ideal_network

####################################################################################
           #########################################################
               #### Section 3 : IO ports Configuration ####
           #########################################################
####################################################################################
##### Input Delay #####
set_input_delay      -clock [get_clocks $fun_clk_name]  -max $input_delay \
                            [remove_from_collection [all_inputs] [get_ports $fun_clk_port]]

##### Output Delay #####
set_output_delay     -clock [get_clocks $fun_clk_name]  -max $output_delay   [all_outputs]

##### Driving Cells #####
# set_driving_cell     -library   $worst_library \
#                      -lib_cell  $input_pad -pin $input_pad_opin \
#                      [remove_from_collection [all_inputs] [get_ports $fun_clk_port]]

##### Output Load #####
set_load $output_load [all_outputs]

####################################################################################
           #########################################################
               #### Section 4 : Operating Conditions ####
           #########################################################
####################################################################################
# set_operating_conditions    -analysis bc_wc      -min_library $best_library \
#                                                  -min $best_condition \
#                                                  -max_library $worst_library \
#                                                  -max $worst_condition
####################################################################################
           #########################################################
                  #### Section 5 : wireload Model ####
           #########################################################
####################################################################################
# set_wire_load_model -name $wire_model -library $worst_library

####################################################################################
           #########################################################
                  #### Section 6 : multicycle path ####
           #########################################################
####################################################################################

####################################################################################
           #########################################################
                    #### Section 7 : exception Cells ####
           #########################################################
####################################################################################
#set_dont_use [get_lib_cells */*AND3*]

####################################################################################
           #########################################################
                  #### Section 8 : Optimization Constraints ####
           #########################################################
####################################################################################
##### set_max_area #####
#set_max_area 0 

##### set_max_transition #####
set_max_transition $max_transition [current_design]

##### set_max_fanout #####
set_max_fanout $max_fanout [current_design]

##### set_max_capacitance #####
set_max_capacitance $max_capacitance [current_design]
