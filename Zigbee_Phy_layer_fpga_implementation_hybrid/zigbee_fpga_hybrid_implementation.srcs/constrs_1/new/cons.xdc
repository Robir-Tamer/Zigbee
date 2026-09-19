###################### Physical Constraints #######################

# Primary System Clock (100 MHz - Bank 13 / GCLK)
set_property PACKAGE_PIN Y9 [get_ports {clk}]

# UART RX Pin (PMOD JC - Pin AB6)
set_property PACKAGE_PIN AB6  [get_ports rx]

# Reset Button (BTNC - Bank 34, 1.8V)
set_property PACKAGE_PIN P16 [get_ports rst_n]

# 8-bit Payload Length Slide Switches (SW0 - SW7 - Bank 35, 1.8V)
set_property PACKAGE_PIN F22 [get_ports {payload_length[0]}]
set_property PACKAGE_PIN G22 [get_ports {payload_length[1]}]
set_property PACKAGE_PIN H22 [get_ports {payload_length[2]}]
set_property PACKAGE_PIN F21 [get_ports {payload_length[3]}]
set_property PACKAGE_PIN H19 [get_ports {payload_length[4]}]
set_property PACKAGE_PIN H18 [get_ports {payload_length[5]}]
set_property PACKAGE_PIN H17 [get_ports {payload_length[6]}]

# TX Done Indicator LED (LD0 - Bank 33, 3.3V)
set_property PACKAGE_PIN T22 [get_ports tx_done]

# TX Real Outputs (PMOD JB - 3.3V)
set_property PACKAGE_PIN W12  [get_ports {tx_real[0]}]
set_property PACKAGE_PIN W11  [get_ports {tx_real[1]}]
set_property PACKAGE_PIN V10  [get_ports {tx_real[2]}]
set_property PACKAGE_PIN W8   [get_ports {tx_real[3]}]
set_property PACKAGE_PIN V12  [get_ports {tx_real[4]}]
set_property PACKAGE_PIN W10  [get_ports {tx_real[5]}]
set_property PACKAGE_PIN V9   [get_ports {tx_real[6]}]
set_property PACKAGE_PIN V8   [get_ports {tx_real[7]}]

# TX Imaginary Outputs (PMOD JA - 3.3V)
set_property PACKAGE_PIN Y11  [get_ports {tx_imag[0]}]
set_property PACKAGE_PIN AA11 [get_ports {tx_imag[1]}]
set_property PACKAGE_PIN Y10  [get_ports {tx_imag[2]}]
set_property PACKAGE_PIN AA9  [get_ports {tx_imag[3]}]
set_property PACKAGE_PIN AB11 [get_ports {tx_imag[4]}]
set_property PACKAGE_PIN AB10 [get_ports {tx_imag[5]}]
set_property PACKAGE_PIN AB9  [get_ports {tx_imag[6]}]
set_property PACKAGE_PIN AA8  [get_ports {tx_imag[7]}]

# Explicit IO Standards (Targeting ports individually to prevent bank-object lookup failures)
set_property IOSTANDARD LVCMOS33 [get_ports {clk rx tx_done tx_real[*] tx_imag[*]}]
set_property IOSTANDARD LVCMOS18 [get_ports {rst_n payload_length[*]}]

###################### Timing Constraints #######################

# Primary Clock (100 MHz)
create_clock -name clk -period 10.000 [get_ports clk]

# Generated 32 MHz Clock by PLL
create_generated_clock -name clk_32 \
    -source [get_pins pll_0/clk_in] \
    -multiply_by 8 \
    -divide_by 25 \
    [get_pins pll_0/clk_32]
    
# False Paths
set_false_path -from [all_inputs]
set_false_path -to [all_outputs]

# Input & Output Delays
set_input_delay  -clock [get_clocks clk_32] -max 0.2 [get_ports {rx payload_length[*]}]
set_input_delay  -clock [get_clocks clk_32] -min 0.1 [get_ports {rx payload_length[*]}]
set_output_delay -clock [get_clocks clk_32] -max 0.2 [all_outputs]
set_output_delay -clock [get_clocks clk_32] -min 0.1 [all_outputs]