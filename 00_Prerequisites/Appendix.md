# Appendix

Cliff notes for environment setup/installation.

### Notes

* `iceprogduino` is targeting POSIX dependencies not available on Windows.
* `winiceprogduino` does not support writing to offsets.
* `usbipd` is needed for WSL as the COM passthrough doesn't support the necessary IOCTLs.

## Install dependencies

### Python 3.11/12

```sh
$ sudo apt update
$ sudo apt install software-properties-common
$ sudo add-apt-repository ppa:deadsnakes/ppa
$ sudo apt install python3.11 python3.11-venv python3.12 python3.12-venv
```

### git and repos

```sh
$ sudo apt install git
$ mkdir src && cd src
$ git clone git@github.com:c0ff33-dev/nand2tetris-fpga.git
```

### Install apio + dependencies

```sh
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

```sh
$ cd ../iCE40HX1K-EVB/programmer/iceprogduino
$ sudo apt install build-essential unzip
$ make
$ sudo make install
```

### Arduino dependencies

```sh
$ cd ~ && curl -fsSL https://raw.githubusercontent.com/arduino/arduino-cli/master/install.sh | sh
$ sudo ln -sf ~/bin/arduino-cli /usr/local/bin/arduino-cli
$ arduino-cli core install arduino:avr
$ arduino-cli lib install "Adafruit GFX Library@1.2.3"
$ wget https://github.com/Marzogh/SPIMemory/archive/refs/tags/v2.2.0.zip -O SPIMemory-2.2.0.zip
$ unzip SPIMemory-2.2.0.zip -d ~/Arduino/libraries/
```

### WSL: Install usbipd to bridge usb

```sh
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

```sh
$ sudo chmod a+rw /dev/ttyACM0
```

### Flash the programmer

If having trouble with disconnects here in WSL may need to use a full VM with USB passthrough:

```sh
$ arduino-cli compile --upload -p /dev/ttyACM0 --fqbn arduino:avr:leonardo "/home/veris/src/nand2tetris-fpga/tools/olimexino-32u4/iceprog"
$ arduino-cli compile --upload -p /dev/ttyACM0 --fqbn arduino:avr:leonardo /home/veris/src/MOD-LCD2.8RTP/SOFTWARE/Arduino/graphicstest_olimex_NS2009
```

### Upload test program

```sh
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

```sh
$ apio clean && apio build --verbose-pnr > log.txt
$ grep -ie "ICESTORM_LC:  " log.txt
$ grep -ie "frequency" log.txt
```

## Testing & Validation

## Update compiler/translator/assembler binaries

```sh
cd ~/src/nand2tetris/interpreter && rm ./__pycache__/*.pyc && python3.12 -m compileall .
cp ~/src/nand2tetris/interpreter/__pycache__/tokenizer.cpython-312.pyc ~/src/nand2tetris-fpga/tools/JackCompiler/tokenizer.pyc
cp ~/src/nand2tetris/interpreter/__pycache__/analyzer.cpython-312.pyc ~/src/nand2tetris-fpga/tools/JackCompiler/analyzer.pyc
cp ~/src/nand2tetris/interpreter/__pycache__/compiler.cpython-312.pyc ~/src/nand2tetris-fpga/tools/JackCompiler/compiler.pyc
cp ~/src/nand2tetris/interpreter/__pycache__/translator.cpython-312.pyc ~/src/nand2tetris-fpga/tools/VMTranslator/translator.pyc
cp ~/src/nand2tetris/interpreter/__pycache__/assembler.cpython-312.pyc ~/src/nand2tetris-fpga/tools/Assembler/assembler.pyc
cd ~/src/nand2tetris-fpga
```

### Original HACK

Flash the "UART" sketch (from VM):

```sh
cd ~/src/nand2tetris-fpga/tools/olimexino-32u4/iceprog2 && sudo ln -sf ../src/iceprog_UART.ino iceprog2.ino
arduino-cli compile --upload -p /dev/ttyACM0 --fqbn arduino:avr:leonardo "/home/<user>/src/nand2tetris-fpga/tools/olimexino-32u4/iceprog2"
```

If using WSL, reattach the port:

```sh
usbipd attach --wsl --busid <busid>
```

Upload bootloader + bitstream:

```sh
$ source ~/src/nand2tetris-fpga/.venv/bin/activate
$ cd ~/src/nand2tetris-fpga/06_IO_Devices/05_GO && make && cd ../00_HACK && apio clean && apio upload
```

Jack tests:

```sh
$ cd ~/src/nand2tetris-fpga/07_Operating_System/01_GPIO_Test && make clean && make && cd ../00_HACK && apio clean && apio sim
$ cd ~/src/nand2tetris-fpga/07_Operating_System/01_GPIO_Test && make clean && make && make upload

# swap RTP for UART in 06_IO_Devices\HACK.v (LC budget) & reflash the hardware bitstream
# ensure olimexino is in bridge mode (green) when transmitting & regular (yellow) when programming
# for LEDs near USB port on olimexino, yellow = rx (from PC) & green = tx (from FPGA)
$ cd ~/src/nand2tetris-fpga/07_Operating_System/02_UART_Test && make clean && make && cd ../00_HACK && apio clean && apio sim
$ cd ~/src/nand2tetris-fpga/07_Operating_System/02_UART_Test && make clean && make && make upload && tio /dev/ttyACM0
$ cd ~/src/nand2tetris-fpga/07_Operating_System/03_Sys_Test && make clean && make && make upload

$ cd ~/src/nand2tetris-fpga/07_Operating_System/04_Memory_Test && make clean && make && cd ../00_HACK && apio clean && apio sim
$ cd ~/src/nand2tetris-fpga/07_Operating_System/05_Array_Test && make clean && make && cd ../00_HACK && apio clean && apio sim
$ cd ~/src/nand2tetris-fpga/07_Operating_System/06_Math_Test && make clean && make && cd ../00_HACK && apio clean && apio sim
$ cd ~/src/nand2tetris-fpga/07_Operating_System/07_String_Test && make clean && make && cd ../00_HACK && apio clean && apio sim

# ctrl+t, l to clear tio output & reset FPGA (not olimexino)
$ cd ~/src/nand2tetris-fpga/07_Operating_System/07_String_Test && make clean && make && make upload && tio /dev/ttyACM0
$ cd ~/src/nand2tetris-fpga/07_Operating_System/08_StdIO_Test && make clean && make && make upload && tio /dev/ttyACM0
$ cd ~/src/nand2tetris-fpga/07_Operating_System/09_Screen_Test && make clean && make && cd ../00_HACK && apio clean && apio sim
$ cd ~/src/nand2tetris-fpga/07_Operating_System/09_Screen_Test && make clean && make && make upload
$ cd ~/src/nand2tetris-fpga/07_Operating_System/10_Output_Test && make clean && make && make upload

# swap UART for RTP in 06_IO_Devices\HACK.v & re-flash the hardware bitstream!

# sim only available for AR1021 emulation only: see 06_IO_Devices/Readme.md for full list of refs
# if disabling Screen/ScreenExt/Output.init() for speed need to also disable the Output.print*() calls in test!
# $ cd ~/src/nand2tetris-fpga/07_Operating_System/11_Touch_Test && make clean && make && cd ../00_HACK && apio clean && apio sim

$ cd ~/src/nand2tetris-fpga/07_Operating_System/11_Touch_Test && make clean && make && make upload
$ cd ~/src/nand2tetris-fpga/07_Operating_System/12_Tetris && make clean && make && make upload
```

### Classic HACK

Flash the "NoUART" sketch (from VM):

```sh
cd ~/src/nand2tetris-fpga/tools/olimexino-32u4/iceprog2 && sudo ln -sf ../src/iceprog_NoUART.ino iceprog2.ino
arduino-cli compile --upload -p /dev/ttyACM0 --fqbn arduino:avr:leonardo "/home/<user>/src/nand2tetris-fpga/tools/olimexino-32u4/iceprog2"
```

If using WSL, reattach the port:

```sh
usbipd attach --wsl --busid <busid>
```

Upload bootloader + bitstream:

```sh
$ source ~/src/nand2tetris-fpga/.venv/bin/activate
$ cd ~/src/nand2tetris-fpga/06_IO_Devices/05_GO && make && cp ../00_HACK/ROM.hack ../../09_More_Fun_to_Go/00_HACK && cd ../../09_More_Fun_to_Go/00_HACK && apio clean && apio upload
```

Jack tests:

```sh
# Application code can be flashed straight to offset 0x10000 as before
# 07_Operating_System tests use original Sys.jack so runs at 1/4 timing for Sys.wait() calls (i.e. slower)
$ cd ~/src/nand2tetris-fpga/07_Operating_System/01_GPIO_Test && make clean && make && make upload
$ cd ~/src/nand2tetris-fpga/07_Operating_System/03_Sys_Test && make clean && make && make upload

# HACK_OS sims: can uncomment additional debug registers in HACK where necessary
# OS tests are too large to be sim'd without using a larger/non-uploadable ROM part (i.e. as done in original 07_Operating_System)
# some need a longer simulation time up to ~1.25 million ticks to complete on the slower CPU timing for the full program
$ cd ~/src/nand2tetris-fpga/07_Operating_System/04_Memory_Test && make clean && make && cp ../00_HACK/ROM.hack ../../09_More_Fun_to_Go/00_HACK_OS && cd ../../09_More_Fun_to_Go/00_HACK_OS && apio clean && apio sim
$ cd ~/src/nand2tetris-fpga/07_Operating_System/05_Array_Test && make clean && make && cp ../00_HACK/ROM.hack ../../09_More_Fun_to_Go/00_HACK_OS && cd ../../09_More_Fun_to_Go/00_HACK_OS && apio clean && apio sim
$ cd ~/src/nand2tetris-fpga/07_Operating_System/06_Math_Test && make clean && make && cp ../00_HACK/ROM.hack ../../09_More_Fun_to_Go/00_HACK_OS && cd ../../09_More_Fun_to_Go/00_HACK_OS && apio clean && apio sim

# VGA tests
$ cd ~/src/nand2tetris-fpga/09_More_Fun_to_Go/02_Operating_System/07_String_Test && make clean && make && make upload
$ cd ~/src/nand2tetris-fpga/09_More_Fun_to_Go/02_Operating_System/09_Screen_Test && make clean && make && make upload
$ cd ~/src/nand2tetris-fpga/09_More_Fun_to_Go/02_Operating_System/10_Output_Test && make clean && make && make upload

# Keyboard tests: dedicated power supply required for PS/2 (5v)
$ cd ~/src/nand2tetris-fpga/09_More_Fun_to_Go/02_Operating_System/14_Keyboard_Test && make clean && make && make upload
$ cd ~/src/nand2tetris-fpga/09_More_Fun_to_Go/03_Pong && make clean && make && make upload
```