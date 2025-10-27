# I2C-Protocol

#  I²C Multi-Master and Multi-Slave Communication System 

---

##  Overview

This project implements a **complete I²C (Inter-Integrated Circuit)** communication system in **SystemVerilog**, supporting **multiple masters** and **three slave devices**. It includes an **accurate behavioral model** of the I²C protocol compliant with the **Standard Mode (100 kHz)** specification.

The system demonstrates key I²C features such as:

- Multi-master arbitration  
- Address-based slave selection  
- Read and write transactions  
- Acknowledgment (ACK/NACK) handling  
- Clock stretching and synchronization  
- Timing compliance with I²C standard specifications  

The design can be simulated using **ModelSim**, **QuestaSim**, or any **SystemVerilog-compatible simulator**.

---

##  System Architecture

###  Components

| Module | Description |
|--------|-------------|
| `controller_I2C.sv` | Implements the I²C Master controller logic. Generates start/stop conditions, manages read/write operations, and handles arbitration. |
| `target_I2C.sv` | Implements an I²C Slave (Target) with a unique 7-bit address. Can send or receive data depending on the master’s request. |
| `I2C_top.sv` | Top-level file interconnecting multiple masters and three slaves through shared SDA and SCL lines. |
| `I2C_TB.sv` | Comprehensive SystemVerilog testbench that verifies all functionalities including write/read cycles, address mismatches, and arbitration. |

---

##  Key Features

###  Protocol Compliance
- Fully compliant with **I²C Standard Mode (100 kHz)** timing requirements.
- START, STOP, ACK, and NACK conditions implemented per specification.

###  Multi-Master Capability
- Three independent master controllers can initiate communication.
- Includes **arbitration** and **clock synchronization** logic.

###  Multi-Slave Support
- Three slave devices connected to the same SDA/SCL bus.
- Each has a unique **7-bit address** and independent data buffers.

###  Clock Stretching
- Implemented on the slave side for simulating slower response conditions.
- Masters correctly wait until the clock is released.

###  Parameterization
All important aspects can be easily modified through parameters:
| Parameter | Description | Default |
|------------|-------------|----------|
| `ADDR_TARGET` | 7-bit address of slave | `7'b0000111` |
| `BYTES_SEND` | Bytes transmitted by slave | `2` |
| `BYTES_RECEIVE` | Bytes received by slave | `2` |
| `STRETCH` | Clock stretch duration (in cycles) | `1000` |
| `THD_STA` | Hold time for START condition | `225` cycles |
| `TSU_STO` | Set-up time for STOP condition | `225` cycles |

---

##  I²C Protocol Background

The **I²C bus** uses two bidirectional open-drain lines:

- **SCL (Serial Clock Line)** — clock provided by master(s).  
- **SDA (Serial Data Line)** — data line used for sending and receiving bits.

### I²C Bus Conditions:
- **START (S)**: SDA transitions from HIGH → LOW while SCL is HIGH.
- **STOP (P)**: SDA transitions from LOW → HIGH while SCL is HIGH.
- **ACK (A)**: Receiver pulls SDA LOW after each byte received.
- **NACK (N)**: Receiver leaves SDA HIGH to indicate no acknowledgment.

---

##  Operation Summary

### 1️ Address Phase
1. The master generates a **START condition**.  
2. Sends a 7-bit **address** + 1-bit **R/W flag** (`0 = Write`, `1 = Read`).  
3. The addressed slave acknowledges by pulling **SDA LOW** during the ACK bit.

### 2️ Data Phase
- If `R/W = 0`: Master sends data bytes to slave.
- If `R/W = 1`: Slave sends data bytes to master.
- After each byte, an ACK/NACK is transmitted.

### 3️ Stop Condition
- Master generates a **STOP condition** to release the bus.

---



