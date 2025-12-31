# 07 Operating System

To run serious application like Tetris we need the operating system JACK-OS, written in the high level language JACK. 

For every JACK-OS class we provide a skeleton file, with the signatures of functions and methods. In the dedicated test folder you find implementation details and test classes.

The folder `00_HACK` contains a simulation of HACK similar to the one in `06_IO_Devices/00_HACK` with the following differences:

* uses build in chips from `01_Boolean_Logic` to `03_Sequential_Logic` instead of going down to the nand gate level.
* has 64k words of instruction ROM preloaded with JACK-OS and applications
* is not uploadable to iCE40HX1K-EVB

## Simulation of JACK-OS classes

Use `00_HACK` of `07_Operating_System` to test your JACK-OS classes in simulation.

```
$ cd <test folder>
$ make
$ cd ../00_HACK
$ apio clean
$ apio sim
```

## Run JACK-OS in real hardware on iCE40HX1K-EVB

To test JACK-OS on real hardware iCE40HX1K-EVB use the design of HACK developed in `06_IO_Devices` with the bootloader of `05_GO`. Attach iCE40HX1K-EVB to your computer and run the following commands:

```
$ cd <test folder>
$ make
$ make upload
```

This will compile all classes in the test folder and upload the binary file to SPI flash rom starting at address 64k (0x10000), where the bootloader can find it.

**Attention:** All used classes must be linked to the folder in which you run the compiler. To add the class `<JACK-OS class>.jack` simply make a soft link in the working directory:

Finally you can run Tetris!

# TODO: symlinks (some early dirs specifically have cut-down versions of the supporting libs)
```
sudo ln -sf ../GPIO.jack ./01_GPIO_Test/GPIO.jack
sudo ln -sf ../UART.jack ./02_UART_Test/UART.jack
sudo ln -sf ../GPIO.jack ./03_Sys_Test/GPIO.jack
sudo ln -sf ../Sys.jack ./03_Sys_Test/Sys.jack
sudo ln -sf ../UART.jack ./03_Sys_Test/UART.jack
sudo ln -sf ../Array.jack ./04_Memory_Test/Array.jack
sudo ln -sf ../GPIO.jack ./04_Memory_Test/GPIO.jack
sudo ln -sf ../Memory.jack ./04_Memory_Test/Memory.jack
sudo ln -sf ../Sys.jack ./04_Memory_Test/Sys.jack
sudo ln -sf ../UART.jack ./04_Memory_Test/UART.jack
sudo ln -sf ../Array.jack ./05_Array_Test/Array.jack
sudo ln -sf ../GPIO.jack ./05_Array_Test/GPIO.jack
sudo ln -sf ../Memory.jack ./05_Array_Test/Memory.jack
sudo ln -sf ../Sys.jack ./05_Array_Test/Sys.jack
sudo ln -sf ../UART.jack ./05_Array_Test/UART.jack
sudo ln -sf ../Array.jack ./06_Math_Test/Array.jack
sudo ln -sf ../GPIO.jack ./06_Math_Test/GPIO.jack
sudo ln -sf ../Math.jack ./06_Math_Test/Math.jack
sudo ln -sf ../Memory.jack ./06_Math_Test/Memory.jack
sudo ln -sf ../Sys.jack ./06_Math_Test/Sys.jack
sudo ln -sf ../UART.jack ./06_Math_Test/UART.jack
sudo ln -sf ../Array.jack ./07_String_Test/Array.jack
sudo ln -sf ../GPIO.jack ./07_String_Test/GPIO.jack
sudo ln -sf ../Math.jack ./07_String_Test/Math.jack
sudo ln -sf ../Memory.jack ./07_String_Test/Memory.jack
sudo ln -sf ../StdIO.jack ./07_String_Test/StdIO.jack
sudo ln -sf ../String.jack ./07_String_Test/String.jack
sudo ln -sf ../Sys.jack ./07_String_Test/Sys.jack
sudo ln -sf ../UART.jack ./07_String_Test/UART.jack
sudo ln -sf ../Array.jack ./08_StdIO_Test/Array.jack
sudo ln -sf ../GPIO.jack ./08_StdIO_Test/GPIO.jack
sudo ln -sf ../Math.jack ./08_StdIO_Test/Math.jack
sudo ln -sf ../Memory.jack ./08_StdIO_Test/Memory.jack
sudo ln -sf ../StdIO.jack ./08_StdIO_Test/StdIO.jack
sudo ln -sf ../String.jack ./08_StdIO_Test/String.jack
sudo ln -sf ../Sys.jack ./08_StdIO_Test/Sys.jack
sudo ln -sf ../UART.jack ./08_StdIO_Test/UART.jack
sudo ln -sf ../Array.jack ./09_Screen_Test/Array.jack
sudo ln -sf ../GPIO.jack ./09_Screen_Test/GPIO.jack
sudo ln -sf ../Math.jack ./09_Screen_Test/Math.jack
sudo ln -sf ../Memory.jack ./09_Screen_Test/Memory.jack
sudo ln -sf ../Screen.jack ./09_Screen_Test/Screen.jack
sudo ln -sf ../ScreenExt.jack ./09_Screen_Test/ScreenExt.jack
sudo ln -sf ../StdIO.jack ./09_Screen_Test/StdIO.jack
sudo ln -sf ../String.jack ./09_Screen_Test/String.jack
sudo ln -sf ../Sys.jack ./09_Screen_Test/Sys.jack
sudo ln -sf ../UART.jack ./09_Screen_Test/UART.jack
sudo ln -sf ../Array.jack ./10_Output_Test/Array.jack
sudo ln -sf ../GPIO.jack ./10_Output_Test/GPIO.jack
sudo ln -sf ../Math.jack ./10_Output_Test/Math.jack
sudo ln -sf ../Memory.jack ./10_Output_Test/Memory.jack
sudo ln -sf ../Output.jack ./10_Output_Test/Output.jack
sudo ln -sf ../Screen.jack ./10_Output_Test/Screen.jack
sudo ln -sf ../ScreenExt.jack ./10_Output_Test/ScreenExt.jack
sudo ln -sf ../StdIO.jack ./10_Output_Test/StdIO.jack
sudo ln -sf ../String.jack ./10_Output_Test/String.jack
sudo ln -sf ../Sys.jack ./10_Output_Test/Sys.jack
sudo ln -sf ../UART.jack ./10_Output_Test/UART.jack
sudo ln -sf ../Array.jack ./11_Touch_Test/Array.jack
sudo ln -sf ../GPIO.jack ./11_Touch_Test/GPIO.jack
sudo ln -sf ../Math.jack ./11_Touch_Test/Math.jack
sudo ln -sf ../Memory.jack ./11_Touch_Test/Memory.jack
sudo ln -sf ../Output.jack ./11_Touch_Test/Output.jack
sudo ln -sf ../Screen.jack ./11_Touch_Test/Screen.jack
sudo ln -sf ../ScreenExt.jack ./11_Touch_Test/ScreenExt.jack
sudo ln -sf ../StdIO.jack ./11_Touch_Test/StdIO.jack
sudo ln -sf ../String.jack ./11_Touch_Test/String.jack
sudo ln -sf ../Sys.jack ./11_Touch_Test/Sys.jack
sudo ln -sf ../Touch.jack ./11_Touch_Test/Touch.jack
sudo ln -sf ../UART.jack ./11_Touch_Test/UART.jack
sudo ln -sf ../Util.jack ./11_Touch_Test/Util.jack
sudo ln -sf ../Array.jack ./12_Tetris/Array.jack
sudo ln -sf ../GPIO.jack ./12_Tetris/GPIO.jack
sudo ln -sf ../Math.jack ./12_Tetris/Math.jack
sudo ln -sf ../Memory.jack ./12_Tetris/Memory.jack
sudo ln -sf ../Output.jack ./12_Tetris/Output.jack
sudo ln -sf ../Screen.jack ./12_Tetris/Screen.jack
sudo ln -sf ../ScreenExt.jack ./12_Tetris/ScreenExt.jack
sudo ln -sf ../StdIO.jack ./12_Tetris/StdIO.jack
sudo ln -sf ../String.jack ./12_Tetris/String.jack
sudo ln -sf ../Sys.jack ./12_Tetris/Sys.jack
sudo ln -sf ../Touch.jack ./12_Tetris/Touch.jack
sudo ln -sf ../UART.jack ./12_Tetris/UART.jack
sudo ln -sf ../Util.jack ./12_Tetris/Util.jack
```

```
sudo ln -sf ./13_Touch/Touch_AR1021.jack ./Touch.jack
sudo ln -sf ./13_Touch/Touch_NS2009.jack ./Touch.jack
```