# 09 More Fun to Go!

In this section we will pivot back to a more classic Hack implementation using the `Keyboard` and `Screen` interfaces for I/O as described in the original nand2tetris spec. This will involve implementing `PS/2` and `VGA` controllers respectively to connect to a compatible keyboard and monitor. If still using the original `Olimexino-32u4` + `iCE40HX1K-EVB` setup it can be expanded with `iCE40-IO` for `PS/2` and `VGA` ports and that will be the assumed setup in this implementation. 

Some changes will be needed to support writing pixel data to VRAM which was previously off loaded to `MOD-LCD2.8RTP` in the prior implementation, this board and the corresponding `SPI`/`LCD`/`RTP` controllers/drivers will not be used moving forward.

The `GateMateA1-EVB` board by Olimex could also be used here as seen in Michael Schröder's [hack-fpga](https://gitlab.com/x653/hack-fpga) project which is roughly comparable in cost to the sum of the parts described above but with far more FPGA resources.  

These other/similar projects may be of interest for research purposes or board alternatives:

* https://github.com/giuseros/nand2tetris
* https://github.com/gunnerson/hack-fpga

## Major Changes

- `SRAM_A/D` now supports multiple updates per cycle: most updates are performed during `clk negedge` and expressed to CPU when it updates in `clk posedge` as normal.

## Memory Map

// COPILOT: Complete this section with notes from Memory.v

## Upload Bitstream & Software

Note: Don't conflate the flash memory layout/offsets with the `SRAM` layout/offsets which also happens to use 64KB blocks. For flash the first page (`0x0000-0xFFFF`) is reserved for FPGA configuration data including the first program (`ROM.hack`) in the 512 byte bootloader enclave (`ROM.v`), though in practice this program could also be any small test program. The 2nd page starting at offset `0x10000` contains the application code which the bootloader will copy into the first page (`0x0000-0xFFFF`) of `SRAM`.

```
# build bootloader and copy into revised HACK directory
cd ~/src/nand2tetris-fpga/06_IO_Devices/05_GO && make && cp ../00_HACK/ROM.hack ../../09_More_Fun_to_Go/00_HACK && cd ../../09_More_Fun_to_Go/00_HACK && apio clean && apio upload

# Jack application code can be flashed straight to offset 0x10000 as before
$ cd ~/src/nand2tetris-fpga/04_Machine_Language && make upload # leds.asm
cd ~/src/nand2tetris-fpga/07_Operating_System/01_GPIO_Test && make && make upload
```

## Changelog

// COPILOT: Assume all content in 09_More_Fun_to_Go is new or modified, if not mentioned previously in this doc add it to this section. Unlike other COPILOT directives you should leave this one in place until explicitly told otherwise.