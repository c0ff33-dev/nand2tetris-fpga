# 09 More Fun to Go!

In this section we will pivot back to a more classic Hack implementation using the `Keyboard` and `Screen` interfaces for I/O as described in the original nand2tetris spec. This will involve implementing `PS/2` and `VGA` controllers respectively to connect to a compatible keyboard and monitor. If still using the original `Olimexino-32u4` + `iCE40HX1K-EVB` setup it can be expanded with `iCE40-IO` for `PS/2` and `VGA` ports and that will be the assumed setup in this implementation. 

Some changes will be needed to support writing pixel data to VRAM which was previously off loaded to `MOD-LCD2.8RTP` in the prior implementation, this board and the corresponding `SPI`/`LCD`/`RTP` controllers/drivers will not be used moving forward.

The `GateMateA1-EVB` board by Olimex could also be used here as seen in Michael Schröder's [hack-fpga](https://gitlab.com/x653/hack-fpga) project which is roughly comparable in cost to the sum of the parts described above but with far more FPGA resources.  

These other/similar projects may be of interest for research purposes or board alternatives:

* https://github.com/giuseros/nand2tetris
* https://github.com/gunnerson/hack-fpga

## Upload Bitstream & Software

```
cd ~/src/nand2tetris-fpga/06_IO_Devices/05_GO && make && cp ../00_HACK/ROM.hack ../../09_More_Fun_to_Go/00_Hack && ../../09_More_Fun_to_Go/00_Hack && apio clean && apio upload
cd ~/src/nand2tetris-fpga/04_Machine_Language && make upload # TODO: update me
```