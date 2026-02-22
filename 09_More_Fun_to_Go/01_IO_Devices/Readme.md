# 01 I/O Devices

Implement support for `Keyboard` and `Screen` via `PS/2` and `VGA` connections respectively.

Additional reading:

* https://wiki.osdev.org/PS/2_Keyboard
* https://wiki.osdev.org/Video_Signals_And_Timing

## Credit / License

Out of respect for the source material I have included the MIT license from Michael Schröder's [hack-fpga](https://gitlab.com/x653/hack-fpga) project for the Verilog source code derived from `Keyboard.v`, `PS2.v` & `VGA.v` and some of the `HACK` boilerplate, but most notably not including the `PS/2` and `VGA` test bench emulation which is new. Some minor timing differences to account for the longer pipeline between VRAM and `VGA` in this implementation.

All the other content in `09_More_Fun_to_Go` is my own excepting some nand2tetris Jack APIs and tests in `01_IO_Devices\01_Keyboard` which have carried forward the original nand2tetris copyright where relevant.