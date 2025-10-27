#  Multi-Master Multi-Slave I²C System (3 Masters, 3 Slaves)
<img width="300" height="304" alt="image" src="https://github.com/user-attachments/assets/9f56671c-7b53-445e-9695-c103f057a844" />


---

##  Overview

This project implements a **fully functional I²C (Inter-Integrated Circuit) bus system** in **SystemVerilog**, featuring:

- **3 Master Controllers**
- **3 Target (Slave) Devices**
- **Shared open-drain SCL and SDA lines**
- **Clock synchronization**
- **Clock stretching**
- **Bus arbitration logic**
- **Multi-controller priority handling**

The design is modular, scalable, and adheres to I²C protocol standards.  
It provides an accurate hardware-level model suitable for FPGA or ASIC simulation environments.

---

##  Key Features

| Feature | Description |
|----------|-------------|
|  **Multi-Master Bus** | Supports 3 controllers operating on a shared I²C bus |
|  **Multi-Target Interface** | Each target has a unique 7-bit address and data send buffer |
|  **Clock Stretching** | Slaves can hold SCL low to delay the master when not ready |
|  **Arbitration** | Ensures fair access when multiple masters initiate communication simultaneously |
|  **Clock Synchronization** | Masters synchronize SCL lines using open-drain wired-AND logic |
|  **Open-Drain Behavior** | SDA and SCL lines modeled with `tri1` for realistic bus contention |
|  **Parameterizable Data Widths** | Easily configurable byte send/receive limits via parameters |
|  **Readable Structure** | Clean separation of top, controller, and target modules |
|  **Comprehensive Testbench** | Simulates multiple communication scenarios with timing and arbitration checks |

---


Each master and target module connects to the **shared SDA and SCL lines**, modeled as `tri1` for open-drain behavior.  
If any device drives the line low, it’s seen as `0` on the bus; otherwise, it remains high due to the pull-up effect.

---

##  Parameter Configuration

| Parameter | Default | Description |
|------------|----------|-------------|
| `BYTES_SEND_LOG` | `2` | Logarithm of max bytes to send (2 → 3 bytes) |
| `BYTES_RECEIVE_LOG` | `2` | Logarithm of max bytes to receive (2 → 3 bytes) |
| `BITS_SEND_MAX` | Derived | `(2**BYTES_SEND_LOG - 1) << 3` = max bits per transaction |

---

##  Testbench Details
  
The testbench demonstrates all functional aspects of the bus, including arbitration and multi-slave communication.

###  Test Phases

| Phase | Description | Involved Masters/Targets |
|--------|--------------|--------------------------|
| 1️ | Master 1 sends to Target 1 | M1 → T1 |
| 2 | Master 2 sends to Target 2 | M2 → T2 |
| 3 | Masters 1 & 3 start simultaneously (arbitration test) | M1 ↔ M3 competing |



============================
I2C Multi-Master Test Complete
============================



