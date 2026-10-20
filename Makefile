# Optional RTL checks (not needed to build or simulate with Quartus).
#
#   make lint       lint the RTL with Verilator
#   make synth      elaborate the RTL with Yosys as a synthesizability check
#   make clean

VERILATOR ?= verilator
YOSYS     ?= yosys
BUILD     ?= build

RTL_DIR := rtl
RTL     := $(wildcard $(RTL_DIR)/*.v)

.PHONY: all lint synth clean

all: lint

$(BUILD):
	mkdir -p $(BUILD)

lint:
	$(VERILATOR) --lint-only -Wall -Wno-ASCRANGE -I$(RTL_DIR) --top-module NuCore $(RTL)

synth: | $(BUILD)
	$(YOSYS) -q -p "read_verilog -I$(RTL_DIR) $(RTL); hierarchy -top NuCore; proc; opt; check -assert; stat" -l $(BUILD)/yosys.log

clean:
	rm -rf $(BUILD)
