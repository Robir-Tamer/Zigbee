vlib work

vlog ../RTL/*.*v 
vlog ../TB/*.*v 


vsim -voptargs=+acc work.zigbee_H_tb

do ../Scripts/wave_H.do

run -all
#quit -sim

do ../Scripts/save_Tx_out.tcl "Hybrid"