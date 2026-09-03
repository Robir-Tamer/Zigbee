# ==============================================================================
# ModelSim / QuestaSim Automated Run Script for DQPSK Testbench
# ==============================================================================

# 1. Clean environment and prepare workspace
quit -sim
cls

vlib work
vmap work work

# 2. Compile Design under Test (DUT) and Testbench
vlog -sv ../RTL/DQPSK.v
vlog -sv ../TB/DQPSK_TB.sv

# 3. Elaborate with full visibility (+acc) for internal registers
vsim -voptargs=+acc work.tb_DQPSK

# 4. Waveform Window Display Configuration
configure wave -namecolwidth  220
configure wave -valuecolwidth 100
configure wave -justifyvalue right
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0

# ==============================================================================
# WAVEFORM SIGNAL MAPPING & STYLING
# ==============================================================================

# --- SECTION 1: Clock & Control ---
add wave -divider -height 25 "System & Control"
add wave -color "Yellow"       -label "Clock"          /tb_DQPSK/clk
add wave -color "Orange"       -label "Reset (Active L)" /tb_DQPSK/rst_n
add wave -color "Light Cyan"   -label "Input Valid"     /tb_DQPSK/i_valid

# --- SECTION 2: Input Symbols ---
add wave -divider -height 25 "Inputs (QPSK Axis)"
add wave -color "Cyan" -radix decimal -label "Real In" /tb_DQPSK/Real
add wave -color "Cyan" -radix decimal -label "Imag In" /tb_DQPSK/Imag

# --- SECTION 3: Internal Registers (4-Symbol Delay Line) ---
add wave -divider -height 25 "Internal State (DUT Delay Ring)"
add wave -color "Magenta" -radix decimal -label "Real_FF [3:0]" /tb_DQPSK/dut/Real_FF
add wave -color "Magenta" -radix decimal -label "Imag_FF [3:0]" /tb_DQPSK/dut/Imag_FF

# --- SECTION 4: Output Signals ---
add wave -divider -height 25 "Outputs (DQPSK)"
add wave -color "Lime Green"                     -label "Output Valid" /tb_DQPSK/valid
add wave -color "Green"       -radix decimal -label "Real Out"    /tb_DQPSK/Real_o
add wave -color "Green"       -radix decimal -label "Imag Out"    /tb_DQPSK/Imag_o

# --- SECTION 5: Testbench Checker & Diagnostics ---
add wave -divider -height 25 "Verification Statistics"
add wave -color "White" -radix decimal -label "Symbol Count" /tb_DQPSK/symbol_counter
add wave -color "Lime"  -radix decimal -label "Pass Count"   /tb_DQPSK/pass_count
add wave -color "Red"   -radix decimal -label "Fail Count"   /tb_DQPSK/fail_count

# ==============================================================================
# 5. Run Simulation & Fit Waveform
# ==============================================================================
run -all
wave zoomfull