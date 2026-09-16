onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider Parameter
add wave -noupdate -radix ascii /zigbee_tb/rate_mode
add wave -noupdate -radix unsigned /zigbee_tb/wl
add wave -noupdate -radix unsigned /zigbee_tb/fl
add wave -noupdate -radix unsigned /zigbee_tb/payload_w
add wave -noupdate -radix unsigned /zigbee_tb/max_payload_length
add wave -noupdate -radix unsigned /zigbee_tb/header_length
add wave -noupdate -radix unsigned /zigbee_tb/dqpsk_fifo_w
add wave -noupdate -radix unsigned /zigbee_tb/dqpsk_fifo_depth
add wave -noupdate -divider Reset
add wave -noupdate /zigbee_tb/rst_n
add wave -noupdate -divider Clock
add wave -noupdate /zigbee_tb/clk
add wave -noupdate -divider Input
add wave -noupdate -color Yellow -radix binary /zigbee_tb/payload
add wave -noupdate /zigbee_tb/payload_length
add wave -noupdate /zigbee_tb/start_tx
add wave -noupdate -divider -height 30 PayLoad_Counter
add wave -noupdate -group PayLoad_counter /zigbee_tb/dut/PayLoad_Counter/wr_en
add wave -noupdate -group PayLoad_counter /zigbee_tb/dut/PayLoad_Counter/wr_data
add wave -noupdate -group PayLoad_counter /zigbee_tb/dut/PayLoad_Counter/counter
add wave -noupdate -divider PayLoad_SYNCH_FIFO
add wave -noupdate -radix binary /zigbee_tb/dut/payload_ram/dout
add wave -noupdate /zigbee_tb/dut/payload_ram/empty_flag
add wave -noupdate /zigbee_tb/dut/payload_ram/mem
add wave -noupdate -divider {Zero Padding}
add wave -noupdate -radix binary /zigbee_tb/dut/ZeroPadding/data_i
add wave -noupdate -color Magenta /zigbee_tb/dut/ZeroPadding/valid
add wave -noupdate /zigbee_tb/dut/ZeroPadding/data_o
add wave -noupdate /zigbee_tb/dut/ZeroPadding/done_bytes
add wave -noupdate /zigbee_tb/dut/ZeroPadding/empty_delayed
add wave -noupdate -expand -group useless /zigbee_tb/dut/ZeroPadding/empty
add wave -noupdate -expand -group useless /zigbee_tb/dut/ZeroPadding/next_item
add wave -noupdate -expand -group useless /zigbee_tb/dut/ZeroPadding/counter
add wave -noupdate -expand -group useless /zigbee_tb/dut/ZeroPadding/header_done
add wave -noupdate -expand -group useless /zigbee_tb/dut/ZeroPadding/byte_counter
add wave -noupdate -expand -group useless /zigbee_tb/dut/ZeroPadding/data_i_reg
add wave -noupdate -expand -group useless /zigbee_tb/dut/ZeroPadding/header_reg
add wave -noupdate -divider demux
add wave -noupdate /zigbee_tb/dut/DEMUX/rate_mode
add wave -noupdate /zigbee_tb/dut/DEMUX/clk
add wave -noupdate /zigbee_tb/dut/DEMUX/rst_n
add wave -noupdate /zigbee_tb/dut/DEMUX/mode
add wave -noupdate /zigbee_tb/dut/DEMUX/data_i
add wave -noupdate /zigbee_tb/dut/DEMUX/valid_i
add wave -noupdate /zigbee_tb/dut/DEMUX/e_bits
add wave -noupdate /zigbee_tb/dut/DEMUX/o_bits
add wave -noupdate /zigbee_tb/dut/DEMUX/valid
add wave -noupdate /zigbee_tb/dut/DEMUX/even
add wave -noupdate /zigbee_tb/dut/DEMUX/e_bits_reg
add wave -noupdate /zigbee_tb/dut/DEMUX/o_bits_reg
add wave -noupdate /zigbee_tb/dut/DEMUX/e_counter
add wave -noupdate /zigbee_tb/dut/DEMUX/o_counter
add wave -noupdate -divider {Sym_Mapper 2 PPDU}
add wave -noupdate /zigbee_tb/dut/symbol_mapper_to_ppdu/rate_mode
add wave -noupdate /zigbee_tb/dut/symbol_mapper_to_ppdu/DATA_WIDTH
add wave -noupdate /zigbee_tb/dut/symbol_mapper_to_ppdu/PREAMBLE_BITS
add wave -noupdate /zigbee_tb/dut/symbol_mapper_to_ppdu/TOTAL_BITS
add wave -noupdate /zigbee_tb/dut/symbol_mapper_to_ppdu/clk
add wave -noupdate /zigbee_tb/dut/symbol_mapper_to_ppdu/rst_n
add wave -noupdate /zigbee_tb/dut/symbol_mapper_to_ppdu/mode
add wave -noupdate /zigbee_tb/dut/symbol_mapper_to_ppdu/i_valid
add wave -noupdate /zigbee_tb/dut/symbol_mapper_to_ppdu/i_data_even
add wave -noupdate /zigbee_tb/dut/symbol_mapper_to_ppdu/i_data_odd
add wave -noupdate /zigbee_tb/dut/symbol_mapper_to_ppdu/o_i
add wave -noupdate /zigbee_tb/dut/symbol_mapper_to_ppdu/o_q
add wave -noupdate /zigbee_tb/dut/symbol_mapper_to_ppdu/o_valid
add wave -noupdate /zigbee_tb/dut/symbol_mapper_to_ppdu/interleaver_even_valid
add wave -noupdate /zigbee_tb/dut/symbol_mapper_to_ppdu/interleaver_odd_valid
add wave -noupdate /zigbee_tb/dut/symbol_mapper_to_ppdu/mapper_even_data
add wave -noupdate /zigbee_tb/dut/symbol_mapper_to_ppdu/mapper_even_valid
add wave -noupdate /zigbee_tb/dut/symbol_mapper_to_ppdu/fifo_even_dout
add wave -noupdate /zigbee_tb/dut/symbol_mapper_to_ppdu/fifo_even_full
add wave -noupdate /zigbee_tb/dut/symbol_mapper_to_ppdu/fifo_even_empty
add wave -noupdate /zigbee_tb/dut/symbol_mapper_to_ppdu/interleaver_even_data
add wave -noupdate /zigbee_tb/dut/symbol_mapper_to_ppdu/mapper_odd_data
add wave -noupdate /zigbee_tb/dut/symbol_mapper_to_ppdu/mapper_odd_valid
add wave -noupdate /zigbee_tb/dut/symbol_mapper_to_ppdu/fifo_odd_dout
add wave -noupdate /zigbee_tb/dut/symbol_mapper_to_ppdu/fifo_odd_full
add wave -noupdate /zigbee_tb/dut/symbol_mapper_to_ppdu/fifo_odd_empty
add wave -noupdate /zigbee_tb/dut/symbol_mapper_to_ppdu/interleaver_odd_data
add wave -noupdate /zigbee_tb/dut/symbol_mapper_to_ppdu/preamble_sfd_wire
add wave -noupdate /zigbee_tb/dut/symbol_mapper_to_ppdu/fifo_odd_rd_en_reg
add wave -noupdate /zigbee_tb/dut/symbol_mapper_to_ppdu/fifo_even_rd_en_reg
add wave -noupdate -divider QPSK
add wave -noupdate /zigbee_tb/dut/QPSK/clk
add wave -noupdate /zigbee_tb/dut/QPSK/rst_n
add wave -noupdate /zigbee_tb/dut/QPSK/i
add wave -noupdate /zigbee_tb/dut/QPSK/q
add wave -noupdate /zigbee_tb/dut/QPSK/i_valid
add wave -noupdate /zigbee_tb/dut/QPSK/valid
add wave -noupdate /zigbee_tb/dut/QPSK/out_real
add wave -noupdate /zigbee_tb/dut/QPSK/out_imag
add wave -noupdate -divider {DQPSK   2   out}
add wave -noupdate /zigbee_tb/dut/DQPSK_CSK/FIFO_DEPTH
add wave -noupdate /zigbee_tb/dut/DQPSK_CSK/FIFO_WIDTH
add wave -noupdate /zigbee_tb/dut/DQPSK_CSK/WL
add wave -noupdate /zigbee_tb/dut/DQPSK_CSK/clk
add wave -noupdate /zigbee_tb/dut/DQPSK_CSK/rst_n
add wave -noupdate /zigbee_tb/dut/DQPSK_CSK/Real
add wave -noupdate /zigbee_tb/dut/DQPSK_CSK/Imag
add wave -noupdate /zigbee_tb/dut/DQPSK_CSK/i_valid
add wave -noupdate /zigbee_tb/dut/DQPSK_CSK/tx_done
add wave -noupdate /zigbee_tb/dut/DQPSK_CSK/tx_real
add wave -noupdate /zigbee_tb/dut/DQPSK_CSK/tx_imag
add wave -noupdate /zigbee_tb/dut/DQPSK_CSK/valid
add wave -noupdate /zigbee_tb/dut/DQPSK_CSK/Real_o
add wave -noupdate /zigbee_tb/dut/DQPSK_CSK/Imag_o
add wave -noupdate /zigbee_tb/dut/DQPSK_CSK/full_flag_real
add wave -noupdate /zigbee_tb/dut/DQPSK_CSK/empty_flag_real
add wave -noupdate /zigbee_tb/dut/DQPSK_CSK/full_flag_imag
add wave -noupdate /zigbee_tb/dut/DQPSK_CSK/empty_flag_imag
add wave -noupdate /zigbee_tb/dut/DQPSK_CSK/FIFO_valid_real
add wave -noupdate /zigbee_tb/dut/DQPSK_CSK/FIFO_valid_imag
add wave -noupdate /zigbee_tb/dut/DQPSK_CSK/S_R
add wave -noupdate /zigbee_tb/dut/DQPSK_CSK/S_I
add wave -noupdate /zigbee_tb/dut/DQPSK_CSK/en
add wave -noupdate /zigbee_tb/dut/DQPSK_CSK/next_item
add wave -noupdate /zigbee_tb/dut/DQPSK_CSK/csk_out_r
add wave -noupdate /zigbee_tb/dut/DQPSK_CSK/csk_out_i
add wave -noupdate /zigbee_tb/dut/DQPSK_CSK/csk_running
add wave -noupdate /zigbee_tb/dut/DQPSK_CSK/tx_done_level
add wave -noupdate /zigbee_tb/dut/DQPSK_CSK/ever_run
add wave -noupdate /zigbee_tb/dut/DQPSK_CSK/tx_done_raw
add wave -noupdate /zigbee_tb/dut/DQPSK_CSK/tx_done_d
add wave -noupdate -divider Output
add wave -noupdate /zigbee_tb/tx_real
add wave -noupdate /zigbee_tb/tx_imag
add wave -noupdate /zigbee_tb/tx_done
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{PayLoad counter --> done successfully} {13 ns} 1 default White} {{Cursor 2} {17 ns} 1} {{Cursor 4} {41 ns} 1} {{Cursor 6} {101 ns} 1 default Cyan} {{Cursor 5} {57 ns} 1 default Turquoise} {{Cursor 6} {73 ns} 1 default Turquoise} {{Cursor 7} {89 ns} 1 default Turquoise} {{Cursor 8} {105 ns} 0}
quietly wave cursor active 8
configure wave -namecolwidth 333
configure wave -valuecolwidth 52
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {10 ns} {110 ns}
