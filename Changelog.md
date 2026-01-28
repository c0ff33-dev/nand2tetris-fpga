# Revision v3.0 (Fork)

### Base content changes

* Added many Verilog & `apio.ini` fixes for modern yosys.
* Added many test enhancements & documentation updates.
* Added syncronized read/write for BRAM/ROM/SRAM & tighter timing for `SPI` (2x faster).
  * Currently run mode for SRAM is still unsyncronized.
* Split `RTP` into `AR1021` + `NS2009` implementations.
  * Added documentation & test bench for the latter.
* Added logic to the `iceprogduino` sketch to filter UART traffic before `CDONE` signal is received.
* Restored functions that modified nand2tetris API signatures and nand2tetris copyright to Jack files.
* Split graphics API where original nand2tetris API is preserved in `Screen` while new functions were added to `ScreenExt`.
  * Renamed `writeData16()` to `writeRgbData()` in ScreenExt.
* Added new/updated datasheets.
* Added 3D printer files for development jig.
* Added `Appendix.md` with cliff notes for development environment setup.

### Implementation changes

* Added `Util` module for homing miscellaneous helper functions.
* Added support for landscape orientation in `Output`.

# Revision v2.0 (Pre-Fork)

## Update 04.08.2023

### Update tools to Python3.11

* `tools/Assembler/assembler.pyc`
* `tools/Jack/JackCompiler.pyc`
* `tools/Jack/VMTranslator.pyc`

### Fixes

* Corrected diagrams: `leds.png`, `mult.png`.

## Update 18.10.2022

### Fixes

* `Hack/CPU.v`: Replace `loadM` with `writeM`.
* Update diagrams.

### Update tools to Python3.10

* `tools/Assembler/assembler.pyc`
* `tools/Jack/JackCompiler.pyc`
* `tools/Jack/VMTranslator.pyc`

### Update Jack OS

* `Jack/UART.jack`: replace `init()` with `init(int addr)`

### Weird behaviour of iCE40HX8K-EVB

* `Hack/RAM.v`: replace `always @(negedge clk)` to `always @(posedge clk)`
* `Hack/DFF.v`: replace `always @(negedge clk)` to `always @(posedge clk)`
* `Hack/Clock.v`: 25 MHz

### iceprog: programmer.ino

* Set default to `bridge` mode (green LED on).

### Consistency

* `Hack/Reset.v`

### Boot from SPI

* `04_Hack-FLASH`
