vlib work

vlog ../RTL_design_code/*.v 
vlog ../TB_code/*.v 


vsim -voptargs=+acc work.controller_single_rate_tb

do ../Scripts/wave_single_rate.do

run -all
#quit -sim