# DRC check + GDS export
# Run with: magic -rcfile $PDK_ROOT/sky130A/libs.tech/magic/sky130A.magicrc -noconsole scripts/drc_gds.tcl

def read run/counter.final.def
drc check
drc why
gds write run/counter.gds
puts ">>> GDS written to run/counter.gds"
quit -noprompt
