# DES Cracker
_By Yohann Jacob Sandvik and Trym Sneltvedt_

* [Introduction](#Introduction)
* [Package](#Package)
* [Design overview](#Design-overview)
* [Engines](#Engines)
* [Controller](#Controller)
* [AXI4 Lite wrapper](#AXI4-Lite-wrapper)
* [Synthesis](#Synthesis)
* [Linux driver](#Linux-driver)
* [Test on Zybo board](#Test-on-Zybo-board)

## Introduction
This project has been about making a estimating the time it would take to crack the Data Encryption Standard (DES) algorithm using the XXX zynq SoC. We explore two possible designs of DES encryption engines coded in VHDL. We then try to instantiate as many engines as the FPGA on the Zybo will allow, and distribute the computations between them. The only contraints that have been set for us is that the top-level VHDL design must be in the file `des_cracker.vhd`, that we use the AXI4 Lite protocol for communication between the CPU and FPGA in the core and that as well as some arcitectural contraints to the architecture of the AXI-wrapper. 

In this report we discuss the different parts of our design, simulations used to validate the different parts of the design and some possible improvements that could have been done. 

## Design overview

![Blokk diagram](images/design_overview.png?raw=true "Block diagram of design")

## Package

## Engines

## Controller 

## AXI4 Lite wrapper

## Synthesis

## Linux driver

## Test on Zybo board

## Conclusion

It's necessary to interface with the DES cracker from the CPU on the Zybo board. The CPU is running a GNU/Linux operating system, this prompts us to write a Linux driver. 
