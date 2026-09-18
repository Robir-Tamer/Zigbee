onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider Parameter
add wave -noupdate -radix ascii /zigbee_S_tb/rate_mode
add wave -noupdate -radix unsigned /zigbee_S_tb/wl
add wave -noupdate -radix unsigned /zigbee_S_tb/fl
add wave -noupdate -radix unsigned /zigbee_S_tb/payload_w
add wave -noupdate -radix unsigned /zigbee_S_tb/max_payload_length
add wave -noupdate -radix unsigned /zigbee_S_tb/header_length
add wave -noupdate -radix unsigned /zigbee_S_tb/dqpsk_fifo_w
add wave -noupdate -radix unsigned /zigbee_S_tb/dqpsk_fifo_depth
add wave -noupdate -divider Reset
add wave -noupdate /zigbee_S_tb/rst_n
add wave -noupdate -divider Clock
add wave -noupdate /zigbee_S_tb/clk
add wave -noupdate -divider Input
add wave -noupdate -color Yellow -radix binary /zigbee_S_tb/payload
add wave -noupdate -radix decimal /zigbee_S_tb/payload_length
add wave -noupdate /zigbee_S_tb/start_tx
add wave -noupdate -divider -height 30 PayLoad_Counter
add wave -noupdate -group PayLoad_counter /zigbee_S_tb/dut/PayLoad_Counter/wr_en
add wave -noupdate -group PayLoad_counter /zigbee_S_tb/dut/PayLoad_Counter/wr_data
add wave -noupdate -group PayLoad_counter /zigbee_S_tb/dut/PayLoad_Counter/counter
add wave -noupdate -divider PayLoad_SYNCH_FIFO
add wave -noupdate -radix binary /zigbee_S_tb/dut/payload_ram/dout
add wave -noupdate /zigbee_S_tb/dut/payload_ram/empty_flag
add wave -noupdate /zigbee_S_tb/dut/payload_ram/mem
add wave -noupdate -divider {Zero Padding}
add wave -noupdate -radix binary /zigbee_S_tb/dut/ZeroPadding/data_i
add wave -noupdate -color Magenta /zigbee_S_tb/dut/ZeroPadding/valid
add wave -noupdate /zigbee_S_tb/dut/ZeroPadding/data_o
add wave -noupdate /zigbee_S_tb/dut/ZeroPadding/done_bytes
add wave -noupdate /zigbee_S_tb/dut/ZeroPadding/empty_delayed
add wave -noupdate -group useless /zigbee_S_tb/dut/ZeroPadding/empty
add wave -noupdate -group useless /zigbee_S_tb/dut/ZeroPadding/next_item
add wave -noupdate -group useless /zigbee_S_tb/dut/ZeroPadding/counter
add wave -noupdate -group useless /zigbee_S_tb/dut/ZeroPadding/header_done
add wave -noupdate -group useless /zigbee_S_tb/dut/ZeroPadding/byte_counter
add wave -noupdate -group useless /zigbee_S_tb/dut/ZeroPadding/data_i_reg
add wave -noupdate -group useless /zigbee_S_tb/dut/ZeroPadding/header_reg
add wave -noupdate -divider demux
add wave -noupdate /zigbee_S_tb/dut/DEMUX/data_i
add wave -noupdate /zigbee_S_tb/dut/DEMUX/valid_i
add wave -noupdate -radix binary /zigbee_S_tb/dut/DEMUX/e_bits
add wave -noupdate -radix binary /zigbee_S_tb/dut/DEMUX/o_bits
add wave -noupdate -color Magenta /zigbee_S_tb/dut/DEMUX/valid
add wave -noupdate -group Useless /zigbee_S_tb/dut/DEMUX/even
add wave -noupdate -group Useless /zigbee_S_tb/dut/DEMUX/e_bits_reg
add wave -noupdate -group Useless /zigbee_S_tb/dut/DEMUX/o_bits_reg
add wave -noupdate -group Useless /zigbee_S_tb/dut/DEMUX/e_counter
add wave -noupdate -group Useless /zigbee_S_tb/dut/DEMUX/o_counter
add wave -noupdate -divider Cont
add wave -noupdate /zigbee_S_tb/dut/my_controller/zero_pad_en
add wave -noupdate -divider {Sym_Mapper 2 PPDU}
add wave -noupdate -height 30 -expand -group {Even Path} -radix binary -childformat {{{/zigbee_S_tb/dut/symbol_mapper_to_ppdu/i_data_even[5]} -radix binary} {{/zigbee_S_tb/dut/symbol_mapper_to_ppdu/i_data_even[4]} -radix binary} {{/zigbee_S_tb/dut/symbol_mapper_to_ppdu/i_data_even[3]} -radix binary} {{/zigbee_S_tb/dut/symbol_mapper_to_ppdu/i_data_even[2]} -radix binary} {{/zigbee_S_tb/dut/symbol_mapper_to_ppdu/i_data_even[1]} -radix binary} {{/zigbee_S_tb/dut/symbol_mapper_to_ppdu/i_data_even[0]} -radix binary}} -subitemconfig {{/zigbee_S_tb/dut/symbol_mapper_to_ppdu/i_data_even[5]} {-height 15 -radix binary} {/zigbee_S_tb/dut/symbol_mapper_to_ppdu/i_data_even[4]} {-height 15 -radix binary} {/zigbee_S_tb/dut/symbol_mapper_to_ppdu/i_data_even[3]} {-height 15 -radix binary} {/zigbee_S_tb/dut/symbol_mapper_to_ppdu/i_data_even[2]} {-height 15 -radix binary} {/zigbee_S_tb/dut/symbol_mapper_to_ppdu/i_data_even[1]} {-height 15 -radix binary} {/zigbee_S_tb/dut/symbol_mapper_to_ppdu/i_data_even[0]} {-height 15 -radix binary}} /zigbee_S_tb/dut/symbol_mapper_to_ppdu/i_data_even
add wave -noupdate -height 30 -expand -group {Even Path} -expand -group Symbol_Mapper /zigbee_S_tb/dut/symbol_mapper_to_ppdu/mapper_even_valid
add wave -noupdate -height 30 -expand -group {Even Path} -expand -group Symbol_Mapper -radix hexadecimal /zigbee_S_tb/dut/symbol_mapper_to_ppdu/mapper_even_data
add wave -noupdate -height 30 -expand -group {Even Path} -expand -group FIFO /zigbee_S_tb/dut/symbol_mapper_to_ppdu/u_sync_fifo_even/dout
add wave -noupdate -height 30 -expand -group {Even Path} -expand -group interleaver -color Magenta /zigbee_S_tb/dut/symbol_mapper_to_ppdu/interleaver_even_valid
add wave -noupdate -height 30 -expand -group {Even Path} -expand -group interleaver /zigbee_S_tb/dut/symbol_mapper_to_ppdu/interleaver_even_data
add wave -noupdate -height 30 -expand -group {Even Path} -expand -group interleaver -radix hexadecimal /zigbee_S_tb/dut/symbol_mapper_to_ppdu/u_interleaver_even/gen_interleaver_250kbps/shift_reg
add wave -noupdate -height 30 -expand -group {Even Path} -expand -group interleaver /zigbee_S_tb/dut/symbol_mapper_to_ppdu/u_interleaver_even/gen_interleaver_250kbps/busy
add wave -noupdate -height 30 -expand -group {Even Path} -expand -group interleaver /zigbee_S_tb/dut/symbol_mapper_to_ppdu/u_interleaver_even/gen_interleaver_250kbps/cycle_flag
add wave -noupdate -height 30 -expand -group {Even Path} -expand -group interleaver -expand -group {New Group} /zigbee_S_tb/dut/symbol_mapper_to_ppdu/u_interleaver_even/i_valid_c
add wave -noupdate -height 30 -expand -group {Even Path} -expand -group interleaver -expand -group {New Group} /zigbee_S_tb/dut/symbol_mapper_to_ppdu/u_interleaver_even/i_data
add wave -noupdate -height 30 -expand -group {Even Path} -expand -group interleaver -expand -group {New Group} /zigbee_S_tb/dut/symbol_mapper_to_ppdu/u_interleaver_even/tx_done
add wave -noupdate -height 30 -expand -group {Even Path} -expand -group interleaver -expand -group {New Group} /zigbee_S_tb/dut/symbol_mapper_to_ppdu/u_interleaver_even/o_data
add wave -noupdate -height 30 -expand -group {Even Path} -expand -group interleaver -expand -group {New Group} /zigbee_S_tb/dut/symbol_mapper_to_ppdu/u_interleaver_even/o_valid
add wave -noupdate -height 30 -expand -group {Even Path} -expand -group interleaver -expand -group {New Group} /zigbee_S_tb/dut/symbol_mapper_to_ppdu/u_interleaver_even/next_item
add wave -noupdate -height 30 -expand -group {Even Path} -expand -group interleaver -expand -group {New Group} /zigbee_S_tb/dut/symbol_mapper_to_ppdu/u_interleaver_even/i_valid
add wave -noupdate -height 30 -expand -group {Even Path} -expand -group interleaver -expand -group {New Group} /zigbee_S_tb/dut/symbol_mapper_to_ppdu/u_interleaver_even/gen_interleaver_250kbps/cycle_flag
add wave -noupdate -height 30 -expand -group {Even Path} -expand -group interleaver -expand -group {New Group} /zigbee_S_tb/dut/symbol_mapper_to_ppdu/u_interleaver_even/gen_interleaver_250kbps/shift_reg
add wave -noupdate -height 30 -expand -group {Even Path} -expand -group interleaver -expand -group {New Group} /zigbee_S_tb/dut/symbol_mapper_to_ppdu/u_interleaver_even/gen_interleaver_250kbps/bit_count
add wave -noupdate -height 30 -expand -group {Even Path} -expand -group interleaver -expand -group {New Group} /zigbee_S_tb/dut/symbol_mapper_to_ppdu/u_interleaver_even/gen_interleaver_250kbps/busy
add wave -noupdate -height 30 -expand -group {Even Path} -expand -group interleaver -expand -group {New Group} /zigbee_S_tb/dut/symbol_mapper_to_ppdu/u_interleaver_even/gen_interleaver_250kbps/first_done
add wave -noupdate -height 30 -expand -group {Even Path} -expand -group interleaver -expand -group {New Group} -color Cyan /zigbee_S_tb/dut/symbol_mapper_to_ppdu/u_interleaver_even/gen_interleaver_250kbps/data_ready
add wave -noupdate -height 30 -group {Odd Path} -radix binary /zigbee_S_tb/dut/symbol_mapper_to_ppdu/i_data_odd
add wave -noupdate -height 30 -group {Odd Path} -expand -group Symbol_mapper /zigbee_S_tb/dut/symbol_mapper_to_ppdu/mapper_odd_valid
add wave -noupdate -height 30 -group {Odd Path} -expand -group Symbol_mapper -radix hexadecimal -childformat {{{/zigbee_S_tb/dut/symbol_mapper_to_ppdu/mapper_odd_data[31]} -radix hexadecimal} {{/zigbee_S_tb/dut/symbol_mapper_to_ppdu/mapper_odd_data[30]} -radix hexadecimal} {{/zigbee_S_tb/dut/symbol_mapper_to_ppdu/mapper_odd_data[29]} -radix hexadecimal} {{/zigbee_S_tb/dut/symbol_mapper_to_ppdu/mapper_odd_data[28]} -radix hexadecimal} {{/zigbee_S_tb/dut/symbol_mapper_to_ppdu/mapper_odd_data[27]} -radix hexadecimal} {{/zigbee_S_tb/dut/symbol_mapper_to_ppdu/mapper_odd_data[26]} -radix hexadecimal} {{/zigbee_S_tb/dut/symbol_mapper_to_ppdu/mapper_odd_data[25]} -radix hexadecimal} {{/zigbee_S_tb/dut/symbol_mapper_to_ppdu/mapper_odd_data[24]} -radix hexadecimal} {{/zigbee_S_tb/dut/symbol_mapper_to_ppdu/mapper_odd_data[23]} -radix hexadecimal} {{/zigbee_S_tb/dut/symbol_mapper_to_ppdu/mapper_odd_data[22]} -radix hexadecimal} {{/zigbee_S_tb/dut/symbol_mapper_to_ppdu/mapper_odd_data[21]} -radix hexadecimal} {{/zigbee_S_tb/dut/symbol_mapper_to_ppdu/mapper_odd_data[20]} -radix hexadecimal} {{/zigbee_S_tb/dut/symbol_mapper_to_ppdu/mapper_odd_data[19]} -radix hexadecimal} {{/zigbee_S_tb/dut/symbol_mapper_to_ppdu/mapper_odd_data[18]} -radix hexadecimal} {{/zigbee_S_tb/dut/symbol_mapper_to_ppdu/mapper_odd_data[17]} -radix hexadecimal} {{/zigbee_S_tb/dut/symbol_mapper_to_ppdu/mapper_odd_data[16]} -radix hexadecimal} {{/zigbee_S_tb/dut/symbol_mapper_to_ppdu/mapper_odd_data[15]} -radix hexadecimal} {{/zigbee_S_tb/dut/symbol_mapper_to_ppdu/mapper_odd_data[14]} -radix hexadecimal} {{/zigbee_S_tb/dut/symbol_mapper_to_ppdu/mapper_odd_data[13]} -radix hexadecimal} {{/zigbee_S_tb/dut/symbol_mapper_to_ppdu/mapper_odd_data[12]} -radix hexadecimal} {{/zigbee_S_tb/dut/symbol_mapper_to_ppdu/mapper_odd_data[11]} -radix hexadecimal} {{/zigbee_S_tb/dut/symbol_mapper_to_ppdu/mapper_odd_data[10]} -radix hexadecimal} {{/zigbee_S_tb/dut/symbol_mapper_to_ppdu/mapper_odd_data[9]} -radix hexadecimal} {{/zigbee_S_tb/dut/symbol_mapper_to_ppdu/mapper_odd_data[8]} -radix hexadecimal} {{/zigbee_S_tb/dut/symbol_mapper_to_ppdu/mapper_odd_data[7]} -radix hexadecimal} {{/zigbee_S_tb/dut/symbol_mapper_to_ppdu/mapper_odd_data[6]} -radix hexadecimal} {{/zigbee_S_tb/dut/symbol_mapper_to_ppdu/mapper_odd_data[5]} -radix hexadecimal} {{/zigbee_S_tb/dut/symbol_mapper_to_ppdu/mapper_odd_data[4]} -radix hexadecimal} {{/zigbee_S_tb/dut/symbol_mapper_to_ppdu/mapper_odd_data[3]} -radix hexadecimal} {{/zigbee_S_tb/dut/symbol_mapper_to_ppdu/mapper_odd_data[2]} -radix hexadecimal} {{/zigbee_S_tb/dut/symbol_mapper_to_ppdu/mapper_odd_data[1]} -radix hexadecimal} {{/zigbee_S_tb/dut/symbol_mapper_to_ppdu/mapper_odd_data[0]} -radix hexadecimal}} -subitemconfig {{/zigbee_S_tb/dut/symbol_mapper_to_ppdu/mapper_odd_data[31]} {-height 15 -radix hexadecimal} {/zigbee_S_tb/dut/symbol_mapper_to_ppdu/mapper_odd_data[30]} {-height 15 -radix hexadecimal} {/zigbee_S_tb/dut/symbol_mapper_to_ppdu/mapper_odd_data[29]} {-height 15 -radix hexadecimal} {/zigbee_S_tb/dut/symbol_mapper_to_ppdu/mapper_odd_data[28]} {-height 15 -radix hexadecimal} {/zigbee_S_tb/dut/symbol_mapper_to_ppdu/mapper_odd_data[27]} {-height 15 -radix hexadecimal} {/zigbee_S_tb/dut/symbol_mapper_to_ppdu/mapper_odd_data[26]} {-height 15 -radix hexadecimal} {/zigbee_S_tb/dut/symbol_mapper_to_ppdu/mapper_odd_data[25]} {-height 15 -radix hexadecimal} {/zigbee_S_tb/dut/symbol_mapper_to_ppdu/mapper_odd_data[24]} {-height 15 -radix hexadecimal} {/zigbee_S_tb/dut/symbol_mapper_to_ppdu/mapper_odd_data[23]} {-height 15 -radix hexadecimal} {/zigbee_S_tb/dut/symbol_mapper_to_ppdu/mapper_odd_data[22]} {-height 15 -radix hexadecimal} {/zigbee_S_tb/dut/symbol_mapper_to_ppdu/mapper_odd_data[21]} {-height 15 -radix hexadecimal} {/zigbee_S_tb/dut/symbol_mapper_to_ppdu/mapper_odd_data[20]} {-height 15 -radix hexadecimal} {/zigbee_S_tb/dut/symbol_mapper_to_ppdu/mapper_odd_data[19]} {-height 15 -radix hexadecimal} {/zigbee_S_tb/dut/symbol_mapper_to_ppdu/mapper_odd_data[18]} {-height 15 -radix hexadecimal} {/zigbee_S_tb/dut/symbol_mapper_to_ppdu/mapper_odd_data[17]} {-height 15 -radix hexadecimal} {/zigbee_S_tb/dut/symbol_mapper_to_ppdu/mapper_odd_data[16]} {-height 15 -radix hexadecimal} {/zigbee_S_tb/dut/symbol_mapper_to_ppdu/mapper_odd_data[15]} {-height 15 -radix hexadecimal} {/zigbee_S_tb/dut/symbol_mapper_to_ppdu/mapper_odd_data[14]} {-height 15 -radix hexadecimal} {/zigbee_S_tb/dut/symbol_mapper_to_ppdu/mapper_odd_data[13]} {-height 15 -radix hexadecimal} {/zigbee_S_tb/dut/symbol_mapper_to_ppdu/mapper_odd_data[12]} {-height 15 -radix hexadecimal} {/zigbee_S_tb/dut/symbol_mapper_to_ppdu/mapper_odd_data[11]} {-height 15 -radix hexadecimal} {/zigbee_S_tb/dut/symbol_mapper_to_ppdu/mapper_odd_data[10]} {-height 15 -radix hexadecimal} {/zigbee_S_tb/dut/symbol_mapper_to_ppdu/mapper_odd_data[9]} {-height 15 -radix hexadecimal} {/zigbee_S_tb/dut/symbol_mapper_to_ppdu/mapper_odd_data[8]} {-height 15 -radix hexadecimal} {/zigbee_S_tb/dut/symbol_mapper_to_ppdu/mapper_odd_data[7]} {-height 15 -radix hexadecimal} {/zigbee_S_tb/dut/symbol_mapper_to_ppdu/mapper_odd_data[6]} {-height 15 -radix hexadecimal} {/zigbee_S_tb/dut/symbol_mapper_to_ppdu/mapper_odd_data[5]} {-height 15 -radix hexadecimal} {/zigbee_S_tb/dut/symbol_mapper_to_ppdu/mapper_odd_data[4]} {-height 15 -radix hexadecimal} {/zigbee_S_tb/dut/symbol_mapper_to_ppdu/mapper_odd_data[3]} {-height 15 -radix hexadecimal} {/zigbee_S_tb/dut/symbol_mapper_to_ppdu/mapper_odd_data[2]} {-height 15 -radix hexadecimal} {/zigbee_S_tb/dut/symbol_mapper_to_ppdu/mapper_odd_data[1]} {-height 15 -radix hexadecimal} {/zigbee_S_tb/dut/symbol_mapper_to_ppdu/mapper_odd_data[0]} {-height 15 -radix hexadecimal}} /zigbee_S_tb/dut/symbol_mapper_to_ppdu/mapper_odd_data
add wave -noupdate -height 30 -group {Odd Path} -expand -group FiFo /zigbee_S_tb/dut/symbol_mapper_to_ppdu/u_sync_fifo_odd/dout
add wave -noupdate -height 30 -group {Odd Path} -expand -group Interleaver -color Magenta /zigbee_S_tb/dut/symbol_mapper_to_ppdu/interleaver_odd_valid
add wave -noupdate -height 30 -group {Odd Path} -expand -group Interleaver /zigbee_S_tb/dut/symbol_mapper_to_ppdu/interleaver_odd_data
add wave -noupdate -height 30 -group {Odd Path} -expand -group Interleaver -radix hexadecimal /zigbee_S_tb/dut/symbol_mapper_to_ppdu/u_interleaver_odd/gen_interleaver_250kbps/shift_reg
add wave -noupdate -height 30 -group {Odd Path} -expand -group Interleaver /zigbee_S_tb/dut/symbol_mapper_to_ppdu/u_interleaver_odd/gen_interleaver_250kbps/busy
add wave -noupdate -height 30 -group {Odd Path} -expand -group Interleaver /zigbee_S_tb/dut/symbol_mapper_to_ppdu/u_interleaver_odd/gen_interleaver_250kbps/cycle_flag
add wave -noupdate -expand -group PPDU -radix binary /zigbee_S_tb/dut/symbol_mapper_to_ppdu/preamble_sfd_wire
add wave -noupdate -expand -group PPDU -color Magenta /zigbee_S_tb/dut/symbol_mapper_to_ppdu/o_valid
add wave -noupdate -expand -group PPDU -radix binary /zigbee_S_tb/dut/symbol_mapper_to_ppdu/o_i
add wave -noupdate -expand -group PPDU -radix binary /zigbee_S_tb/dut/symbol_mapper_to_ppdu/o_q
add wave -noupdate -expand -group Useless2 /zigbee_S_tb/dut/symbol_mapper_to_ppdu/fifo_even_empty
add wave -noupdate -expand -group Useless2 /zigbee_S_tb/dut/symbol_mapper_to_ppdu/fifo_odd_empty
add wave -noupdate -divider QPSK
add wave -noupdate /zigbee_S_tb/dut/QPSK/i_valid
add wave -noupdate -color Yellow /zigbee_S_tb/dut/QPSK/i
add wave -noupdate -color Wheat /zigbee_S_tb/dut/QPSK/q
add wave -noupdate /zigbee_S_tb/dut/QPSK/valid
add wave -noupdate -radix symbolic /zigbee_S_tb/dut/QPSK/out_real
add wave -noupdate -radix symbolic /zigbee_S_tb/dut/QPSK/out_imag
add wave -noupdate -divider {DQPSK   2   out}
add wave -noupdate /zigbee_S_tb/dut/DQPSK_CSK/i_valid
add wave -noupdate -radix decimal /zigbee_S_tb/dut/DQPSK_CSK/Real_o
add wave -noupdate -radix decimal /zigbee_S_tb/dut/DQPSK_CSK/Imag_o
add wave -noupdate /zigbee_S_tb/dut/DQPSK_CSK/valid
add wave -noupdate -expand -group Synch_FIFO_output /zigbee_S_tb/dut/DQPSK_CSK/S_R
add wave -noupdate -expand -group Synch_FIFO_output /zigbee_S_tb/dut/DQPSK_CSK/S_I
add wave -noupdate -expand -group Synch_FIFO_output /zigbee_S_tb/dut/DQPSK_CSK/next_item
add wave -noupdate -expand -group Synch_FIFO_output -expand -group Useless_fifo /zigbee_S_tb/dut/DQPSK_CSK/FIFO_valid_imag
add wave -noupdate -expand -group Synch_FIFO_output -expand -group Useless_fifo /zigbee_S_tb/dut/DQPSK_CSK/FIFO_valid_real
add wave -noupdate -expand -group Synch_FIFO_output -expand -group Useless_fifo /zigbee_S_tb/dut/DQPSK_CSK/empty_flag_imag
add wave -noupdate -expand -group Synch_FIFO_output -expand -group Useless_fifo /zigbee_S_tb/dut/DQPSK_CSK/full_flag_imag
add wave -noupdate -expand -group Synch_FIFO_output -expand -group Useless_fifo /zigbee_S_tb/dut/DQPSK_CSK/empty_flag_real
add wave -noupdate -expand -group Synch_FIFO_output -expand -group Useless_fifo /zigbee_S_tb/dut/DQPSK_CSK/full_flag_real
add wave -noupdate /zigbee_S_tb/dut/DQPSK_CSK/Real_Sync_FIFO/rd_en
add wave -noupdate /zigbee_S_tb/dut/DQPSK_CSK/Imag_Sync_FIFO/rd_en
add wave -noupdate /zigbee_S_tb/dut/DQPSK_CSK/en
add wave -noupdate -divider -height 30 <NULL>
add wave -noupdate -format Analog-Step -height 74 -max 16.0 -min -16.0 -radix decimal /zigbee_S_tb/dut/DQPSK_CSK/csk_out_r
add wave -noupdate -format Analog-Step -height 74 -max 16.0 -min -16.0 -radix decimal /zigbee_S_tb/dut/DQPSK_CSK/csk_out_i
add wave -noupdate -divider -height 30 <NULL>
add wave -noupdate /zigbee_S_tb/dut/DQPSK_CSK/csk_running
add wave -noupdate /zigbee_S_tb/dut/DQPSK_CSK/tx_done_level
add wave -noupdate /zigbee_S_tb/dut/DQPSK_CSK/ever_run
add wave -noupdate /zigbee_S_tb/dut/DQPSK_CSK/tx_done_raw
add wave -noupdate -divider Output
add wave -noupdate -format Event -radix decimal /zigbee_S_tb/tx_real
add wave -noupdate -format Event -radix decimal /zigbee_S_tb/tx_imag
add wave -noupdate /zigbee_S_tb/tx_done
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 11} {475 ns} 1} {{Cursor 12} {1035 ns} 0} {{Cursor 13} {126 ns} 0}
quietly wave cursor active 2
configure wave -namecolwidth 271
configure wave -valuecolwidth 146
configure wave -justifyvalue left
configure wave -signalnamewidth 1
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
WaveRestoreZoom {848 ns} {1296 ns}
