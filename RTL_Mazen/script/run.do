# =====================================================================
# ModelSim / Questa Simulation Do File for RTL_Mazen
# =====================================================================

# 1. Create and map the working library
if [file exists work] {
    vdel -all -lib work
}
vlib work
vmap work work

# 2. Compile RTL Source Files
echo "--- Compiling RTL Files ---"
vlog -work work ../rtl/form_ppdu.v
vlog -work work ../rtl/interleaver.v
vlog -work work ../rtl/preamble_sfd_gen.v
vlog -work work ../rtl/symbol_mapper.v
vlog -work work ../rtl/FIFO_mem.v
vlog -work work ../rtl/top_sym_to_ppdu.v

# 3. Compile Testbench File
echo "--- Compiling Testbench ---"
vlog -work work ../tb/tb_top_sym_to_ppdu.v

# 4. Load Simulation
echo "--- Loading Simulation ---"
vsim -voptargs=+acc work.tb_top_sym_to_ppdu

# 5. Add Waves to Wave Window with clear descriptions per module
echo "--- Setting up Wave Window ---"

# --- SYSTEM SIGNALS ---
add wave -noupdate -divider "=== SYSTEM SIGNALS ==="
add wave -noupdate -color "Orange" -radix binary /tb_top_sym_to_ppdu/u_ut/clk
add wave -noupdate -color "Light Blue" -radix binary /tb_top_sym_to_ppdu/u_ut/i_valid

# --- TOP INPUTS ---
add wave -noupdate -divider "=== TOP INPUT SYMBOLS ==="
add wave -noupdate -color "Cyan" -radix hexadecimal /tb_top_sym_to_ppdu/u_ut/i_data_even

# --- 1. SYMBOL MAPPER (Even & Odd) ---
add wave -noupdate -divider "=== 1. SYMBOL MAPPER (Internal) ==="
add wave -noupdate -color "Pink" -radix binary      /tb_top_sym_to_ppdu/u_ut/u_symbol_mapper_even/i_valid
add wave -noupdate -color "Pink" -radix hexadecimal /tb_top_sym_to_ppdu/u_ut/u_symbol_mapper_even/o_data
add wave -noupdate -color "Pink" -radix binary      /tb_top_sym_to_ppdu/u_ut/u_symbol_mapper_even/o_valid

# --- 2. SYNC FIFO (Even & Odd) ---
add wave -noupdate -divider "=== 2. SYNC FIFO (Internal) ==="
add wave -noupdate -color "Khaki" -radix binary      /tb_top_sym_to_ppdu/u_ut/u_sync_fifo_even/wr_en
add wave -noupdate -color "Khaki" -radix binary      /tb_top_sym_to_ppdu/u_ut/u_sync_fifo_even/rd_en
add wave -noupdate -color "Khaki" -radix binary      /tb_top_sym_to_ppdu/u_ut/u_sync_fifo_even/empty_flag
add wave -noupdate -color "Khaki" -radix hexadecimal /tb_top_sym_to_ppdu/u_ut/u_sync_fifo_even/dout


# --- 3. INTERLEAVER (Even & Odd) ---
add wave -noupdate -divider "=== 3. INTERLEAVER (Even & Odd) ==="
add wave -noupdate -color "Gold" -radix binary      /tb_top_sym_to_ppdu/u_ut/u_interleaver_even/i_valid
add wave -noupdate -color "Gold" -radix hexadecimal /tb_top_sym_to_ppdu/u_ut/u_interleaver_even/i_data
# Interleaver Internal Signals (Added)
add wave -noupdate -color "Yellow" -radix binary      /tb_top_sym_to_ppdu/u_ut/u_interleaver_even/gen_interleaver_hybrid/busy
add wave -noupdate -color "Yellow" -radix binary      /tb_top_sym_to_ppdu/u_ut/u_interleaver_even/gen_interleaver_hybrid/cycle_flag
add wave -noupdate -color "Yellow" -radix unsigned    /tb_top_sym_to_ppdu/u_ut/u_interleaver_even/gen_interleaver_hybrid/bit_count
add wave -noupdate -color "Yellow" -radix hexadecimal /tb_top_sym_to_ppdu/u_ut/u_interleaver_even/gen_interleaver_hybrid/shift_reg
# Interleaver Outputs
add wave -noupdate -color "Gold" -radix binary      /tb_top_sym_to_ppdu/u_ut/u_interleaver_even/o_data
add wave -noupdate -color "Gold" -radix binary      /tb_top_sym_to_ppdu/u_ut/u_interleaver_even/o_valid


# --- 4. PREAMBLE & FORM PPDU ---
add wave -noupdate -divider "=== 4. FORM PPDU (Final Output) ==="
add wave -noupdate -color "Light Green" -radix binary      /tb_top_sym_to_ppdu/u_ut/o_valid
add wave -noupdate -color "Light Green" -radix binary      /tb_top_sym_to_ppdu/u_ut/o_i

# 6. Run Simulation
echo "--- Running Simulation ---"
run -all

# Zoom to fit wave window
wave zoom full