# Here we set which board and xilinx chip we are using
set board [get_board_parts digilentinc.com:zybo*]
set part xc7z010clg400-1

# Here we print information about the variables 'script' and 'design' 
proc usage {} {
  puts "
usage: vivado -mode batch -source <script> [-tclargs <design>]
  <script>: TCL script
  <design>: name of top entity and basename of the VHDL source file
            optional, defaults to basename of <script>"
  exit -1
}

# Here we se the values of the variables 'script' and 'src'.
set script [file normalize [info script]]
# The line below defining 'src' should be changed, as it says the src directory is the same directory as the tcl script. Or we can put the tcl script in the source directory
set src [file dirname [file dirname $script]] 
puts $src
#regsub {\..*} [file tail $script] "" design
#
#if { $argc == 1 } {
#  set design [lindex $argv 0]
#} elseif { $argc != 0 } {
#  usage
#}
#
## Here we summarize parameters of the synthesis build
#puts "*********************************************"
#puts "Summary of build parameters"
#puts "*********************************************"
#puts "Board: $board"
#puts "Part: $part"
#puts "Source directory: $src"
#puts "Design name: $design"
#puts "Frequency: $frequency_mhz MHz"
#puts "Start delay: $start_us µs"
#puts "Warm-up delay: $warm_us µs"
#puts "*********************************************"
#
##############
## Create IP #
##############
#set_part $part
#set_property board_part $board [current_project]
#read_vhdl $src/lab02/sr.vhd
#read_vhdl $src/lab02/timer.vhd
#read_vhdl $src/lab03/edge.vhd
#read_vhdl $src/lab04/counter.vhd
#read_vhdl $src/lab04/dht11_pkg.vhd
#read_vhdl $src/lab04/dht11_ctrl.vhd
#read_vhdl $src/lab06/dht11_ctrl_axi_wrapper.vhd
