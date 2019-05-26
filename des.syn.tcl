#!/usr/bin/tclsh

# Here we se the values of the variables 'script' and 'src'.
set script [file normalize [info script]]
set src "/homes/sandvik/des-cracker/src/" 

# Here we set which board and xilinx chip we are using (not working)
set board [get_board_parts digilentinc.com:zybo*] 
set part xc7z010clg400-1
