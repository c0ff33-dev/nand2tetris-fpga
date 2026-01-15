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
$ git clone git@gitlab.com:gcpd88/nand2tetris-fpga.git # requires ssh config
$ git clone git@github.com:c0ff33-dev/nand2tetris.git
$ git clone https://github.com/OLIMEX/iCE40HX1K-EVB.git
$ git clone https://github.com/OLIMEX/MOD-LCD2.8RTP.git
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
$ sudo ln -s ~/bin/arduino-cli /usr/local/bin/arduino-cli
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

### Update hardware

```
$ source ~/src/nand2tetris-fpga/.venv/bin/activate
$ cd ~/src/nand2tetris-fpga/06_IO_Devices/05_GO && make && cd ../00_HACK && apio clean && apio upload
```

### Upload program

```
$ cd ~/src/nand2tetris-fpga/07_Operating_System/12_Tetris && make && make upload
```