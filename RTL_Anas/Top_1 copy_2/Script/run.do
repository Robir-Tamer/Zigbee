# ==============================================================================
# Script: run.do
# Project: Complete Top Module Verification
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

# 3. Compile Design RTL Files and Testbench
vlog -work work ../RTL/CSK_GEN.V
vlog -work work ../RTL/DQPSK.V
vlog -work work ../RTL/FIFO_mem.V
vlog -work work ../RTL/posedge_detector.V
vlog -work work ../RTL/Top.V
vlog -sv -work work ../TB/Top_TB.sv

# 4. Load Simulation (Exact Module Case: Top_TB)
vsim -voptargs=+acc work.Top_TB

# ==============================================================================
# 5. DEFINE FIXED-POINT RADICES
# ==============================================================================
# Q1.4: 6-bit Signed (1 Sign bit + 1 Integer bit + 4 Fractional bits, Range: [-2.0, 1.9375])
# This matches the CSK/chirp ROM's actual verified format -- NOT Q1.5. Using
# -fraction 5 here would silently divide every value by 32 instead of 16,
# showing exactly half the true magnitude (this was the bug being fixed).
catch {radix delete q1_4}
radix define q1_4 -fixed -signed -fraction 4

# Q3.4: 8-bit Signed (1 Sign bit + 3 Integer bits + 4 Fractional bits, Range: [-8.0, 7.9375])
catch {radix delete q3_4}
radix define q3_4 -fixed -signed -fraction 4

# ==============================================================================
# 6. WAVEFORM CONFIGURATION & COLOR SETUP
# ==============================================================================

# Configure Wave Window Display
configure wave -namecolwidth  220
configure wave -valuecolwidth 120
configure wave -justifyvalue right
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 6
configure wave -childrowmargin 4

# --- GROUP 1: SYSTEM CONTROLS ---
add wave -divider "System Controls"
add wave -color Yellow         -radix binary   /Top_TB/clk
add wave -color Red            -radix binary   /Top_TB/rst_n

# --- GROUP 2: INPUT INTERFACE ---
add wave -divider "Input Interface"
add wave -color White          -radix binary   /Top_TB/i_valid
add wave -color White          -radix decimal  /Top_TB/Real
add wave -color White          -radix decimal  /Top_TB/Imag

# --- GROUP 3: DQPSK ENCODER STAGE ---
add wave -divider "DQPSK Encoder Output"
add wave -color Magenta        -radix binary   /Top_TB/Top_DUT/valid
add wave -color Magenta        -radix decimal  /Top_TB/Top_DUT/DQPSK_DUT/Real_o
add wave -color Magenta        -radix decimal  /Top_TB/Top_DUT/DQPSK_DUT/Imag_o

# --- GROUP 4: FIFO BUFFER MEMORY ---
add wave -divider "FIFO Handshake & Memory"
add wave -color Pink           -radix decimal  /Top_TB/Top_DUT/Real_Sync_FIFO/dout
add wave -color Pink           -radix decimal  /Top_TB/Top_DUT/Imag_Sync_FIFO/dout
add wave -color Grey           -radix binary   /Top_TB/Top_DUT/empty_flag_real
add wave -color Grey           -radix binary   /Top_TB/Top_DUT/full_flag_real

# --- GROUP 5: CSK OUT (FIXED POINT Q1.4) ---
add wave -divider "CSK Output (Fixed Point Q1.4)"
add wave -color Khaki          -radix binary   /Top_TB/Top_DUT/csk_running
add wave -color Khaki          -radix binary   /Top_TB/Top_DUT/next_item
add wave -color Lime           -radix q1_4     /Top_TB/Top_DUT/CSK_GEN_DUT/csk_out_r
add wave -color Coral          -radix q1_4     /Top_TB/Top_DUT/CSK_GEN_DUT/csk_out_i

# --- GROUP 6: CSK OUT (ANALOG WAVEFORM VIEW) ---
add wave -divider "CSK Output (Analog Wave View)"
add wave -color Lime   -radix q1_4 -format Analog-Step -height 55 -max 1.0 -min -1.0 /Top_TB/Top_DUT/CSK_GEN_DUT/csk_out_r
add wave -color Coral  -radix q1_4 -format Analog-Step -height 55 -max 1.0 -min -1.0 /Top_TB/Top_DUT/CSK_GEN_DUT/csk_out_i

# --- GROUP 7: TX DATA OUTPUT (FIXED POINT Q3.4 DISPLAY) ---
add wave -divider "Tx Data Output (Fixed Point Q3.4)"
add wave -color Chartreuse     -radix q3_4     /Top_TB/tx_real
add wave -color Cyan           -radix q3_4     /Top_TB/tx_imag

# --- GROUP 8: TX DATA OUTPUT (ANALOG WAVEFORM VIEW) ---
add wave -divider "Tx Data Output (Analog Wave View)"
add wave -color Chartreuse -radix q3_4 -format Analog-Step -height 85 -max 8.0 -min -8.0 /Top_TB/tx_real
add wave -color Cyan       -radix q3_4 -format Analog-Step -height 85 -max 8.0 -min -8.0 /Top_TB/tx_imag

# --- GROUP 9: TRANSMISSION STATUS ---
add wave -divider "Tx Status Handshake"
add wave -color Yellow         -radix binary   /Top_TB/tx_done
add wave -color Orange         -radix binary   /Top_TB/tx_end

# ==============================================================================
# 7. EXECUTION & ZOOM SETUP
# ==============================================================================
run -all

# Auto-fit Wave Window
wave zoomfull
