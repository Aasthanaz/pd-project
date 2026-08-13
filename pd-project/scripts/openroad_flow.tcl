# Full OpenROAD flow: floorplan -> PDN -> placement -> CTS -> routing -> STA
# Run inside the openroad/orfs docker container:
#   openroad -exit scripts/openroad_flow.tcl

set PDK_ROOT $::env(PDK_ROOT)
set LIB_DIR  $PDK_ROOT/sky130A/libs.ref/sky130_fd_sc_hd/lib
set LEF_DIR  $PDK_ROOT/sky130A/libs.ref/sky130_fd_sc_hd

read_lef $LEF_DIR/tech/sky130_fd_sc_hd.tlef
read_lef $LEF_DIR/lef/sky130_fd_sc_hd.lef
read_liberty $LIB_DIR/sky130_fd_sc_hd__tt_025C_1v80.lib

read_verilog run/counter.synth.v
link_design counter
puts ">>> link_design OK"

# --- Floorplan ---
initialize_floorplan \
  -die_area  "0 0 200 200" \
  -core_area "10 10 190 190" \
  -site unithd
place_pins -random -hor_layers li1 -ver_layers met2
write_def run/counter.floorplan.def
puts ">>> Floorplan done -> run/counter.floorplan.def"

# --- Power Distribution Network ---
set_voltage_domain -power VDD -ground VSS
define_pdn_grid -name main_grid -voltage_domains VDD
add_pdn_stripe -grid main_grid -layer met1 -width 0.48 -pitch 5.44 -offset 0
add_pdn_stripe -grid main_grid -layer met4 -width 1.6  -pitch 27.2 -offset 0
add_pdn_ring   -grid main_grid -layers {met4 met5} -widths 5 -spacings 2
pdngen
write_def run/counter.pdn.def
puts ">>> PDN done -> run/counter.pdn.def"

# --- Placement ---
global_placement -density 0.55
detailed_placement
check_placement -verbose
write_def run/counter.placement.def
puts ">>> Placement done -> run/counter.placement.def"

# --- Clock Tree Synthesis ---
create_clock -period 10 [get_ports clk]
set_propagated_clock [get_clocks clk]
clock_tree_synthesis \
  -root_buf sky130_fd_sc_hd__clkbuf_1 \
  -buf_list sky130_fd_sc_hd__clkbuf_1
detailed_placement
write_def run/counter.cts.def
puts ">>> CTS done -> run/counter.cts.def"

# --- Routing ---
set_routing_layers -signal met1-met5
global_route
detailed_route -output_drc run/counter.drc.rpt
write_def run/counter.routed.def
puts ">>> Routing done -> run/counter.routed.def"

# --- STA ---
puts ">>> ===== TIMING REPORT ====="
report_checks -path_delay max
report_wns
report_tns

write_def run/counter.final.def
puts ">>> ALL STAGES COMPLETE -> run/counter.final.def"
