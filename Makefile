# Modelsim paths (for Eurecom computers)
MODELSIMPATH = /packages/LabSoC/Mentor/Modelsim/bin
VLIB = $(MODELSIMPATH)/vlib
VMAP = $(MODELSIMPATH)/vmap
VCOM = $(MODELSIMPATH)/vcom
VSIM = $(MODELSIMPATH)/vsim

WORKDIR = gh_work
SOURCE = src/des_pkg.vhd
SIM = src/des_sim.vhd

validate:
	ghdl -a --std=08 --workdir=gh_work src/des_pkg.vhd src/des_pkg_sim.vhd
	ghdl -r --std=08 --workdir=$(WORKDIR) des_pkg_sim sim --vcd=$(WORKDIR)/wf.vcd

# Verification with ModelSim 
validate-ms:
	$(VLIB) work
	$(VMAP) work work
	$(VCOM) -2008 -work work src/des_pkg.vhd src/des_pkg_sim.vhd
	$(VSIM) -c -do "run -all; quit;" des_pkg_sim 
