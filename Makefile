
## SRAM macros
SRAM_BEHAVIORAL_MODELS = $(PDK_PATH)/libs.ref/sky130_sram_macros/verilog

##
UPRJ_SRC_PATH = ./src

# COCOTB variables
export COCOTB_REDUCED_LOG_FMT=1
export PYTHONPATH := test:$(PYTHONPATH)
export LIBPYTHON_LOC=$(shell cocotb-config --libpython)

all: test_wb_openram_wrapper formal

formal:
	sby -f properties.sby

# if you run rules with NOASSERT=1 it will set PYTHONOPTIMIZE, which turns off assertions in the tests
test_wb_openram_wrapper:
	rm -rf sim_build/
	mkdir sim_build/
	iverilog -o sim_build/sim.vvp -s wb_openram_wrapper_tb test/wb_openram_wrapper_tb.v src/wb_openram_wrapper.v src/wb_port_control.v \
	-I $(SRAM_BEHAVIORAL_MODELS)
	PYTHONOPTIMIZE=${NOASSERT} MODULE=test_wb_openram_wrapper vvp -M $$(cocotb-config --prefix)/cocotb/libs -m libcocotbvpi_icarus sim_build/sim.vvp
	! grep failure results.xml
	
show_%: %.vcd %.gtkw
	gtkwave $^


lint:
	verible-verilog-lint src/*v --rules_config verible.rules

clean:
	rm -rf *vcd sim_build test/__pycache__

.PHONY: clean
