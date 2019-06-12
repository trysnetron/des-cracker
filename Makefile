# Modelsim paths (for Eurecom computers)
MODELSIMPATH = /packages/LabSoC/Mentor/Modelsim/bin
VIVADOPATH = /packages/LabSoC/Xilinx/bin
VLIB = $(MODELSIMPATH)/vlib
VMAP = $(MODELSIMPATH)/vmap
VCOM = $(MODELSIMPATH)/vcom
VSIM = $(MODELSIMPATH)/vsim
VIVADO = $(VIVADOPATH)/vivado

MS_WD = work
GH_WD = gh_work

# Source files, listed in order of compilation (it matters)
LST = des_pkg  des_key_checker  des_sm  des_cracker

SRC = $(patsubst %,src/%.vhd,$(LST))
SIMSRC = $(patsubst %,src/sim_%.vhd,$(LST))
SIM = $(patsubst %,%_sim,$(LST)) 

# GHDL 

compile-gh:
	ghdl -a --std=08 --workdir=$(GH_WD) $(SRC) $(SIMSRC)

check-gh: compile-gh
	ghdl -r --std=08 --workdir=$(GH_WD) des_pkg_sim sim
	ghdl -r --std=08 --workdir=$(GH_WD) des_key_checker_sim sim --stop-time=500ns --vcd=$(GH_WD)/wf_key_checker.vcd
	ghdl -r --std=08 --workdir=$(GH_WD) des_sm_sim sim --stop-time=500ns --vcd=$(GH_WD)/wf_sm.vcd
	ghdl -r --std=08 --workdir=$(GH_WD) des_cracker_sim sim --stop-time=500ns --vcd=$(GH_WD)/wf_cracker.vcd

# ModelSim 

compile:
	$(VLIB) $(MS_WD)    
	$(VMAP) work $(MS_WD)
	$(VCOM) -2008 -work $(MS_WD) $(SRC) $(SIMSRC) 


# Run all tests in the terminal (doesn't open ModelSim GUI)
check: compile
	$(VSIM) -c -do "run -all; quit;" $(SIM) 

sim: compile
	$(VSIM) des_cracker_sim

sim_%: compile
	$(VSIM) $*_sim

syn: compile
	cd syn && $(VIVADO) -mode batch -source ../des.syn.tcl -notrace -tclargs des_cracker	

clean: 
	rm -rf .Xil/ .srcs/ des_cracker/
	rm -f *.rpt
	rm -f *.jou
	rm -f *.log
	rm -f *.html
	rm -f *.xml
	rm -f des_cracker.bit
	rm -rf $(MS_WD)
	rm -rf $(GH_WD)
