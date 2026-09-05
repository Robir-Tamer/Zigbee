# ==============================================================================
#  ModelSim / QuestaSim Automated Simulation & Waveform DO File
#  Module: FIFO_mem (SystemVerilog)
# ==============================================================================

# 1. Clean and Setup Library
if {[file exists work]} {
    vdel -lib work -all
}
vlib work
vmap work work

# 2. Compile Design and Testbench (.sv extensions with SystemVerilog support)
vlog -sv ../RTL/FIFO_mem.v
vlog -sv ../TB/FIFO_mem_TB.sv

# 3. Load Simulation with Full Visibility (+acc)
vsim -voptargs=+acc work.FIFO_mem_TB

# 4. Configure Waveform Window View & Layout Settings
configure wave -namecolwidth  210
configure wave -valuecolwidth 100
configure wave -justifyvalue right
configure wave -signalnamewidth 1        ; # Displays short signal names
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 6
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 10ns
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns

# 5. Add Signals with Visual Dividers, Color Coding, and Custom Radices

# --- SYSTEM CLOCK & RESET ---
add wave -divider -height 25 " SYSTEM CLOCK & RESET "
add wave -noupdate -color "Yellow"       -radix bin /FIFO_mem_TB/clk
add wave -noupdate -color "Cyan"         -radix bin /FIFO_mem_TB/rst_n

# --- CONTROL SIGNALS ---
add wave -divider -height 25 " CONTROL INTERFACE "
add wave -noupdate -color "Lime"         -radix bin /FIFO_mem_TB/wr_en
add wave -noupdate -color "Orange"       -radix bin /FIFO_mem_TB/rd_en

# --- DATA BUS INTERFACE ---
add wave -divider -height 25 " DATA INTERFACE "
add wave -noupdate -color "Magenta"      -radix hex /FIFO_mem_TB/din
add wave -noupdate -color "Light Blue"   -radix hex /FIFO_mem_TB/dout

# --- STATUS FLAGS ---
add wave -divider -height 25 " STATUS FLAGS "
add wave -noupdate -color "Red"          -radix bin /FIFO_mem_TB/full_flag
add wave -noupdate -color "Green"        -radix bin /FIFO_mem_TB/empty_flag

# --- DUT INTERNAL POINTERS ---
add wave -divider -height 25 " INTERNAL POINTERS "
add wave -noupdate -color "Gold"         -radix unsigned /FIFO_mem_TB/dut/wr_in_addr
add wave -noupdate -color "Orchid"       -radix unsigned /FIFO_mem_TB/dut/rd_from_addr

# --- DUT INTERNAL MEMORY ARRAY ---
add wave -divider -height 25 " INTERNAL MEMORY MATRIX "
add wave -noupdate -color "Khaki"        -radix hex      /FIFO_mem_TB/dut/mem

# 6. Run Simulation and Adjust View
run -all
wave zoomfull