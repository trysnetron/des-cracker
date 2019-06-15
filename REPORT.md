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

 ![waveform engine1](images/wf-engine.png?raw=true)

For this (and most of the coming validations) we use the the following plain text, key and cipher text: `plain text = 0x123456789ABCDEF`, `key = 0x12695BC9B7B7F8` and `cipher text = 85E813540F0AB405`. From the waveform we can see that when the correct key is put as input, the match signal goes high.

### Interface - Engine 2

### Validation - Engine 2

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

The controller works by creating an array of engines, and then supplying them with different keys, incrementing the given keys for each clock cycle. Starting in IDLE, it transitions to WORKING, when the `run` signal is high. When in state WORKING the controlles checks whether any of the engines have had a match at the start of each clock cycle. If a match is found, the controller finds the index of the engine with correct key, extracts the key with the same index from the array of current keys being, writes that key to `k1`, and sets the `irq` signal high.
Then it changes state to FINISHED, and waits for `run` to be set low, resetting it to the IDLE state. If none of the engines have find a match, we stay in WORKING and each of the keys in the array of keys being worked on are incremented by the _number of engines_. This makes the engines always crack different keys without overlap.

This is illustrated in the diagram below. Also, in each clock cycle, the current key `k` is set to the last key in the key array.

![SM diagram](images/engine_controller_sm.png?raw=true "State machine diagram of engine controller")

The implementation of the engine controller can be found in `des_sm.vhd` and it's corresponding simulation entity in `sim_des_sm.vhd`.

## Validation

This entity was easier to validate by inspecting the waveforms, however we also use som assert statements to 

![WF 1 of state machine](images/wf-sm-1.png?raw=true)
![WF 2 of state machine](images/wf-sm-2.png?raw=true)


## AXI4 Lite wrapper

The AXI4 Lite wrapper is, as the name suggests, just a thin wrapper around the rest of the system. It is capable of communicating via the AXI4 Lite protocol, making it possible for the embedded ARM Cortex CPU on the Zybo board interact with the DES cracker. 

### Interface 

| Name             | Direction | Type                           | Description                               |
| :----            | :----     | :----                          | :----                                     |
| `aclk`           | in        | std_ulogic                     | Master clock from CPU part of Zynq core   |
| `aresetn`        | in        | std_ulogic                     | Reset signal, synchronous and active low  |
| `s0_axi_araddr`  | in        | std_ulogic_vector(11 downto 0) | Read address                              |
| `s0_axi_arvalid` | in        | std_ulogic                     | Read address valid                        |
| `s0_axi_arready` | out       | std_ulogic                     | Read address acknowledge                  |
| `s0_axi_awaddr`  | in        | std_ulogic_vector(11 downto 0) | Write address                             |
| `s0_axi_awvalid` | in        | std_ulogic                     | Write address valid flag                  |
| `s0_axi_awready` | out       | std_ulogic                     | Write address acknowledge                 |
| `s0_axi_wdata`   | in        | std_ulogic_vector(31 downto 0) | Write data                                |
| `s0_axi_wstrb`   | in        | std_ulogic_vector(3 downto 0)  | Write byte enables                        |
| `s0_axi_wvalid`  | in        | std_ulogic                     | Write data and byte enables valid         |
| `s0_axi_wready`  | out       | std_ulogic                     | Write data and byte enables acknowledge   |
| `s0_axi_rdata`   | out       | std_ulogic_vector(31 downto 0) | Read data response                        |
| `s0_axi_rresp`   | out       | std_ulogic_vector(1 downto 0)  | Read status response                      |
| `s0_axi_rvalid`  | out       | std_ulogic                     | Read data and status response valid flag  |
| `s0_axi_rready`  | in        | std_ulogic                     | Read response acknowledge from CPU        |
| `s0_axi_bresp`   | out       | std_ulogic_vector(1 downto 0)  | Write status response                     |
| `s0_axi_bvalid`  | out       | std_ulogic                     | Write status response valid               |
| `s0_axi_bready`  | in        | std_ulogic                     | Write response acknowledge                |
| `irq`            | out       | std_ulogic                     | Interrupt request                         |
| `led`            | out       | std_ulogic_vector(3 downto 0)  | Wired to the four user LEDs               |

The general contraints of the AXI4 lite system is that each of the registers `p`, `c`, `k0`, `k` and `k1` must be written to/read in two separate write/read requests. The read/write response is encoded as follows:
* If the CPU tries to access adresses, that are not mapped, the response should be DECERR. 
* If the CPU tries to submit a write request to a read-only adresses, the response should be SLVERR
* Otherwise, reponse is OKAY.

There have been set some constraints as to how the communication shall work, and these help us detail what tests we have made for the axi-wrapper. Below are the constraints in a list format

1. The design should be able to handle read/write requests submitted simultaneously. 

2. `p` and `c` are read-write registers without side effect, and `k1` is a read-only register without side effect. 

3. `k0` is a read-write register with the side effect that when the cracking machines starts when the MSB are written to, and stops when the LSB are written to. 

4. When there is submitted a read-request for the LSB of `k`, the value of `k` must be frozen such that the value of `k` is the same untill the entire value of `k` is read. 

The implementation of the axi-wrapper can be found in `des_cracker.vhd` and the corresponding simulation file can be found in `sim_des_cracker.vhd`. 

### Validation 

To make sure that our AXI-wrapper met the constraints mentioned above we use the following tests

1. We test that the cracker starts when the correct sequence of registers is written to. First, `p`, then `c` then `k0` LSB and lastly `k0` MSB. In this point we also test that the AXI wrapper can handle write requests to mapped adresses. We also wait untill the correct key is found, and check that it returns the correct key. 

2. We test that the cracker stops when the LSB of `k0` are written to. 

3. We test that the value of `k` freezes while in between read requests of `k` LSB and MSB

4. We test that we get the correct responses when submitting read/write requests to addresses that are not mapped to, and when submitting write requests to adresses that are read-only. 

![AXI WF1](images/wf-cracker-1.png?raw=true)
![AXI WF2](images/wf-cracker-2.png?raw=true)
![AXI WF3](images/wf-cracker-3.png?raw=true)
![AXI WF4](images/wf-cracker-4.png?raw=true)

As before we use asserts often to validate, but these images show the waveforms generated compiling with GHDL, and viewed using GTKWave as well. 

## Synthesis

After synthesis we found that we were able to generate as much as 12 engines, using 88% of the logical ports on the FPGA and 4% of the slice registers. This part of the synthesis report is shown below

![LUT USAGE](images/logic_port_usage.png?raw=true "Logic Unit and Memory Usage")

In relation to the timing the longest path in the design requires 53 ns to propagate through, meaning that the highest clock frequency we could operate at was 19 MHz. This is shown below. 

![Timing Report](images/timing_report.png?raw=true "Timing report")

## Conclusion

Operating at a clock frequency of 19 MHz with 12 des-engines is probably far from the best design this year, but it means that we can test 228 million keys per second. However, with 2 to the power of 56 possible keys. The worst case is still that it would take 3658 days (approximately 10 years) to crack a 64 bit cipher with one Zybo board. 

## References

* [1] DES standard
* [2] TU Berlin
