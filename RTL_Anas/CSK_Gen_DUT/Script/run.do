# ==============================================================================
# Script: run.do
# Project: CSK Generator Verification
# Tool: QuestaSim / ModelSim
# ==============================================================================

# 1. Quit current simulation safely
quit -sim -f

# 2. Re-create and Map Working Library
if {[file exists work]} {
    catch {vdel -lib work -all}
}
vlib work
vmap work work

# 3. Compile Design RTL and Testbench
vlog -work work ../RTL/CSK_GEN.V
vlog -work work ../TB/CSK_GEN_TB.V

# 4. Load Simulation (Exact Module Case: CSK_GEN_tb)
vsim -voptargs=+acc work.CSK_GEN_tb

# ==============================================================================
# 5. DEFINE FIXED-POINT RADIX (Q1.5: 6-bit Signed, 5 Fractional Bits)
# ==============================================================================
catch {radix delete q1_5}
radix define q1_5 -fixed -signed -fraction 5

# ==============================================================================
# 6. WAVEFORM CONFIGURATION & COLOR SETUP
# ==============================================================================

# Configure Wave Window Display
configure wave -namecolwidth  220
configure wave -valuecolwidth 100
configure wave -justifyvalue right
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2

# --- GROUP 1: CLOCK & RESET / CONTROL ---
add wave -divider "System Controls"
add wave -color Yellow         -radix binary   /CSK_GEN_tb/clk
add wave -color Green          -radix binary   /CSK_GEN_tb/en

# --- GROUP 2: FIFO INTERFACE ---
add wave -divider "FIFO Handshake"
add wave -color Magenta        -radix binary   /CSK_GEN_tb/next_item

# --- GROUP 3: INTERNAL FSM & COUNTERS (DUT Hierarchy) ---
add wave -divider "Internal State & Address Tracking"
add wave -color Cyan           -radix unsigned /CSK_GEN_tb/dut/*

# --- GROUP 4: IQ DATA OUTPUTS (FIXED/FLOAT DISPLAY) ---
add wave -divider "IQ Data Output (Fixed Point)"
add wave -color Lime  -radix q1_5 /CSK_GEN_tb/csk_out_r
add wave -color Red   -radix q1_5 /CSK_GEN_tb/csk_out_i

# --- GROUP 5: ANALOG WAVEFORM VIEW ---
add wave -divider "IQ Data Output (Analog Wave View)"
add wave -color Lime  -radix q1_5 -format Analog-Step -height 50 -max 1.0 -min -1.0 /CSK_GEN_tb/csk_out_r
add wave -color Red   -radix q1_5 -format Analog-Step -height 50 -max 1.0 -min -1.0 /CSK_GEN_tb/csk_out_i

# ==============================================================================
# 7. EXECUTION & ZOOM SETUP
# ==============================================================================
run -all

# Auto-fit Wave Window
wave zoomfull