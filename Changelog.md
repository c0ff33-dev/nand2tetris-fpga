# Revision v3.0

* Appendix / end to end install
* wire/yosys updates (smaller bram, bram/rom/sram timings/sync)
* testbench/jack fixes/enhancements + documentation updates
* Split RTP into AR1021 + NS2009 support (+docs, tests, etc)
* UART filter for iceprogduino sketch
* restored original Jack api/copyright (+changelog)
* migrated new graphics funcs to ScreenExt (writeData16 > writeRgbData)
* optional util module
* landscape support (output)
* new/updated datasheets

```
- TODO: complete changelog (cleanup tools, formatting etc)
- TODO: update top level readme
- TODO: jig files
- TODO: diff Jack files (nand2tetris)
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
