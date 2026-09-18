# ==============================================================================
# Script: run_H.do
# Project: Full CSS PHY Chain Verification -- Hybrid (Dual-Rate) TB
# Tool: QuestaSim / ModelSim
# ==============================================================================
onerror {resume}

# 1. Quit current simulation safely
quit -sim -f

# 2. Re-create and Map Working Library
if {[file exists work]} {
    catch {vdel -lib work -all}
}
vlib work
vmap work work

# 3. Compile Design RTL Files and Testbench
vlog -work work ../RTL/*.*v
vlog -sv -work work ../TB/*.*v

# 4. Load Simulation
vsim -voptargs=+acc work.zigbee_H_tb

# ==============================================================================
# 5. DEFINE FIXED-POINT RADICES
# ==============================================================================
catch {radix delete q1_4}
radix define q1_4 -fixed -signed -fraction 4    ;# 6-bit: 1 sign + 1 int + 4 frac

catch {radix delete q3_4}
radix define q3_4 -fixed -signed -fraction 4    ;# 8-bit: 1 sign + 3 int + 4 frac

# ==============================================================================
# 6. WAVEFORM CONFIGURATION & COLOR SETUP
# ==============================================================================
configure wave -namecolwidth  260
configure wave -valuecolwidth 120
configure wave -justifyvalue right
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 6
configure wave -childrowmargin 4

# --- GROUP 1: SYSTEM CONTROLS ---
add wave -divider "System Controls"
add wave -color Yellow /zigbee_H_tb/clk
add wave -color Red    /zigbee_H_tb/rst_n

# --- GROUP 2: PARAMETERS ---
add wave -divider "Parameters"
add wave -color White -radix ascii    /zigbee_H_tb/rate_mode
add wave -color White -radix unsigned /zigbee_H_tb/wl
add wave -color White -radix unsigned /zigbee_H_tb/fl
add wave -color White -radix unsigned /zigbee_H_tb/payload_w
add wave -color White -radix unsigned /zigbee_H_tb/max_payload_length
add wave -color White -radix unsigned /zigbee_H_tb/header_length
add wave -color White -radix unsigned /zigbee_H_tb/dqpsk_fifo_w
add wave -color White -radix unsigned /zigbee_H_tb/dqpsk_fifo_depth

# --- GROUP 3: TB / RATE-SWITCH CONTROL (HYBRID-SPECIFIC) ---
add wave -divider "TB / Rate-Switch Control"
add wave -color Orange /zigbee_H_tb/test_case
add wave -color Orange /zigbee_H_tb/test_mode
add wave -color Orange /zigbee_H_tb/dut/my_controller/mode
add wave              /zigbee_H_tb/dut/my_controller/zero_pad_en

# --- GROUP 4: INPUT INTERFACE ---
add wave -divider "Input Interface"
add wave -color White -radix binary  /zigbee_H_tb/payload
add wave -color White -radix decimal /zigbee_H_tb/payload_length
add wave -color White -radix binary  /zigbee_H_tb/start_tx

# --- GROUP 5: PAYLOAD RAM / COUNTER ---
add wave -divider "Payload RAM & Counter"
add wave -group "Payload_Counter" /zigbee_H_tb/dut/PayLoad_Counter/wr_en
add wave -group "Payload_Counter" /zigbee_H_tb/dut/PayLoad_Counter/wr_data
add wave -group "Payload_Counter" /zigbee_H_tb/dut/PayLoad_Counter/counter
add wave -radix binary /zigbee_H_tb/dut/payload_ram/dout
add wave             /zigbee_H_tb/dut/payload_ram/empty_flag

# --- GROUP 6: ZERO PADDING ---
add wave -divider "Zero Padding"
add wave -color Magenta -radix binary /zigbee_H_tb/dut/ZeroPadding/data_i
add wave -color Magenta               /zigbee_H_tb/dut/ZeroPadding/valid
add wave                              /zigbee_H_tb/dut/ZeroPadding/data_o
add wave                              /zigbee_H_tb/dut/ZeroPadding/done_bytes

# --- GROUP 7: DEMUX ---
add wave -divider "Demux (I/Q Split)"
add wave -color Yellow -radix binary /zigbee_H_tb/dut/DEMUX/e_bits
add wave -color Wheat  -radix binary /zigbee_H_tb/dut/DEMUX/o_bits
add wave -color Magenta              /zigbee_H_tb/dut/DEMUX/valid

# --- GROUP 8: SYMBOL MAPPER -> PPDU (EVEN/I PATH) ---
add wave -divider "Symbol Mapper -> PPDU : Even (I) Path"
add wave -group "Even_Path" -radix binary /zigbee_H_tb/dut/symbol_mapper_to_ppdu/i_data_even
add wave -group "Even_Path" -group "Symbol_Mapper" /zigbee_H_tb/dut/symbol_mapper_to_ppdu/mapper_even_valid
add wave -group "Even_Path" -group "Symbol_Mapper" -radix hexadecimal /zigbee_H_tb/dut/symbol_mapper_to_ppdu/mapper_even_data
add wave -group "Even_Path" -group "FIFO"          -radix binary /zigbee_H_tb/dut/symbol_mapper_to_ppdu/u_sync_fifo_even/dout
add wave -group "Even_Path" -group "Interleaver" -color Magenta /zigbee_H_tb/dut/symbol_mapper_to_ppdu/interleaver_even_valid
add wave -group "Even_Path" -group "Interleaver" -radix binary  /zigbee_H_tb/dut/symbol_mapper_to_ppdu/interleaver_even_data
add wave -group "Even_Path" -group "Interleaver" -group "Internals" /zigbee_H_tb/dut/symbol_mapper_to_ppdu/u_interleaver_even/i_valid
add wave -group "Even_Path" -group "Interleaver" -group "Internals" /zigbee_H_tb/dut/symbol_mapper_to_ppdu/u_interleaver_even/o_valid
add wave -group "Even_Path" -group "Interleaver" -group "Internals" /zigbee_H_tb/dut/symbol_mapper_to_ppdu/u_interleaver_even/next_item
add wave -group "Even_Path" -group "Interleaver" -group "Internals" /zigbee_H_tb/dut/symbol_mapper_to_ppdu/u_interleaver_even/tx_done
add wave -group "Even_Path" -group "Interleaver" -group "Internals" -radix hexadecimal /zigbee_H_tb/dut/symbol_mapper_to_ppdu/u_interleaver_even/gen_interleaver_250kbps/shift_reg
add wave -group "Even_Path" -group "Interleaver" -group "Internals" /zigbee_H_tb/dut/symbol_mapper_to_ppdu/u_interleaver_even/gen_interleaver_250kbps/busy
add wave -group "Even_Path" -group "Interleaver" -group "Internals" /zigbee_H_tb/dut/symbol_mapper_to_ppdu/u_interleaver_even/gen_interleaver_250kbps/cycle_flag

# --- GROUP 9: SYMBOL MAPPER -> PPDU (ODD/Q PATH) ---
add wave -divider "Symbol Mapper -> PPDU : Odd (Q) Path"
add wave -group "Odd_Path" -radix binary /zigbee_H_tb/dut/symbol_mapper_to_ppdu/i_data_odd
add wave -group "Odd_Path" -group "Symbol_Mapper" /zigbee_H_tb/dut/symbol_mapper_to_ppdu/mapper_odd_valid
add wave -group "Odd_Path" -group "Symbol_Mapper" -radix hexadecimal /zigbee_H_tb/dut/symbol_mapper_to_ppdu/mapper_odd_data
add wave -group "Odd_Path" -group "FIFO"          -radix binary /zigbee_H_tb/dut/symbol_mapper_to_ppdu/u_sync_fifo_odd/dout
add wave -group "Odd_Path" -group "Interleaver" -color Magenta /zigbee_H_tb/dut/symbol_mapper_to_ppdu/interleaver_odd_valid
add wave -group "Odd_Path" -group "Interleaver" -radix binary  /zigbee_H_tb/dut/symbol_mapper_to_ppdu/interleaver_odd_data

# --- GROUP 10: PPDU (PREAMBLE + SFD FRAMING) ---
add wave -divider "PPDU Framing (Preamble + SFD)"
add wave -group "PPDU" -radix binary  /zigbee_H_tb/dut/symbol_mapper_to_ppdu/preamble_sfd_wire
add wave -group "PPDU" -color Magenta /zigbee_H_tb/dut/symbol_mapper_to_ppdu/o_valid
add wave -group "PPDU" -radix binary  /zigbee_H_tb/dut/symbol_mapper_to_ppdu/o_i
add wave -group "PPDU" -radix binary  /zigbee_H_tb/dut/symbol_mapper_to_ppdu/o_q

# --- GROUP 11: QPSK MAPPER ---
add wave -divider "QPSK Mapper"
add wave               /zigbee_H_tb/dut/QPSK/i_valid
add wave -color Yellow  /zigbee_H_tb/dut/QPSK/i
add wave -color Wheat   /zigbee_H_tb/dut/QPSK/q
add wave               /zigbee_H_tb/dut/QPSK/valid
add wave -radix decimal /zigbee_H_tb/dut/QPSK/out_real
add wave -radix decimal /zigbee_H_tb/dut/QPSK/out_imag

# --- GROUP 12: DQPSK ENCODER OUTPUT ---
add wave -divider "DQPSK Encoder Output"
add wave                /zigbee_H_tb/dut/DQPSK_CSK/i_valid
add wave -color Magenta -radix decimal /zigbee_H_tb/dut/DQPSK_CSK/Real_o
add wave -color Magenta -radix decimal /zigbee_H_tb/dut/DQPSK_CSK/Imag_o
add wave                /zigbee_H_tb/dut/DQPSK_CSK/valid

# --- GROUP 13: SYNC FIFO (I/Q) HANDSHAKE ---
add wave -divider "Sync FIFO (I/Q) Handshake"
add wave -color Pink -radix decimal /zigbee_H_tb/dut/DQPSK_CSK/S_R
add wave -color Pink -radix decimal /zigbee_H_tb/dut/DQPSK_CSK/S_I
add wave -color Khaki                /zigbee_H_tb/dut/DQPSK_CSK/next_item
add wave -color Grey                 /zigbee_H_tb/dut/DQPSK_CSK/empty_flag_real
add wave -color Grey                 /zigbee_H_tb/dut/DQPSK_CSK/full_flag_real
add wave -color Grey                 /zigbee_H_tb/dut/DQPSK_CSK/empty_flag_imag
add wave -color Grey                 /zigbee_H_tb/dut/DQPSK_CSK/full_flag_imag
add wave                             /zigbee_H_tb/dut/DQPSK_CSK/en

# --- GROUP 14: CSK OUTPUT (FIXED POINT Q1.4) ---
add wave -divider "CSK Output (Fixed Point Q1.4)"
add wave -color Khaki             /zigbee_H_tb/dut/DQPSK_CSK/csk_running
add wave -color Lime  -radix q1_4 /zigbee_H_tb/dut/DQPSK_CSK/csk_out_r
add wave -color Coral -radix q1_4 /zigbee_H_tb/dut/DQPSK_CSK/csk_out_i

# --- GROUP 15: CSK OUTPUT (ANALOG WAVEFORM VIEW) ---
add wave -divider "CSK Output (Analog Wave View)"
add wave -color Lime  -radix q1_4 -format Analog-Step -height 55 -max 1.0 -min -1.0 /zigbee_H_tb/dut/DQPSK_CSK/csk_out_r
add wave -color Coral -radix q1_4 -format Analog-Step -height 55 -max 1.0 -min -1.0 /zigbee_H_tb/dut/DQPSK_CSK/csk_out_i

# --- GROUP 16: TX DONE CONTROL CHAIN ---
add wave -divider "Tx Done Control Chain"
add wave -color Yellow /zigbee_H_tb/dut/DQPSK_CSK/ever_run
add wave -color Yellow /zigbee_H_tb/dut/DQPSK_CSK/tx_done_level
add wave -color Orange /zigbee_H_tb/dut/DQPSK_CSK/tx_done_raw

# --- GROUP 17: TX DATA OUTPUT (FIXED POINT Q3.4) ---
add wave -divider "Tx Data Output (Fixed Point Q3.4)"
add wave -color Chartreuse -radix q3_4 /zigbee_H_tb/tx_real
add wave -color Cyan       -radix q3_4 /zigbee_H_tb/tx_imag

# --- GROUP 18: TX DATA OUTPUT (ANALOG WAVEFORM VIEW) ---
add wave -divider "Tx Data Output (Analog Wave View)"
add wave -color Chartreuse -radix q3_4 -format Analog-Step -height 85 -max 8.0 -min -8.0 /zigbee_H_tb/tx_real
add wave -color Cyan       -radix q3_4 -format Analog-Step -height 85 -max 8.0 -min -8.0 /zigbee_H_tb/tx_imag

# --- GROUP 19: TRANSMISSION STATUS ---
add wave -divider "Tx Status Handshake"
add wave -color Yellow /zigbee_H_tb/tx_done

# ==============================================================================
# 7. EXECUTION, ZOOM & OUTPUT DUMP
# ==============================================================================
run -all
wave zoomfull

do ../Scripts/save_Tx_out.tcl "Hybrid"
