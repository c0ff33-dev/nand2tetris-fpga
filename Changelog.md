# TODO: Summarize changes

# Revision v3.0

* Appendix / end to end install
* wire/yosys updates (smaller bram, bram/rom/sram timings/sync)
* testbench/jack fixes/enhancements + documentation updates
* Split RTP into AR1021 + NS2009 support (+docs, tests, etc)
* UART filter for iceprogduino sketch
* restored original Jack api/copyright (+changelog)
* new funcs in ScreenExt
* landscape support (output)

```
- TODO: continue PR review from Screen.jack

- TODO: your code here - various Sys.jack? Touch*.jack? 07_OS/*.jack
- TODO: change unused new functions back to private functions (+nand2tetris)
  - drawChar
- TODO: replace tab with spaces (repo wide)
```

***

Pre-fork changelog.

# Revision v2.0

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
