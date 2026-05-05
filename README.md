# FPGA-Based Interactive System (Nexys A7)

Real-time FPGA system implementing an interactive "Simon Says"-style game using a finite state machine (FSM), VGA output, and hardware validation on the Digilent Nexys A7.

---

## Overview

This project implements a fully synchronous RTL design in Verilog that generates and validates user input sequences in real time. The system integrates input conditioning, control logic, display output, and VGA rendering under strict hardware timing constraints.

---

## Features

- Multi-state FSM for game control and sequence validation  
- Debounced button inputs with one-pulse generation  
- LFSR-based pseudo-random sequence generator  
- VGA output at 640x480 resolution  
- Seven-segment display integration  
- Simulation and on-board hardware verification  

---

## Hardware

- Digilent Nexys A7 FPGA board  
- Push buttons (user input)  
- LEDs / RGB LEDs (visual feedback)  
- Seven-segment display  
- VGA monitor  

---

## Project Structure

constraints/   -> FPGA pin mappings and timing constraints  
rtl/           -> Verilog RTL modules  
tb/            -> Verilog testbenches  
writeupEE354.pdf -> Final project report  
README.md      -> Project documentation  

---

## Constraints Files

- nexys_a7_simon_says.xdc → Main constraints file used for implementation  
- A7_detour_top.xdc → Alternate / reference constraints for Nexys conversion  

---

## Key Modules

- simon_says_top.v → Top-level module integrating all components  
- simon_game_sm.v → FSM for game logic and control flow  
- simon_vga_renderer.v → VGA rendering pipeline  
- debounce_onepulse.v → Button debounce + edge detection  
- vga_timing_640x480.v → VGA timing generator  
- ssd_mux.v → Seven-segment display multiplexing  

---

## Tools Used

- Verilog HDL  
- Xilinx Vivado  
- GTKWave  

---

## How to Run

1. Open Vivado and create a new project  
2. Add all files from:
   - rtl/
   - tb/
   - constraints/
3. Set `nexys_a7_simon_says.xdc` as the active constraints file  
4. Run simulation using testbench files in `tb/`  
5. Synthesize, implement, and generate bitstream  
6. Program the Nexys A7 FPGA  

---

## Notes

- Fully synchronous RTL design (no asynchronous logic)  
- Designed with modular architecture for clarity and reuse  
- Verified through simulation and physical hardware testing  
- Emphasizes deterministic timing and hardware-level debugging  
