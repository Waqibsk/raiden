# ============================================
# PROJECT CONFIGURATION
# ============================================

# Directory Structure
RTL_DIR   = design
TB_DIR    = testbench

# Source Files
# All Design Files (ALU, Decoder, Register File, etc.)
# The Testbench (tb_processor.sv)
SV_SRC    = $(RTL_DIR)/*.sv $(TB_DIR)/tb_processor.sv

# Output Executable Name
OUT_EXE   = raiden_sim

# ============================================
# TOOLS
# ============================================

# Icarus Verilog Compiler & Simulator
IV      = iverilog
VVP     = vvp

# Flags
# -g2012: Enables SystemVerilog 2012 standard
# -Wall:  Enables all warnings 
VFLAGS  = -g2012 -Wall

# ============================================
# BUILD TARGETS
# ============================================

# Default target: Compile and Run
all: compile run

# ----------------------------------
# Compile Verilog (Hardware Build)
# ----------------------------------
compile:
	@echo "========================================"
	@echo " Compiling Verilog Sources..."
	@echo "========================================"
	$(IV) $(VFLAGS) -o $(OUT_EXE) $(SV_SRC)
	@echo " Compilation Successful! Output: $(OUT_EXE)"

# ----------------------------------
# Run Simulation
# ----------------------------------
run: compile
	@echo "========================================"
	@echo " Running Simulation..."
	@echo "========================================"
	$(VVP) $(OUT_EXE)

# ----------------------------------
# View Waveforms
# ----------------------------------
wave: run
	@echo "========================================"
	@echo " Opening GTKWave..."
	@echo "========================================"
	gtkwave waveform.vcd &
# ----------------------------------
# Utilities
# ----------------------------------

# Clean up generated files
clean:
	rm -f $(OUT_EXE) waveform.vcd
	@echo "Cleaned up."

# Help command
help:
	@echo "Available targets:"
	@echo "  make        - Compile and run the simulation"
	@echo "  make compile- Compile only"
	@echo "  make run    - Run the simulation (compiles if needed)"
	@echo "  make wave   - View waveforms (compiles and runs if needed)"
	@echo "  make clean  - Remove the executable"
