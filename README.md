# Serial BCD Arithmetic Logic Unit (ALU)

## 📌 Overview
This project implements a custom Arithmetic Logic Unit (ALU) designed to perform addition and subtraction on 4-digit Binary Coded Decimal (BCD) numbers. Unlike standard parallel ALUs that require significant pin overhead, this system routes all data through a single-bit serial input line and a single-bit serial output line. It balances hardware footprint efficiency with clock-cycle tradeoffs, featuring sequence detection, combinational parallel math, and robust edge-case handling.

## ⚙️ System Architecture
The system is divided into three primary functional blocks:

* **Serial-In Parallel-Out (SIPO) & Sequence Detection:** Continuously shifts a 41-bit input stream. It scans for a hardcoded 8-bit synchronization header (`8'h67`). Once detected, the 33-bit payload (operation flag + two 16-bit operands) is locked into a parallel holding register.
* **16-bit Cascaded BCD ALU:** A purely combinational arithmetic core constructed by chaining four 4-bit BCD ALUs. This allows the 16-bit calculation to ripple through instantly, independent of the main system clock.
* **Parallel-In Serial-Out (PISO) Output Register:** After calculations, the system packages the result into a 20-bit (5-digit) BCD output, appends a hardcoded transmission header (`8'hA5`), and serially shifts the 28-bit frame out. 

## 🧮 Mathematical Implementation

### BCD Addition & Hexadecimal Correction
Because BCD uses a 4-bit, 8-4-2-1 encoding to represent digits 0-9, 6 of the 16 possible 4-bit combinations are mathematically invalid. 
* If a digit's raw binary sum exceeds 9 (e.g., 6 + 7 = 13, or 1101 in binary), the ALU applies an automatic hexadecimal correction.
* The hardware injects a +6 correction (0110 in binary) to bypass the invalid states, fixing the 4-bit sum and properly triggering a carry-out to the next digit.

### Subtraction via 10's Complement
Since standard 4-bit BCD encoding is not self-complementing, a direct 2's complement calculation yields incorrect results. 
* Subtraction is achieved using the **10's Complement method**. 
* The system calculates the 9's complement of the subtrahend and sets the initial carry-in high (+1) to reach the exact 10's complement.
* This approach allows the system to reuse the exact same 5-bit addition hardware for both operations, heavily optimizing the logic gate footprint.

## 🛠️ Key Technical Challenges Solved

**The "Embedded Header" Problem**
Handling continuous, asynchronous serial inputs creates a vulnerability where random data payload bits might accidentally match the `8'h67` control sequence, causing a false synchronization trigger. To resolve this, the RTL logic completely wipes the shift register to zero the exact clock cycle a valid header is verified. This hardware-level isolation prevents payload data from continuously shifting and falsely triggering the sequence detector.

## 🧪 Simulation & Verification
The design was rigorously verified via behavioral testbenches and automated grading (Gradescope), achieving 100% functional accuracy across all test parameters. 

* **Synthesis:** Elaborated and mapped to physical logic primitives using **Xilinx Vivado RTL**.
* **Waveform Verification:** Confirmed stable combinational rippling, correct borrow-discard on subtraction, and uninterrupted continuous input processing on back-to-back packets.

## 💻 Technologies Used
* **Hardware Description Language:** Verilog
* **Synthesis & Simulation:** Xilinx Vivado
* **Concepts:** Digital Logic Design, FSMs, Shift Registers, Serial Communication, Combinational Arithmetic
