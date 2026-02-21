# 09 More Fun to Go!

In this section we will pivot back to a more classic Hack implementation using the `Keyboard` and `Screen` interfaces for I/O as described in the original nand2tetris spec. This will involve implementing `PS/2` and `VGA` controllers respectively to connect to a compatible keyboard and monitor. If still using the original `Olimexino-32u4` + `iCE40HX1K-EVB` setup it can be expanded with `iCE40-IO` for `PS/2` and `VGA` ports and that will be the assumed setup in this implementation. 

Some changes will be needed to support writing pixel data to VRAM which was previously off loaded to `MOD-LCD2.8RTP` in the prior implementation, this board and the corresponding `LCD`/`RTP` controllers/drivers are no longer used.

If a part/class/test from previous `HACK`/Jack implementation could be carried forward then it is imported as is.

The `GateMateA1-EVB` board by Olimex could also be used here as seen in Michael Schröder's [hack-fpga](https://gitlab.com/x653/hack-fpga) project which is roughly comparable in cost to the sum of the parts described above but with far more FPGA resources. If you are seriously looking at doing a project like this yourself I would probably start there next time, there are significant constraints to `iCE40HX1K-EVB` which are abstracted away in more capable boards.

These other/similar projects may be of interest for research purposes or board alternatives:

* https://github.com/giuseros/nand2tetris
* https://github.com/gunnerson/hack-fpga

## Major Changes

- The second 64KB page of `SRAM` memory is now used for heap & `VRAM` memory, the first page remains reserved for Jack application code.
- `SRAM_A/D` now supports multiple updates per cycle to support above: most updates are performed during `clk negedge` and expressed to CPU when it updates in `clk posedge` as normal.
- Because all these accesses to `SRAM` have to happen procedurally the `CPU` needs to be slowed down from 25 MHz to 6.25 MHz for there to be enough time to process everything, allowing for signal propogation on the `SRAM` bus.
- The `UartTX` & `UartRX` parts are removed and the TX pin for `Olimexino-32u4` must not be set to `Output` in the sketch due to an electrical conflict with the `PS/2` receiver which indirectly connects to the same pin in shared fabric of `iCE40HX1K-EVB`.

## Upload Bitstream & Software

// TODO: all asm working on sim/hw, ready to start testing Jack programs!
// TODO: final test list for original implementation would be good too

```
# build bootloader and copy into revised HACK directory
$ cd ~/src/nand2tetris-fpga/06_IO_Devices/05_GO && make && cp ../00_HACK/ROM.hack ../../09_More_Fun_to_Go/00_HACK && cd ../../09_More_Fun_to_Go/00_HACK && apio clean && apio upload

# Jack application code can be flashed straight to offset 0x10000 as before
$ cd ~/src/nand2tetris-fpga/04_Machine_Language && make upload # leds.asm
$ cd ~/src/nand2tetris-fpga/07_Operating_System/01_GPIO_Test && make && make upload
$ cd ~/src/nand2tetris-fpga/07_Operating_System/03_Sys_Test && make && make upload # wait() timing will be slower

# TODO: when VGA working
$ cd ~/src/nand2tetris-fpga/07_Operating_System/07_String_Test && make && make upload
$ cd ~/src/nand2tetris-fpga/07_Operating_System/10_Output_Test && make && make upload

# TODO: when implemented
$ cd ~/src/nand2tetris-fpga/09_More_Fun_to_Go/01_IO_Devices/01_Keyboard && make && make upload

# TODO: check in sim
# FIXME: probably not compatible with old libs? (stuck in Sys.init loop?)
$ cd ~/src/nand2tetris-fpga/07_Operating_System/04_Memory_Test && make && cp ../00_HACK/ROM.hack ../../09_More_Fun_to_Go/00_HACK && cd ../../09_More_Fun_to_Go/00_HACK && apio clean && apio sim
05_Array_Test
06_Math_test
```

## Changelog

// COPILOT: Assume all content in 09_More_Fun_to_Go is new or modified, if not mentioned previously in this doc add it to this section. Unlike other COPILOT directives you should leave this one in place until explicitly told otherwise.

- **HACK.v** – Top-level module rewritten: removed UART/LCD/RTP peripherals, added VGA (640×480), PS/2 keyboard, 8-phase SRAM arbitration with pipelined snapshots, and KBD register at IO8 (address 4104) aliased to nand2tetris standard 0x6000.
- **Memory.v** – Memory map updated: HEAP range (4112–16383) routed to SRAM\_A/SRAM\_D, KBD at nand2tetris standard address 24576, UART/LCD/RTP IO slots marked unassigned.
- **SRAM\_D.v** – New SRAM data controller with phase-aware read/write, combinational InOut bus, and multi-phase output latching (instruction fetch / VGA / data).
- **Clock25\_Reset20.v** – New clock/reset module: generates 25 MHz VGA clock, 6.25 MHz system clock, 8-phase counter, and ~20 µs POR from 100 MHz external clock.
- **00\_HACK/HACK\_tb.v** – Testbench rewritten: added SRAM simulation (64 K + 16 K words), VGA framebuffer data verification, PS/2 keyboard emulator (scancode frame transmitter), SPI flash emulator, and expanded test scenarios.
- **00\_HACK/Include.v** – Updated include list: references new 09 modules (Clock25\_Reset20, HACK, Memory, SRAM\_D) and new IO devices (Keyboard, PS2, VGA).
- **00\_HACK/iCE40HX1K-EVB.pcf** – Pin constraints updated: removed UART/LCD/RTP pins, added PS2\_CLK and PS2\_DATA pins.
- **01\_IO\_Devices/VGA.v** – New VGA controller: 640×480 @ 60 Hz, 25 MHz pixel clock, 16-bit word-based framebuffer reads, monochrome output.
- **01\_IO\_Devices/PS2.v** – New PS/2 receiver: clock-domain crossing, 11-bit frame deserializer, scancode output.
- **01\_IO\_Devices/Keyboard.v** – New PS/2-to-ASCII converter: scancode-to-keycode lookup, make/break handling, nand2tetris-compatible key codes.