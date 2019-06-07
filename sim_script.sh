export PATH=$PATH:/packages/LabSoC/Mentor/Modelsim/bin
export PATH=$PATH:/packages/LabSoC/Xilinx/bin
src=./src
vlib work
vmap work work
vcom -2008 -work work $src/des_pkg.vhd $src/des_key_checker.vhd $src/des_sm.vhd $src/des_cracker.vhd $src/sim_des_cracker.vhd
#vsim -c -do "run -all; quit;" des_pkg_sim # Simulutaion of package functions
#vsim des_engine_sim # Simulation of engine
#vsim des_key_checker_sim 
vsim sim_des_cracker 
# . sim_script
