# Appendix

Cliff notes for environment setup/installation.

### Notes

* `iceprogduino` is targeting POSIX dependencies not available on Windows.
* `winiceprogduino` does not support writing to offsets.
* `usbipd` is needed for WSL as the COM passthrough doesn't support the necessary IOCTLs.

## Install dependencies

### Python 3.11

```
$ sudo apt update
$ sudo apt install software-properties-common
$ sudo add-apt-repository ppa:deadsnakes/ppa
$ sudo apt install python3.11 python3.11-venv
```

### git and repos

```
$ sudo apt install git
$ mkdir src && cd src
$ git clone git@github.com:c0ff33-dev/nand2tetris-fpga.git
```

### Install apio + dependencies

```
$ cd nand2tetris-fpga
$ python3.11 -m venv .venv
$ source .venv/bin/activate
$ python -m pip install apio
$ apio install oss-cad-suite
$ apio install examples

$ sudo apt install gtkwave
$ sudo apt install tio # serial client
$ sudo apt install xvfb # not needed on wsl
```

### Build + install the programmer

```
$ cd ../iCE40HX1K-EVB/programmer/iceprogduino
$ sudo apt install build-essential unzip
$ make
$ sudo make install
```

### Arduino dependencies

```
$ cd ~ && curl -fsSL https://raw.githubusercontent.com/arduino/arduino-cli/master/install.sh | sh
$ sudo ln -sf ~/bin/arduino-cli /usr/local/bin/arduino-cli
$ arduino-cli core install arduino:avr
$ arduino-cli lib install "Adafruit GFX Library@1.2.3"
$ wget https://github.com/Marzogh/SPIMemory/archive/refs/tags/v2.2.0.zip -O SPIMemory-2.2.0.zip
$ unzip SPIMemory-2.2.0.zip -d ~/Arduino/libraries/
```

### WSL: Install usbipd to bridge usb

```
$ winget install --interactive --exact dorssel.usbipd-win # restart shell
$ usbipd list
$ usbipd bind --busid 1-3 # USB Serial Device (COM3)
$ usbipd attach --wsl --busid 1-3
$ lsusb # wsl: Arduino SA Leonardo (CDC ACM, HID)
$ usbipd detach --wsl --busid 1-3
$ usbipd unbind --all
```

## Prepare board & development environment

### Enable write perms on the serial port

```
$ sudo chmod a+rw /dev/ttyACM0
```

### Flash the programmer

If having trouble with disconnects here in WSL may need to use a full VM with USB passthrough:

```
$ arduino-cli compile --upload -p /dev/ttyACM0 --fqbn arduino:avr:leonardo "/home/veris/src/nand2tetris-fpga/tools/olimexino-32u4 firmware/iceprog"
$ arduino-cli compile --upload -p /dev/ttyACM0 --fqbn arduino:avr:leonardo /home/veris/src/MOD-LCD2.8RTP/SOFTWARE/Arduino/graphicstest_olimex_NS2009
```

### Upload test program

```
$ cd ~/src/nand2tetris-fpga
$ apio examples -d iCE40-HX1K-EVB/leds
$ cd iCE40-HX1K-EVB/leds
$ apio sim
$ apio build
$ apio upload
```

## Miscellaneous

### Useful VSC extensions

```
mshr-h.veriloghdl
throvn.nand2tetris
roman-lukash.nand2tetris-jack-language-server
```

### Check LC utilization & timing

```
$ apio clean && apio build --verbose-pnr > log.txt
$ grep -ie "ICESTORM_LC:  " log.txt
$ grep -ie "frequency" log.txt
```

## Testing & Validation

### Original HACK

Upload bootloader + bitstream:

```
$ source ~/src/nand2tetris-fpga/.venv/bin/activate
$ cd ~/src/nand2tetris-fpga/06_IO_Devices/05_GO && make && cd ../00_HACK && apio clean && apio upload
```

Jack tests:

```
$ cd ~/src/nand2tetris-fpga/07_Operating_System/01_GPIO_Test && make && cd ../00_HACK && apio clean && apio sim
$ cd ~/src/nand2tetris-fpga/07_Operating_System/01_GPIO_Test && make && make upload
$ cd ~/src/nand2tetris-fpga/07_Operating_System/02_UART_Test && make && cd ../00_HACK && apio clean && apio sim
$ cd ~/src/nand2tetris-fpga/07_Operating_System/02_UART_Test && make && make upload && tio /dev/ttyACM0
$ cd ~/src/nand2tetris-fpga/07_Operating_System/03_Sys_Test && make && cd ../00_HACK && apio clean && apio sim
$ cd ~/src/nand2tetris-fpga/07_Operating_System/03_Sys_Test && make && make upload
$ cd ~/src/nand2tetris-fpga/07_Operating_System/04_Memory_Test && make && cd ../00_HACK && apio clean && apio sim
$ cd ~/src/nand2tetris-fpga/07_Operating_System/05_Array_Test && make && cd ../00_HACK && apio clean && apio sim
$ cd ~/src/nand2tetris-fpga/07_Operating_System/06_Math_Test && make && cd ../00_HACK && apio clean && apio sim
$ cd ~/src/nand2tetris-fpga/07_Operating_System/07_String_Test && make && cd ../00_HACK && apio clean && apio sim
$ cd ~/src/nand2tetris-fpga/07_Operating_System/07_String_Test && make && make upload && tio /dev/ttyACM0
$ cd ~/src/nand2tetris-fpga/07_Operating_System/08_StdIO_Test && make && make upload && tio /dev/ttyACM0
$ cd ~/src/nand2tetris-fpga/07_Operating_System/09_Screen_Test && make && cd ../00_HACK && apio clean && apio sim
$ cd ~/src/nand2tetris-fpga/07_Operating_System/09_Screen_Test && make && make upload
$ cd ~/src/nand2tetris-fpga/07_Operating_System/10_Output_Test && make && make upload
$ cd ~/src/nand2tetris-fpga/07_Operating_System/11_Touch_Test && make && cd ../00_HACK && apio clean && apio sim
$ cd ~/src/nand2tetris-fpga/07_Operating_System/11_Touch_Test && make && make upload
$ cd ~/src/nand2tetris-fpga/07_Operating_System/12_Tetris && make && make upload
```

### Classic HACK

Upload bootloader + bitstream:

```
$ source ~/src/nand2tetris-fpga/.venv/bin/activate
$ cd ~/src/nand2tetris-fpga/06_IO_Devices/05_GO && make && cp ../00_HACK/ROM.hack ../../09_More_Fun_to_Go/00_HACK && cd ../../09_More_Fun_to_Go/00_HACK && apio clean && apio upload
```

Jack tests:

```
# Application code can be flashed straight to offset 0x10000 as before
$ cd ~/src/nand2tetris-fpga/07_Operating_System/01_GPIO_Test && make && make upload
$ cd ~/src/nand2tetris-fpga/07_Operating_System/03_Sys_Test && make && make upload

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
