vlib work

vlog ../RTL_design_code/*.v 
vlog ../TB_code/*.v 


vsim -voptargs=+acc work.QPSK_mapper_tb

do ../Scripts/wave.do

run -all
#quit -sim