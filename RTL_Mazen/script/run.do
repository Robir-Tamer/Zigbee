# =====================================================================
# ModelSim / Questa Simulation Do File for RTL_Mazen
# =====================================================================

# 1. Create and map the working library
if [file exists work] {
    vdel -all -lib work
}
vlib work
vmap work work

# 2. Compile RTL Source Files (Order: low-level blocks first, then top)
echo "--- Compiling RTL Files ---"
vlog -work work ../rtl/form_ppdu.v
vlog -work work ../rtl/interleaver.v
vlog -work work ../rtl/preamble_sfd_gen.v
vlog -work work ../rtl/symbol_mapper.v
vlog -work work ../rtl/sync_fifo_hybrid.v
vlog -work work ../rtl/top_sym_to_ppdu.v

# 3. Compile Testbench File
echo "--- Compiling Testbench ---"
vlog -work work ../tb/tb_top_sym_to_ppdu.v

# 4. Load the Simulation (Optimized/Top level testbench)
echo "--- Loading Simulation ---"
vsim -voptargs=+acc work.tb_top_sym_to_ppdu

# 5. Add Waves to the Wave Window with custom colors and radix
echo "--- Setting up Wave Window ---"

# Group: System Signals (Clock, Reset, Mode)
add wave -noupdate -color "Orange" -radix binary /tb_top_sym_to_ppdu/u_ut/clk
add wave -noupdate -color "Orange" -radix binary /tb_top_sym_to_ppdu/u_ut/rst
add wave -noupdate -color "Yellow" -radix binary /tb_top_sym_to_ppdu/u_ut/mode

# Group: Control & Inputs (Valid, Even/Odd Symbol Inputs)
add wave -noupdate -color "Light Blue" -radix binary /tb_top_sym_to_ppdu/u_ut/i_valid
add wave -noupdate -color "Cyan"       -radix hexadecimal /tb_top_sym_to_ppdu/u_ut/i_data_even
add wave -noupdate -color "Cyan"       -radix hexadecimal /tb_top_sym_to_ppdu/u_ut/i_data_odd

# Group: Internal Generation
add wave -noupdate -color "Dark Orchid" -radix hexadecimal /tb_top_sym_to_ppdu/u_ut/preamble_sfd_wire

# Group: Final PPDU Outputs (Highlighted in Green for easy sequence observation)
add wave -noupdate -color "Light Green" -radix binary /tb_top_sym_to_ppdu/u_ut/o_valid
add wave -noupdate -color "Light Green" -radix binary /tb_top_sym_to_ppdu/u_ut/o_i
add wave -noupdate -color "Light Green" -radix binary /tb_top_sym_to_ppdu/u_ut/o_q

# 6. Run Simulation
echo "--- Running Simulation ---"
run -all

# Zoom to fit wave window
wave zoom full