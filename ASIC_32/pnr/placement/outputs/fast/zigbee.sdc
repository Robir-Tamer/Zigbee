################################################################################
#
# Design name:  zigbee_F_placement
#
# Created by icc2 write_sdc on Mon Sep 21 03:59:23 2026
#
################################################################################

set sdc_version 2.1
set_units -time ns -resistance MOhm -capacitance fF -voltage V -current uA

################################################################################
#
# Units
# time_unit               : 1e-09
# resistance_unit         : 1000000
# capacitive_load_unit    : 1e-15
# voltage_unit            : 1
# current_unit            : 1e-06
# power_unit              : 1e-12
################################################################################


# Mode: default
# Corner: default
# Scenario: default

# /home/ICer/Desktop/shared_folder/ROBO/Zigbee/ASIC_32/syn/generated_files/fast/sdc/zigbee_F.sdc, \
#   line 31; \
#   /home/ICer/Desktop/shared_folder/ROBO/Zigbee/ASIC_32/syn/generated_files/fast/sdc/zigbee_F.sdc, \
#   line 32
create_clock -name clk -period 31.25 -waveform {0 15.625} [get_ports {clk}]
set_load -pin_load 100 [get_ports {tx_real[7]}]
set_load -pin_load 100 [get_ports {tx_real[6]}]
set_load -pin_load 100 [get_ports {tx_real[5]}]
set_load -pin_load 100 [get_ports {tx_real[4]}]
set_load -pin_load 100 [get_ports {tx_real[3]}]
set_load -pin_load 100 [get_ports {tx_real[2]}]
set_load -pin_load 100 [get_ports {tx_real[1]}]
set_load -pin_load 100 [get_ports {tx_real[0]}]
set_load -pin_load 100 [get_ports {tx_imag[7]}]
set_load -pin_load 100 [get_ports {tx_imag[6]}]
set_load -pin_load 100 [get_ports {tx_imag[5]}]
set_load -pin_load 100 [get_ports {tx_imag[4]}]
set_load -pin_load 100 [get_ports {tx_imag[3]}]
set_load -pin_load 100 [get_ports {tx_imag[2]}]
set_load -pin_load 100 [get_ports {tx_imag[1]}]
set_load -pin_load 100 [get_ports {tx_imag[0]}]
set_load -pin_load 100 [get_ports {tx_done}]
set_ideal_network [get_ports {clk}]
# -origin user
set_clock_latency 0 [get_clocks {clk}]
# Set latency for io paths.
set_clock_uncertainty -setup 0.9375 [get_clocks {clk}]
set_clock_uncertainty -hold 0.625 [get_clocks {clk}]
set_clock_transition 0 [get_clocks {clk}]
# /home/ICer/Desktop/shared_folder/ROBO/Zigbee/ASIC_32/syn/generated_files/fast/sdc/zigbee_F.sdc, \
#   line 39
set_input_delay -clock [get_clocks {clk}] -max 6.25 [get_ports {rst_n}]
# /home/ICer/Desktop/shared_folder/ROBO/Zigbee/ASIC_32/syn/generated_files/fast/sdc/zigbee_F.sdc, \
#   line 40
set_input_delay -clock [get_clocks {clk}] -max 6.25 [get_ports {payload[7]}]
# /home/ICer/Desktop/shared_folder/ROBO/Zigbee/ASIC_32/syn/generated_files/fast/sdc/zigbee_F.sdc, \
#   line 41
set_input_delay -clock [get_clocks {clk}] -max 6.25 [get_ports {payload[6]}]
# /home/ICer/Desktop/shared_folder/ROBO/Zigbee/ASIC_32/syn/generated_files/fast/sdc/zigbee_F.sdc, \
#   line 42
set_input_delay -clock [get_clocks {clk}] -max 6.25 [get_ports {payload[5]}]
# /home/ICer/Desktop/shared_folder/ROBO/Zigbee/ASIC_32/syn/generated_files/fast/sdc/zigbee_F.sdc, \
#   line 43
set_input_delay -clock [get_clocks {clk}] -max 6.25 [get_ports {payload[4]}]
# /home/ICer/Desktop/shared_folder/ROBO/Zigbee/ASIC_32/syn/generated_files/fast/sdc/zigbee_F.sdc, \
#   line 44
set_input_delay -clock [get_clocks {clk}] -max 6.25 [get_ports {payload[3]}]
# /home/ICer/Desktop/shared_folder/ROBO/Zigbee/ASIC_32/syn/generated_files/fast/sdc/zigbee_F.sdc, \
#   line 45
set_input_delay -clock [get_clocks {clk}] -max 6.25 [get_ports {payload[2]}]
# /home/ICer/Desktop/shared_folder/ROBO/Zigbee/ASIC_32/syn/generated_files/fast/sdc/zigbee_F.sdc, \
#   line 46
set_input_delay -clock [get_clocks {clk}] -max 6.25 [get_ports {payload[1]}]
# /home/ICer/Desktop/shared_folder/ROBO/Zigbee/ASIC_32/syn/generated_files/fast/sdc/zigbee_F.sdc, \
#   line 47
set_input_delay -clock [get_clocks {clk}] -max 6.25 [get_ports {payload[0]}]
# /home/ICer/Desktop/shared_folder/ROBO/Zigbee/ASIC_32/syn/generated_files/fast/sdc/zigbee_F.sdc, \
#   line 48
set_input_delay -clock [get_clocks {clk}] -max 6.25 [get_ports \
    {payload_length[6]}]
# /home/ICer/Desktop/shared_folder/ROBO/Zigbee/ASIC_32/syn/generated_files/fast/sdc/zigbee_F.sdc, \
#   line 49
set_input_delay -clock [get_clocks {clk}] -max 6.25 [get_ports \
    {payload_length[5]}]
# /home/ICer/Desktop/shared_folder/ROBO/Zigbee/ASIC_32/syn/generated_files/fast/sdc/zigbee_F.sdc, \
#   line 50
set_input_delay -clock [get_clocks {clk}] -max 6.25 [get_ports \
    {payload_length[4]}]
# /home/ICer/Desktop/shared_folder/ROBO/Zigbee/ASIC_32/syn/generated_files/fast/sdc/zigbee_F.sdc, \
#   line 51
set_input_delay -clock [get_clocks {clk}] -max 6.25 [get_ports \
    {payload_length[3]}]
# /home/ICer/Desktop/shared_folder/ROBO/Zigbee/ASIC_32/syn/generated_files/fast/sdc/zigbee_F.sdc, \
#   line 52
set_input_delay -clock [get_clocks {clk}] -max 6.25 [get_ports \
    {payload_length[2]}]
# /home/ICer/Desktop/shared_folder/ROBO/Zigbee/ASIC_32/syn/generated_files/fast/sdc/zigbee_F.sdc, \
#   line 53
set_input_delay -clock [get_clocks {clk}] -max 6.25 [get_ports \
    {payload_length[1]}]
# /home/ICer/Desktop/shared_folder/ROBO/Zigbee/ASIC_32/syn/generated_files/fast/sdc/zigbee_F.sdc, \
#   line 54
set_input_delay -clock [get_clocks {clk}] -max 6.25 [get_ports \
    {payload_length[0]}]
# /home/ICer/Desktop/shared_folder/ROBO/Zigbee/ASIC_32/syn/generated_files/fast/sdc/zigbee_F.sdc, \
#   line 55
set_input_delay -clock [get_clocks {clk}] -max 6.25 [get_ports {start_tx}]
# /home/ICer/Desktop/shared_folder/ROBO/Zigbee/ASIC_32/syn/generated_files/fast/sdc/zigbee_F.sdc, \
#   line 56
set_output_delay -clock [get_clocks {clk}] -max 6.25 [get_ports {tx_real[7]}]
# /home/ICer/Desktop/shared_folder/ROBO/Zigbee/ASIC_32/syn/generated_files/fast/sdc/zigbee_F.sdc, \
#   line 57
set_output_delay -clock [get_clocks {clk}] -max 6.25 [get_ports {tx_real[6]}]
# /home/ICer/Desktop/shared_folder/ROBO/Zigbee/ASIC_32/syn/generated_files/fast/sdc/zigbee_F.sdc, \
#   line 58
set_output_delay -clock [get_clocks {clk}] -max 6.25 [get_ports {tx_real[5]}]
# /home/ICer/Desktop/shared_folder/ROBO/Zigbee/ASIC_32/syn/generated_files/fast/sdc/zigbee_F.sdc, \
#   line 59
set_output_delay -clock [get_clocks {clk}] -max 6.25 [get_ports {tx_real[4]}]
# /home/ICer/Desktop/shared_folder/ROBO/Zigbee/ASIC_32/syn/generated_files/fast/sdc/zigbee_F.sdc, \
#   line 60
set_output_delay -clock [get_clocks {clk}] -max 6.25 [get_ports {tx_real[3]}]
# /home/ICer/Desktop/shared_folder/ROBO/Zigbee/ASIC_32/syn/generated_files/fast/sdc/zigbee_F.sdc, \
#   line 61
set_output_delay -clock [get_clocks {clk}] -max 6.25 [get_ports {tx_real[2]}]
# /home/ICer/Desktop/shared_folder/ROBO/Zigbee/ASIC_32/syn/generated_files/fast/sdc/zigbee_F.sdc, \
#   line 62
set_output_delay -clock [get_clocks {clk}] -max 6.25 [get_ports {tx_real[1]}]
# /home/ICer/Desktop/shared_folder/ROBO/Zigbee/ASIC_32/syn/generated_files/fast/sdc/zigbee_F.sdc, \
#   line 63
set_output_delay -clock [get_clocks {clk}] -max 6.25 [get_ports {tx_real[0]}]
# /home/ICer/Desktop/shared_folder/ROBO/Zigbee/ASIC_32/syn/generated_files/fast/sdc/zigbee_F.sdc, \
#   line 64
set_output_delay -clock [get_clocks {clk}] -max 6.25 [get_ports {tx_imag[7]}]
# /home/ICer/Desktop/shared_folder/ROBO/Zigbee/ASIC_32/syn/generated_files/fast/sdc/zigbee_F.sdc, \
#   line 65
set_output_delay -clock [get_clocks {clk}] -max 6.25 [get_ports {tx_imag[6]}]
# /home/ICer/Desktop/shared_folder/ROBO/Zigbee/ASIC_32/syn/generated_files/fast/sdc/zigbee_F.sdc, \
#   line 66
set_output_delay -clock [get_clocks {clk}] -max 6.25 [get_ports {tx_imag[5]}]
# /home/ICer/Desktop/shared_folder/ROBO/Zigbee/ASIC_32/syn/generated_files/fast/sdc/zigbee_F.sdc, \
#   line 67
set_output_delay -clock [get_clocks {clk}] -max 6.25 [get_ports {tx_imag[4]}]
# /home/ICer/Desktop/shared_folder/ROBO/Zigbee/ASIC_32/syn/generated_files/fast/sdc/zigbee_F.sdc, \
#   line 68
set_output_delay -clock [get_clocks {clk}] -max 6.25 [get_ports {tx_imag[3]}]
# /home/ICer/Desktop/shared_folder/ROBO/Zigbee/ASIC_32/syn/generated_files/fast/sdc/zigbee_F.sdc, \
#   line 69
set_output_delay -clock [get_clocks {clk}] -max 6.25 [get_ports {tx_imag[2]}]
# /home/ICer/Desktop/shared_folder/ROBO/Zigbee/ASIC_32/syn/generated_files/fast/sdc/zigbee_F.sdc, \
#   line 70
set_output_delay -clock [get_clocks {clk}] -max 6.25 [get_ports {tx_imag[1]}]
# /home/ICer/Desktop/shared_folder/ROBO/Zigbee/ASIC_32/syn/generated_files/fast/sdc/zigbee_F.sdc, \
#   line 71
set_output_delay -clock [get_clocks {clk}] -max 6.25 [get_ports {tx_imag[0]}]
# /home/ICer/Desktop/shared_folder/ROBO/Zigbee/ASIC_32/syn/generated_files/fast/sdc/zigbee_F.sdc, \
#   line 72
set_output_delay -clock [get_clocks {clk}] -max 6.25 [get_ports {tx_done}]
set_max_transition 3.63662 [current_design]
set_max_capacitance 100 [current_design]
