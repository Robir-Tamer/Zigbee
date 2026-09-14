vlib work

vlog ../RTL/*.v 
vlog ../TB/*.v 


vsim -voptargs=+acc work.zigbee_tb

do ../Scripts/wave.do

run -all
#quit -sim