# 09 More Fun to Go!

In this section we will pivot back to a more classic Hack implementation using the `Keyboard` and `Screen` interfaces for I/O as described in the original nand2tetris spec. This will involve implementing `PS/2` and `VGA` controllers respectively to connect to a compatible keyboard and monitor. If still using the original `olimexino-32u4` + `iCE40HX1K-EVB` setup it can be expanded with `iCE40-IO` for `PS/2` and `VGA` ports and that will be the assumed setup in this implementation. 

Some changes will be needed to support writing pixel data to VRAM which was previously off loaded to `MOD-LCD2.8RTP` in the prior implementation, this board and the corresponding `LCD`/`RTP` controllers/drivers are no longer used.

If a part/class/test from previous `HACK`/Jack implementation could be carried forward then it is imported as is.

The `GateMateA1-EVB` board by Olimex could also be used here as seen in Michael Schröder's [hack-fpga](https://gitlab.com/x653/hack-fpga) project which is roughly comparable in cost to the sum of the parts described above but with far more FPGA resources. If you are seriously looking at doing a project like this yourself I would probably start there next time, there are significant constraints to `iCE40HX1K-EVB` which are abstracted away in more capable boards.

For keyboard I was using Adafruit's 60% hybrid USB and PS/2 [Keyboard](https://adafru.it/857) but anything with PS/2 (directly or as fallback) should work, I happened to have an old monitor that will had a VGA port (sometimes also referred to as `D-sub` or `DE-15` port) but don't have any modern recommendations for that one.

These other/similar projects may be of interest for research purposes or board alternatives:

* https://github.com/giuseros/nand2tetris
* https://github.com/gunnerson/hack-fpga

## Major Changes

- The second 64KB page of `SRAM` memory is now used for heap & `VRAM` memory, the first page remains reserved for Jack application code.
- `SRAM_A/D` now supports multiple updates per cycle to support above: most updates are performed during `clk negedge` and expressed to CPU when it updates in `clk posedge` as normal.
- Because all these accesses to `SRAM` have to happen procedurally the `CPU` needs to be slowed down from 25 MHz to 6.25 MHz for there to be enough time to process everything, mainly allowing for signal propogation on the `SRAM` bus.
- The `UartTX` & `UartRX` parts are removed and the TX pin for `olimexino-32u4` must not be set to `Output` in the sketch due to an electrical conflict with the `PS/2` receiver which indirectly connects to the same pin in shared fabric of `iCE40HX1K-EVB`.
- A dedicated power supply must be used for the `PS/2` receiver to function correctly which requires 5v. If not required then powering the system with 3.3v over UEXT (i.e. via `olimexino-32u4` from USB power or otherwise) is still fine.

## Upload Bitstream & Software

Non-exhaustive list of tests below, for several modules there are more specific `asm` tests for debugging but in general this should do for validation.

// FUTURE: final test list for original implementation would be good too

```
# build bootloader, copy into revised HACK directory & upload it (separately from remaining application code)
$ cd ~/src/nand2tetris-fpga/06_IO_Devices/05_GO && make && cp ../00_HACK/ROM.hack ../../09_More_Fun_to_Go/00_HACK && cd ../../09_More_Fun_to_Go/00_HACK && apio clean && apio upload

# Application code can be flashed straight to offset 0x10000 as before
$ cd ~/src/nand2tetris-fpga/07_Operating_System/01_GPIO_Test && make && make upload # Jack equivalent of leds.asm
$ cd ~/src/nand2tetris-fpga/07_Operating_System/03_Sys_Test && make && make upload # Jack equivalent of Blinky.v

# HACK_OS sims: can uncomment additional debug registers in HACK where necessary
# OS tests are too large to be sim'd without using a larger/non-uploadable ROM part (i.e. as done in original 07_Operating_System)
# some need a longer simulation time up to ~1.25 million ticks to complete on the slower CPU timing
# 03_Sys_Test needs to be switched to 1ms wait in sim (4-5ms with slower CPU timing)
# some dead refs to UART in assembler labels but shouldn't affect anything (removed in Jack code)
$ cd ~/src/nand2tetris-fpga/07_Operating_System/03_Sys_Test && make && cp ../00_HACK/ROM.hack ../../09_More_Fun_to_Go/00_HACK_OS && cd ../../09_More_Fun_to_Go/00_HACK_OS && apio clean && apio sim
$ cd ~/src/nand2tetris-fpga/07_Operating_System/04_Memory_Test && make && cp ../00_HACK/ROM.hack ../../09_More_Fun_to_Go/00_HACK_OS && cd ../../09_More_Fun_to_Go/00_HACK_OS && apio clean && apio sim
$ cd ~/src/nand2tetris-fpga/07_Operating_System/05_Array_Test && make && cp ../00_HACK/ROM.hack ../../09_More_Fun_to_Go/00_HACK_OS && cd ../../09_More_Fun_to_Go/00_HACK_OS && apio clean && apio sim
$ cd ~/src/nand2tetris-fpga/07_Operating_System/06_Math_Test && make && cp ../00_HACK/ROM.hack ../../09_More_Fun_to_Go/00_HACK_OS && cd ../../09_More_Fun_to_Go/00_HACK_OS && apio clean && apio sim

# VGA tests: normal for initial read to be unitialized, SRAM data will carry over during soft reboots & uploads if not overwritten
$ cd ~/src/nand2tetris-fpga/09_More_Fun_to_Go/02_Operating_System/07_String_Test && make && make upload
$ cd ~/src/nand2tetris-fpga/09_More_Fun_to_Go/02_Operating_System/09_Screen_Test && make && make upload
$ cd ~/src/nand2tetris-fpga/09_More_Fun_to_Go/02_Operating_System/10_Output_Test && make && make upload

# Keyboard tests: dedicated power supply required for PS/2 (5v)
$ cd ~/src/nand2tetris-fpga/09_More_Fun_to_Go/02_Operating_System/14_Keyboard_Test && make && make upload
$ cd ~/src/nand2tetris-fpga/09_More_Fun_to_Go/03_Pong && make && make upload
```

## Testing Matrix

- ✅ 01_GPIO_Test // hw only
- ❌ 02_UART_Test // removed
- ✅ 03_Sys_Test / SysTest // hw + sim
- ✅ 04_Memory_Test / MemoryTest // sim only
- ✅ 05_Array_Test / ArrayTest // sim only
- ✅ 06_Math_Test / MathTest // sim only
- ✅ 07_String_Test / StringTest // hw only
- ❌ 08_StdIO_Test // removed
- ✅ 09_Screen_Test / ScreenTest // hw only
- ✅ 10_Output_Test / OutputTest // hw only
- ❌ 11_Touch_Test // removed
- ❌ 12_Tetris // removed
- ❌ 13_Touch // removed  
- ✅ 14_Keyboard_Test // hw only
- ✅ 03_Pong // hw only

## Changelog

// COPILOT: Assume all content in 09_More_Fun_to_Go is new or modified, if not mentioned previously in this doc add it to this section. Unlike other COPILOT directives you should leave this one in place until explicitly told otherwise.

- **HACK.v** – Top-level module rewritten: removed UART/LCD/RTP peripherals, added VGA (640×480), PS/2 keyboard, 8-phase SRAM arbitration with pipelined snapshots, and KBD register at IO8 (address 4104) aliased to nand2tetris standard 0x6000.
- **Memory.v** – Memory map updated: HEAP range (4112–16383) routed to SRAM\_A/SRAM\_D, KBD at nand2tetris standard address 24576, UART/LCD/RTP IO slots marked unassigned.
- **SRAM\_D.v** – New SRAM data controller with phase-aware read/write, combinational InOut bus, and multi-phase output latching (instruction fetch / VGA / data).
- **Clock25\_Reset20.v** – New clock/reset module: generates 25 MHz VGA clock, 6.25 MHz system clock, 8-phase counter, and ~20 µs POR from 100 MHz external clock.
- **00\_HACK/HACK\_tb.v** – Testbench rewritten: added SRAM simulation (64 K + 16 K words), VGA framebuffer data verification, PS/2 keyboard emulator (scancode frame transmitter), SPI flash emulator, and expanded test scenarios.
- **00\_HACK/Include.v** – Updated include list: references new 09 modules (Clock25\_Reset20, HACK, Memory, SRAM\_D) and new IO devices (Keyboard, PS2, VGA).
- **00\_HACK\_OS/HACK\_tb.v** – Added run-mode/OS simulation bench variant with VGA pattern validation against SRAM page 1, PS/2 scancode injection, and explicit pass/fail checks.
- **00\_HACK\_OS/Include.v** – Added dedicated include manifest for the OS simulation target, mirroring the 09 HACK module graph.
- **00\_HACK/iCE40HX1K-EVB.pcf** – Pin constraints updated: removed UART/LCD/RTP pins, added PS2\_CLK and PS2\_DATA pins.
- **01\_IO\_Devices/VGA.v** – New VGA controller: 640×480 @ 60 Hz, 25 MHz pixel clock, 16-bit word-based framebuffer reads, monochrome output.
- **01\_IO\_Devices/PS2.v** – New PS/2 receiver: clock-domain crossing, 11-bit frame deserializer, scancode output.
- **01\_IO\_Devices/Keyboard.v** – New PS/2-to-ASCII converter: scancode-to-keycode lookup, make/break handling, nand2tetris-compatible key codes.
- **02\_Operating\_System/** – Added/revised Jack OS classes and hardware tests for the VGA/Keyboard profile (`Screen`, `Output`, `Keyboard`, `String`, `Sys`, and associated test apps).
