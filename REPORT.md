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
This project has been about making a estimating the time it would take to crack the Data Encryption Standard (DES algorithm using the Zynq-7000 SoC. Given a 64 bit plain text **p**, and a 64 bit cipher text **c**, we check which 56 bit key yields **c** according to the DES algorithm. If the produced cipher text doesn't match the one provided, we increment the key and try again. We are provided a start key **k0**, telling us from which key to begin testing. 

We explore two possible designs of DES encryption engines coded in VHDL. We then try to instantiate as many engines as the FPGA on the Zybo will allow, and distribute the computations between them. The only contraints that have been set for us is that the top-level VHDL design must be in the file `des_cracker.vhd`, that we use the AXI4 Lite protocol for communication between the CPU and FPGA in the core and that as well as some arcitectural contraints to the architecture of the AXI-wrapper. 

In this report we discuss the different parts of our design, simulations used to validate the different parts of the design and some possible improvements that could have been done. 

## Design overview

The block diagram below shows what entities we instantiate, and in which files the different entities are. Each enncryption engine is capable of producing one cipher text, and the checker checks whether the ciphertext produced matches the cipher text given. 

![Blokk diagram](images/design_overview.png?raw=true "Block diagram of design")

After the checkers are finished checking whether the produced cipher text matches the provided one, they set a `complete` signal high to signalize that they are finished, and a `check` signal high or low to indicate if they have found the correct key. The engine controller then decides whether to increment the keys of the engines based on `complete`, and `check`.

## Package

The entirety of the DES algorithm is implemented in the des_package.vhd file.

## Engines

The engine is the core of our design. It is responsible for encrypting a plaintext using the DES algorithm and deciding wether the given key was correct.

### Interface - Engine 1

| Port | I/O | Type | Description |
| ---- | --- | ---- | ----------- |
| `p`  | in  | std_ulogic_vector(63 downto 0) | The plaintext |
| `c`  | in  | std_ulogic_vector(63 downto 0) | The ciphertext |
| `k`  | in  | std_ulogic_vector(55 downto 0) | The key |
| `match`| out | std_ulogic | Whether `p` encrypted with `k` matches `c` or not | 

 We started out with the simplest possible design, a purely combinatorial engine that computes one ciphertext, and compares it with the correct ciphertext in one clock cycle. This architecture, while simple, does not perform very well. The plan was that after we had implemented the entire system we would make an engine that could work faster, and reuse more hardware such that we could instantiate more of them. Sadly we were not able to complete the second engine in time. 

 The implementation of engine 1 can be found in `des_engine.vhd`, and it's corresponding simulation file can be found in `sim_des_engine.vhd`. 

 ### Validation - Engine 1 

 The functionality of this engine was hard to validate by looking at waveforms alone, as it is purely combinatorial. Therefore we use a set of `assert` statements to check whether the engine identifies the correct key, and disregards the wrong keys. However, below is an image from the the waveforms of the simulation of engine 1 using GHDL and GTKWave. 

 ![waveform engine1](images/waveform_engine1.png?raw=true "waveform of succesful engine")

For this (and most of the coming validations) we use the the following plain text, key and cipher text: `plain text = 0x123456789ABCDEF`, `key = 0x12695BC9B7B7F8` and `cipher text = 85E813540F0AB405`. From the waveform we can see that when the correct key is put as input, the match signal goes high.

## Controller 

The controller is the brain of our design. It initiates an array of engines and manages the keys given to them. It is made as a rather simple state machine with 3 states.

### Interface

| Port | I/O | Type | Description |
| ---- | --- | ---- | ----------- |
| `clk`     | in  | std_ulogic                     | Clock signal |
| `sresetn` | in  | std_ulogic                     | Reset signal, synchronous and active low |
| `run`     | in  | std_ulogic                     | Cracking signal, kept high for the cracking to occur. |
| `p`       | in  | std_ulogic_vector(63 downto 0) | The plaintext |
| `c`       | in  | std_ulogic_vector(63 downto 0) | The ciphertext |
| `k0`      | in  | std_ulogic_vector(55 downto 0) | The starting key |
| `k`       | out | std_ulogic_vector(55 downto 0) | The highest key currently being worked on |
| `k1`      | out | std_ulogic_vector(55 downto 0) | The correct key, when found |
| `irq`     | out | std_ulogic                     | Interrupt request, set high for one clock period when the correct key is found. |

![SM diagram](images/engine_controller_sm.png?raw=true "State machine diagram of engine controller")

The controller works by creating an array of engines, and then supplying them with different keys, incrementing the given keys for each clock cycle. At the start of each clock cycle, the controlles checks whether any of the engines have had a match, if they have, the controller finds the index of the engine with correct key, extracts the key with the same index from the array of keys being cracked by the engines, and writes that key to `k1`, as well as setting the `irq` signal high. Then it changes state to FINISHED, and waits for `run` to be set low, resetting it to the IDLE state. If none of the engines have a match, each of the keys in the array of keys being worked on are incremented by the _number of engines_. This makes the engines always crack different keys without overlap.

Also, in each clock cycle, the current key `k` is set to the last key in the key array.

## AXI4 Lite wrapper

The AXI4 Lite wrapper is, as the name suggests, just a thin wrapper around the rest of the system. It is capable of communicating via the AXI4 Lite protocol, making it possible for the embedded ARM Cortex CPU on the Zybo board interact with the DES cracker. 

## Synthesis

## Linux driver

It's necessary to interface with the DES cracker from the CPU on the Zybo board. The CPU is running a GNU/Linux operating system, this prompts us to write a Linux driver. 

## Test on Zybo board

## Conclusion

## References

* [1] DES standard
* [2] TU Berlin
