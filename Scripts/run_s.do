vlib work

vlog ../RTL/*.*v 
vlog ../TB/*.*v 


vsim -voptargs=+acc work.zigbee_S_tb

do ../Scripts/wave_S.do

run -all
#quit -sim

do ../Scripts/save_Tx_out.tcl "SlowSingleMode"