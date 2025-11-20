# MIPS32 Pipeline Processor
## Introduction
This repository contains the Verilog implementation of a MIPS32 pipeline processor. The design is based on the book "Digital Design and Computer Architecture" by David Money Harris and Sarah L. Harris. The processor includes a 5-stage pipeline: Instruction Fetch (IF), Instruction Decode (ID), Execute (EX), Memory Access (MEM), and Write Back (WB), along with a hazard detection unit to manage data and control hazards.
## Implementation
### Stages
1. Instruction Fetch (IF): Fetches the instruction from the instruction memory.  
2. Instruction Decode (ID): Decodes the fetched instruction and reads the necessary registers.  
3. Execute (EX): Performs arithmetic or logical operations.  
4. Memory Access (MEM): Accesses data memory for load and store instructions.
5. Write Back (WB): Writes the result back to the register file.
### Instruction Set
The MIPS32 pipeline processor currently supports the following instructions:  
* `add` - Add  
* `sub` - Subtract  
* `or` - Bitwise OR  
* `and` - Bitwise AND  
* `slt` - Set Less Than  
* `addi` - Add Immediate  
* `lw` - Load Word  
* `sw` - Store Word  
* `beq` - Branch if Equal  
* `j` - Jump  
### Hazard Unit
The hazard unit is responsible for detecting and resolving data and control hazards. It ensures that the pipeline operates smoothly without conflicts. The unit implements forwarding and stalling mechanisms to handle different types of hazards.
### Branch Predictor
The implementation uses a 2-bit bimodal direction predictor (PHT with 2-bit saturating counters) and a small Branch Target Buffer (BTB). Predictor updates happen in the ID stage (where branches are resolved); the IF stage consults the predictor + BTB to fetch a predicted next PC.

<img width="490" height="347" alt="image" src="https://github.com/user-attachments/assets/04326352-b348-43fd-83fb-29d9c973f819" />

### Datapath
![image](https://github.com/sushi0706/mips-pipeline-processor/assets/170224108/920233ca-2555-4a43-9681-acc92356f138)

## Tools
* Verilog compiler (such as Icarus Verilog)  
* Simulator (such as Modelsim)
## References
_Digital Design and Computer Architecture_ by David Money Harris & Sarah L. Harris
