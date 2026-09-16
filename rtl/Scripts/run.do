vlib work

vlog ../RTL/*.v 
vlog ../TB/*.v 


vsim -voptargs=+acc work.zigbee_tb

do ../Scripts/wave_1_payL.do

run -all
#quit -sim