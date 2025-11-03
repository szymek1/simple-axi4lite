# FPGA-TCL-Makefile-template
## Overview
Repository containing TCL-Makefile template for FPGA projects intended to automate build, test and program processes.
This template utilizes TCL scripting language in conjunction with Makefile. It provides a clear template for describing FPGA project:
- project name
- top module
- HDL of choice (Verilog, VHDL, System Verilog)
- FPGA device for synthezis

It currently supports only Xilinx Vivado simulators.
TCL part of this project got inspired by this [Vivado tempate](https://github.com/adamchristiansen/minimal-vivado-template/blob/main/generate_project.tcl).

## Structure
The template inposes a specific project's structure which has to be followed in order to use it.
```
.
├── bin
├── log
├── Makefile
├── dep_analyzer.py
├── scripts
│   ├── build.tcl
│   ├── program_board.tcl
│   └── simulate.tcl
├── simulation
│   └── waveforms
└── src
    ├── constraints
    │   └── constraints.xdc
    ├── hdl
    │   └── top.v
    └── sim
        ├── top_tb.v 
```
- ```bin/```: stores compiled bitstream and netlists
- ```log/```: stores logs produced by each of TCL scripts
- ```scripts/```: stores TCL scripts called from Makefile
- ```simulation/```: stores simulation results and logs per run testbench
- ```src/```: stores HDL and tesbenches source code as well as constraint file

The Makefile from the root directory requires the following structure and to some extend it can instantiate it.

## Usage
Inside the Makefile user can specify paths to descirbed above directories. Provided Makefile contains an example how this could look like.
Furthermore, the name of the project, language and device have to be specified (currently only a single language per project is allowed).
Several directovies govern the workflow:
- ```make conf```: checks, if all direcotires exist and instantiates them in case some are missing
- ```make sim_all```: runs all availabele testbenches which are stored inside ```src/sim/```-> each tesbench will have a separate direcotry inside ```simulation/waveforms```
- ```make sim_sel TB="..."```: runs only selected (one or multiple) tesbenches and stores their results inside ```simulation/waveforms```. ***use quote marks to place multiple tesbenches, use only module names!***
- ```make bit```: generates bitstream and netlist which are stored respectively inside ```bin/bit``` and ```bin/netlist```
- ```make program_fpga```: programs an FPGA device according to ```device``` field from the Makefile
- ```make clean```: clears ```bin/``` and ```log/``` directories. ***its doesn't clear ```simulation/```***

In the root directory there is an imporant script which has to be included in any projects making us of this template- ```dep_analyzer.py```. It is responsible for gathering compile sources during executing ```sim_sel``` target for a specified testbench/testbenches and for them only. This solution speeds up compilation time as no longer all the sources compile for a single testbench (which might not even use it- yes, I know I well thought it at the beginning xd).

### First use
Run ```make conf``` to prepare missing directories which ```.gitignore``` skips or move on to any other directive except of ```clean``` as they rely on ```conf```.

## TODOs:
- multi-language support (allow mixed-language projects)
- support for non-commercial simulators like Verilator etc...
- add ```data``` dictionary from which some tesbenches could fetch data for simulations (subject of tests, if this is really an issue for this template)
- add tests results analysis tool
- add instruction how to integrate with CI/CD tools for cutting-edge automation
- modify ```dep_analyzer.py``` to group testbenches with their respective sources and potentially cache them so they don't get compiled multiple times