onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider Parameter
add wave -noupdate -radix ascii /controller_hyb_rate_tb/hyb_controller/rate_mode
add wave -noupdate -divider reset
add wave -noupdate /controller_hyb_rate_tb/rst_n
add wave -noupdate -divider Clock
add wave -noupdate /controller_hyb_rate_tb/clk
add wave -noupdate -divider Input
add wave -noupdate /controller_hyb_rate_tb/start_tx
add wave -noupdate /controller_hyb_rate_tb/tx_end
add wave -noupdate -divider {Internal Signals}
add wave -noupdate /controller_hyb_rate_tb/hyb_controller/idle_flage
add wave -noupdate -divider Output
add wave -noupdate /controller_hyb_rate_tb/mode
add wave -noupdate /controller_hyb_rate_tb/zero_pad_en
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {125 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 189
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
WaveRestoreZoom {0 ns} {244 ns}
