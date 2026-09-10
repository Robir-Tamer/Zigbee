vlib work

vlog ../RTL_design_code/*.v 
vlog ../TB_code/*.v 


vsim -voptargs=+acc work.controller_hyb_rate_tb

do ../Scripts/wave_hyb.do

run -all
#quit -sim