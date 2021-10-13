# User config
set ::env(DESIGN_NAME) wb_openram_wrapper

# Change if needed
set ::env(VERILOG_FILES) [glob $::env(DESIGN_DIR)/src/*.v]

# Fill this
set ::env(CLOCK_PORT) "wb_clk_i"

# Design is not intended to be top module (= leave metal layer 5 for PDN)
set ::env(DESIGN_IS_CORE) 0
set ::env(GLB_RT_MAXLAYER) 5

set ::env(VDD_NETS) [list {vccd1}] 
set ::env(GND_NETS) [list {vssd1}]

set ::env(RUN_CVC) 0

set filename $::env(DESIGN_DIR)/$::env(PDK)_$::env(STD_CELL_LIBRARY)_config.tcl
if { [file exists $filename] == 1} {
	source $filename
}

