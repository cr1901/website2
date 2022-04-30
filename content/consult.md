+++
title = "Consult"
date = 2019-05-30
updated = 2022-04-27
aliases = ["consult.html"]
+++

# Consulting Services
I have been freelancing on and off since September 2015. I offer
software and hardware development services such as:

* FPGA core design and verification
  * This includes designing [SoCs](https://en.wikipedia.org/wiki/System_on_a_chip) using [soft-cores](https://en.wikipedia.org/wiki/Soft_microprocessor).
* Writing firmware for microcontrollers without an OS (freestanding)
* Porting C/C++ source code tailored to [POSIX](https://pubs.opengroup.org/onlinepubs/9699919799.2018edition/)
  systems to Windows
* Vintage code base maintenance

Less recently, I have also been paid to develop:

* Desktop GUI applications using Qt 5
* Javascript widgets

I am still open to doing widget and GUI design.

## Programming Languages
I am most comfortable working with, in no particular order:

* Python 3
  * I have not written Python 2 since 2014.
* Rust
  * I track the most recent release of the compiler [every 6 weeks](https://doc.rust-lang.org/book/appendix-07-nightly-rust.html).
* C89 and C99
  * I can write C for targets with or without an OS, and proiritize portable
    code without compiler extensions when possible.
* C++11 and C++14
* Lua
  * This includes working on Lua bindings to C code.

## FPGAs
For FPGA work, I tend to use the [Amaranth](https://github.com/amaranth-lang/amaranth)
or [Migen](https://github.com/m-labs/migen) HDLs, the latter as part of the [LiteX](https://github.com/enjoy-digital/litex)
SoC ecosystem. I can also read and write Verilog (VHDL, less so).

Outside of client work, I also contribute to the open-source [yosys](https://github.com/YosysHQ/yosys)
Verilog synthesizer, and [nextpnr](https://github.com/YosysHQ/nextpnr) place-and-route tool.
With the exception of [Lattice Diamond](https://www.latticesemi.com/latticediamond), I am _much_
more familiar with using the above than with FPGA vendor tools directly.

I have worked with the following FPGA families in various capacities:

* [Lattice](https://www.latticesemi.com/en/Products.aspx) iCE40, ECP5, and MachXO2.
* [Xilinx](https://www.xilinx.com/products/silicon-devices/fpga.html) Spartan 3,
  Spartan 6, Spartan 7, and Artix 7.

In general I have spent more time with Lattice FPGAs than Xilinx, and I have not
recently used any FPGAs from Altera/Intel or other, smaller vendors (although
the latter is likely to change soon as of 2022-04-27).

My services are tailored to individuals and companies with open source
code bases who need a feature (this includes FPGA IP) or internal tool implemented.
Please feel free to <a href="mailto:wjones@wdj-consulting.com">email me</a> to discuss any work that
you need done and rates.

## Client Projects
### Project Facade
[Project Trellis](https://github.com/YosysHQ/prjtrellis) is a project by [gatecat](https://ds0.me)
to reverse-engineer the bitstream format and internal structure of the [Lattice ECP5](https://www.latticesemi.com/Products/FPGAandCPLD/ECP5)
family of FPGAs. Project Facade is my extension to Project Trellis with databases
for the [Lattice MachXO2](https://www.latticesemi.com/en/Products/FPGAandCPLD/MachXO2) family.

I found that MachXO2 and ECP5 families are [similar enough](https://github.com/YosysHQ/prjtrellis/pull/148)
internally that it made sense to reuse as much of Project Trellis as possible. In
addition, thanks to the efforts of gatecat (without them, this project would not
have succeeded), and [Andres Navarro](https://github.com/AndresNavarro82)
(who did bitstream compression reverse-engineering for), it should be possible
to use Project Trellis to more quickly reverse-engineer the remaining Lattice
families later on.

On 2021-01-31, I created, as far as I know, the [first bitstream](https://twitter.com/cr1901/status/1356042679608606721)
for MachXO2 devices using only open-source tools. However, there is still much
work to do, as indicated by the `nextpnr-machxo2` [README](https://github.com/YosysHQ/nextpnr/tree/master/machxo2#readme)!

### TinyUSB
[TinyUSB](https://github.com/hathach/tinyusb) is a open-source USB stack written in C
targeting microcontrollers that favors ease of usage and code size over performance.
A [large selection](https://github.com/hathach/tinyusb#supported-mcus) of
microcontroller families and CPU architectures (and multiple C compilers!) are
supported.

I have contributed the following ports/backends to TinyUSB:
* [Initial support](https://github.com/hathach/tinyusb/pull/38) for what would become
  a microcontroller-family-agnostic [Synopsys DesignWare USB 2.0 Controller](https://www.synopsys.com/dw/ipdir.php?ds=dwc_usb_2_0_hs_otg)
  [backend](https://github.com/hathach/tinyusb/tree/master/src/portable/synopsys/dwc2).
* [MSP430 support](https://github.com/hathach/tinyusb/pull/194)- the first port
  of TinyUSB to a non-32-bit device.

In addition, I've contributed demos of TinyUSB on various evaluation boards including:
  * [STM32F4DISCOVERY](https://www.st.com/en/evaluation-tools/stm32f4discovery.html)
  * [NUCLEO-H743ZI](https://www.st.com/en/evaluation-tools/nucleo-h743zi.html)
  * [NUCLEO-F746ZG](https://www.st.com/en/evaluation-tools/nucleo-f746zg.html)
  * [pyboard](https://store.micropython.org/product/PYBv1.1)
  * [MSP-EXP430F5529LP](https://www.ti.com/tool/MSP-EXP430F5529LP)

## Other Projects
This section needs to be rewritten as of 2022-04-27. In the meantime, my
[IRC activity](/about/#irc) is a good glimpse into the type of projects I
contribute to.
