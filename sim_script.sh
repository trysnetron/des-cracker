export PATH=$PATH:/packages/LabSoC/Mentor/Modelsim/bin
export PATH=$PATH:/packages/LabSoC/Xilinx/bin
src=./src
vlib work
vmap work work
vcom -2008 -work work $src/des_pkg.vhd $src/des_engine.vhd $src/des_engine_sim.vhd
#vsim -c -do "run -all; quit;" des_sim
vsim des_engine_sim
# . sim_script