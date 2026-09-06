vlib work
vmap work work
vlog ../RTL/CSK_GEN.V
vlog ../TB/CSK_GEN_TB.V
vsim -voptargs=+acc CSK_GEN_TB
add wave clk en
add wave addr_ptr
add wave csk_out_r csk_out_i
add wave next_item
run -all