###########################################################################################
# STARS 2025 - Makefile for SystemVerilog Projects
# By Miguel Isrrael Teran, Alex Weyer, Johnny Hazboun, Ben Miller
# 
# Set tab spacing to 2 spaces per tab for best viewing results
###########################################################################################

export PATH := /home/shay/a/ece270/bin:$(PATH)
export LD_LIBRARY_PATH := /home/shay/a/ece270/lib:$(LD_LIBRARY_PATH)

YOSYS=yosys
NEXTPNR=nextpnr-ice40
SHELL=bash

MAP = mapped
TB	=  testbench
SRC = source
BUILD = build

FPGA_TOP = top
ICE   	= support/ice40hx8k.sv
UART	= support/uart*.v
PINMAP = support/pinmap.pcf
FPGA_TIMING_CELLS = support/*.v

DEVICE  = 8k
TIMEDEV = hx8k
FOOTPRINT = ct256

# PDK sky130A Standard Cell Libraries
VERILOG := /usr/share/yosys/ice40/cells_sim.v /usr/share/yosys/ice40/cells_map.v

help:
	@echo -e "Help..."
	@cat support/help.txt

# Setup sky130 PDK files
.PHONY: setup_pdk
setup_pdk:
	@python3 -m pip install --user --upgrade --no-cache-dir volare &&\
	mkdir -p pdks && \
	volare enable --pdk sky130 $(PDK_VERSION_TAG) &&\
	echo -e "\nPDK Setup Complete!\n"


# Check environment (sky130A must be loaded)
.PHONY: check_env
check_env:
	echo -e "\nEnvironment setup correctly!\n";

# *******************************************************************************
# COMPILATION & SIMULATION TARGETS
# *******************************************************************************

# Source Compilation and simulation of Design
.PHONY: sim_%_src
sim_%_src: 
	@echo -e "Creating executable for source simulation...\n"
	@mkdir -p $(BUILD) && rm -rf $(BUILD)/*
	@iverilog -g2012 -o $(BUILD)/$*_tb -Y .sv -y $(SRC) $(TB)/$*_tb.sv
	@echo -e "\nSource Compilation complete!\n"
	@echo -e "Simulating source...\n"
	@vvp -l vvp_sim.log $(BUILD)/$*_tb
	@echo -e "\nSimulation complete!\n"
	@echo -e "\nOpening waveforms...\n"
	@if [ -f waves/$*.gtkw ]; then \
		gtkwave waves/$*.gtkw; \
	else \
		gtkwave waves/$*.vcd; \
	fi


# Run synthesis on Design
.PHONY: syn_%
syn_%: check_env
	@echo -e "Synthesizing design...\n"
	@mkdir -p $(MAP)
	$(YOSYS) -d -p "read_verilog -sv -noblackbox $(SRC)/*; synth_ice40 -top $*; write_verilog -noattr -noexpr -nohex -nodec -defparam $(MAP)/$*.v" > $*.log
	@echo -e "\nSynthesis complete!\n"


# Compile and simulate synthesized design
.PHONY: sim_%_syn
sim_%_syn: syn_%
	@echo -e "Compiling synthesized design...\n"
	@mkdir -p $(BUILD) && rm -rf $(BUILD)/*
	@iverilog -g2012 -o $(BUILD)/$*_tb -DFUNCTIONAL -DUNIT_DELAY=#1 $(TB)/$*_tb.sv $(MAP)/$*.v $(VERILOG)
	@echo -e "\nCompilation complete!\n"
	@echo -e "Simulating synthesized design...\n\n"
	@vvp -l vvp_sim.log $(BUILD)/$*_tb
	@echo -e "\nSimulation complete!\n"
	@echo -e "\nOpening waveforms...\n"
	@if [ -f waves/$*.gtkw ]; then \
		gtkwave waves/$*.gtkw; \
	else \
		gtkwave waves/$*.vcd; \
	fi


# Lint Design Only
.PHONY: vlint_%
vlint_%:
	@verilator --lint-only -Wall --timing -y $(SRC) $(SRC)/$*.sv $(TB)/$*_tb.sv
	@echo -e "\nNo linting errors found!\n"
 	

# Compile and simulate synthesized design
.PHONY: cells_%
cells_%: $(ICE) $(SRC) $(PINMAP)
	# lint with Verilator
	verilator --lint-only --top-module top -Werror-latch -y $(SRC) $(SRC)/top.sv
	# if build folder doesn't exist, create it
	mkdir -p $(BUILD)
	# synthesize using Yosys
	$(YOSYS) -p "read_verilog -sv -noblackbox $(ICE) $(UART) $(SRC)/*; synth -top $*; cd $*; show -format svg -viewer gimp"

# *******************************************************************************
# FPGA TARGETS
# *******************************************************************************

# Check code and synthesize design into a JSON netlist
$(BUILD)/$(FPGA_TOP).json : $(ICE) $(SRC)/* $(PINMAP)
	# lint with Verilator
	verilator --lint-only --top-module top -Werror-latch -y $(SRC) $(SRC)/top.sv
	# if build folder doesn't exist, create it
	mkdir -p $(BUILD)
	# synthesize using Yosys
	$(YOSYS) -p "read_verilog -sv -noblackbox $(ICE) $(UART) $(SRC)/*; synth_ice40 -top ice40hx8k; write_json -noscopeinfo $(BUILD)/$(FPGA_TOP).json"


# Place and route design using nextpnr
$(BUILD)/$(FPGA_TOP).asc : $(BUILD)/$(FPGA_TOP).json
	# Place and route using nextpnr
	$(NEXTPNR) --hx8k --package ct256 --placer-heap-cell-placement-timeout 0 --pcf $(PINMAP) --asc $(BUILD)/$(FPGA_TOP).asc --json $(BUILD)/$(FPGA_TOP).json 2> >(sed -e 's/^.* 0 errors$$//' -e '/^Info:/d' -e '/^[ ]*$$/d' 1>&2)


# Convert to bitstream using IcePack
$(BUILD)/$(FPGA_TOP).bin : $(BUILD)/$(FPGA_TOP).asc
	# Convert to bitstream using IcePack
	icepack $(BUILD)/$(FPGA_TOP).asc $(BUILD)/$(FPGA_TOP).bin


# Perform timing analysis on FPGA design
time: $(BUILD)/$(FPGA_TOP).asc
	# Re-synthesize
	$(YOSYS) -p "read_verilog -sv -noblackbox $(ICE) $(UART) $(SRC)/*; synth_ice40 -top ice40hx8k -json $(BUILD)/$(FPGA_TOP).json"
	# Place and route using nextpnr
	$(NEXTPNR) --hx8k --package ct256 --placer-heap-cell-placement-timeout 0 --asc $(BUILD)/$(FPGA_TOP).asc --json $(BUILD)/$(FPGA_TOP).json 2> >(sed -e 's/^.* 0 errors$$//' -e '/^Info:/d' -e '/^[ ]*$$/d' 1>&2)
	icetime -tmd hx8k $(BUILD)/$(FPGA_TOP).asc


# Upload design to the FPGA's flash memory
flash: $(BUILD)/$(FPGA_TOP).bin
	# Program non-volatile flash memory with FPGA bitstream using iceprog
	iceprog $(BUILD)/$(FPGA_TOP).bin


# Upload design to the FPGA's non-volatile RAM
cram: $(BUILD)/$(FPGA_TOP).bin
	# Program volatile FPGA Configuration RAM (CRAM) with bitstream using iceprog
	iceprog -S $(BUILD)/$(FPGA_TOP).bin

#Show the synthesied diagram
cells : $(ICE) $(SRC) $(PINMAP)
	# lint with Verilator
	verilator --lint-only --top-module top -Werror-latch -y $(SRC) $(SRC)/top.sv
	# if build folder doesn't exist, create it
	mkdir -p $(BUILD)
	# synthesize using Yosys
	$(YOSYS) -p "read_verilog -sv -noblackbox $(ICE) $(UART) $(SRC)/*; synth -top top; cd top; show -format svg -viewer gimp"

#Show the synthesied diagram
fpga-cells : $(ICE) $(SRC) $(PINMAP)
	# lint with Verilator
	verilator --lint-only --top-module top -Werror-latch -y $(SRC) $(SRC)/top.sv
	# if build folder doesn't exist, create it
	mkdir -p $(BUILD)
	# synthesize using Yosys
	$(YOSYS) -p "read_verilog -sv -noblackbox $(ICE) $(UART) $(SRC)/*; synth_ice40 -top top; show -format svg -viewer gimp"

# Combination Lock Demo
.PHONY: lock_demo
lock_demo:
	mkdir -p $(BUILD)
	$(YOSYS) -p "read_verilog -sv $(ICE) support/lock_bb_top.sv support/blackbox_lock.v $(UART); synth_ice40 -top ice40hx8k; write_json $(BUILD)/$(FPGA_TOP).json"
	$(NEXTPNR) --hx8k --package ct256 --placer-heap-cell-placement-timeout 0 --pcf $(PINMAP) --asc $(BUILD)/$(FPGA_TOP).asc --json $(BUILD)/$(FPGA_TOP).json 2> >(sed -e 's/^.* 0 errors$$//' -e '/^Info:/d' -e '/^[ ]*$$/d' 1>&2)
	icepack $(BUILD)/$(FPGA_TOP).asc $(BUILD)/$(FPGA_TOP).bin
	iceprog -S $(BUILD)/$(FPGA_TOP).bin

# Clean temporary files
clean:
	rm -rf build/ mapped/ *.log waves/*.vcd


# Thorough cleaning (remove all PDK files)
.PHONY: veryclean
veryclean: clean
	@rm -rf $(PDK_ROOT) &&\
	echo -e "PDK files removed!\n"


