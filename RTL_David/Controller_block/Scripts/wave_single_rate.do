onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider Clock
add wave -noupdate /controller_single_rate_tb/clk
add wave -noupdate -divider {Control Signals}
add wave -noupdate /controller_single_rate_tb/rst_n
add wave -noupdate -divider Input
add wave -noupdate /controller_single_rate_tb/start_tx
add wave -noupdate /controller_single_rate_tb/tx_end
add wave -noupdate -divider {Output of Slow rate}
add wave -noupdate /controller_single_rate_tb/mode_S
add wave -noupdate /controller_single_rate_tb/zero_pad_en_S
add wave -noupdate -divider {Output of Fast rate}
add wave -noupdate /controller_single_rate_tb/mode_F
add wave -noupdate /controller_single_rate_tb/zero_pad_en_F
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {24 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
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
WaveRestoreZoom {0 ns} {252 ns}
