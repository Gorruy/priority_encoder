vlib work

vlog -sv ../rtl/priority_encoder.sv
vlog -sv top_tb.sv

vsim -novopt top_tb
add log -r /*
add wave -r *
run -all