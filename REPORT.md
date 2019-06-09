# DES Cracker
_By Yohann Jacob Sandvik and Trym Sneltvedt_


## Hardware

### DES_ENGINE.VHD
The core of our DES cracker, the DES implementation.

It has the following ports:

- **clk** the clock signal driving the engine
- **sresetn** reset (synchronous, active low)
- **plaintext** the plaintext to be encrypted
- **ciphertext** the correct cipher text, used to verify the key
- **key** the key to be used for encryption
- **complete** Goes high when the encryption and cipher comparison is completed
- **success** Goes high along with complete if the given plaintext and key encrypts to the given ciphertext

Operation of the engine is as follows:

1. Load ciphertext, plaintext and key into the ports
2. Reset engine, releasing the reset starts the encryption process
3. When the encryption and comparison is finished, `complete` is set high, and if the cipher matches the one given, `success` also.

## Linux driver

It's necessary to interface with the DES cracker from the CPU on the Zybo board. The CPU is running a GNU/Linux operating system, this prompts us to write a Linux driver. 
