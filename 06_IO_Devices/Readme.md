# 06 IO Devices

Build the following special function register to connect HACK to I/O devices: `UART_TX`, `UART_RX`, `SPI`, `SRAM`, `GO`, `LCD` and `RTP`. For every special function register we provide a folder with implementation details and a testbench. The special function register must be memory mapped, so HACK can read/write data from/to the IO device.

| address | I/O dev   | function                                           |
| ------- | --------- | -------------------------------------------------- |
| 4096    | LED       | 0 = led off, 1 = led on                            |
| 4097    | BUT       | 0 = button pressed "down", 1 = button released     |
| 4098    | UART_TX   | transmit byte to UART with 115200 baud 8N1         |
| 4099    | UART_RX   | receive byte from UART with 115200 baud 8N1        |
| 4100    | SPI       | read/write spi flash memory chip                   |
| 4101    | SRAM_A    | address of external SRAM chip                      |
| 4102    | SRAM_D    | read/write data from/to external SRAM chip         |
| 4103    | GO        | start execution of instructions from external SRAM |
| 4104    | LCD8      | write 8 bit command/data to LCD screen              |
| 4105    | LCD16     | write 16 bit data to LCD screen                     |
| 4106    | RTP       | read/write byte from/to resistive touch panel      |
| 4107    | DEBUG0    | used for debugging                                 |
| 4108    | DEBUG1    | used for debugging                                 |
| 4109    | DEBUG2    | used for debugging                                 |
| 4110    | DEBUG3    | used for debugging                                 |
| 4111    | DEBUG4    | used for debugging                                 |

For every special function register we will need the appropriate software to talk to the device. The simpler device drivers (UART, SPI, SRAM and GO) can be implemented in assembly. After completing the devices UART, SPI, SRAM and GO we will be able to fill the SRAM chip with up to 64K words (16 bits) of HACK code. This will enable us to run Jack OS and applications on HACK. The more sophisticated device drivers for LCD and RTP will be implemented in Jack.

### Proposed implementation

![](00_HACK/HACK.png)

***

### Project

+ Copy `HACK.v` from `05_Computer_Architecture` into `06_IO_Devices` and add one IO device at time at the designated memory mapped address. Implement the corresponding special function register and run the test bench.
  
  ```
  $ cd 0X_<device>
  $ apio clean
  $ apio sim
  ```

+ Implement the designated assembler program, install the binary into `00_HACK` and run the testbench:
  
  ```
  $ cd 0X_<device>
  $ make
  $ cd ../00_HACK
  $ apio clean
  $ apio sim
  ```

* Run `HACK` in real hardware on `iCE40HX1K-EVB` with the real device attached:
  
  ```
  $ cd 00_HACK
  $ apio clean
  $ apio upload
  ```

* Check if attached IO device is working according to the uploaded software.

### Resistive Touch Panel (RTP)

Later hardware revisions (Rev C onwards) of `MOD-LCD2.8RTP` may ship with different ICs for the `RTP` controller and while the overall functionality is similar the implementation is a major point of divergence. The board is currently printed to support either the `NS2009` or the `AR1021` chip. In the image below the `NS2009` chip has been installed in the `U2` slot. In other variations `AR1021` may be installed in the `U1` slot instead and earlier revisions will not include the `U2` slot at all.

![](RTP.png)

Once you have identified which chip is installed comment/uncomment the relevant set from each pair.

Create symlinks to instantiate the relevant template:

```
sudo ln -s RTP_AR1021.v RTP.v
sudo ln -s 07A_RTP_AR1021 07_RTP

sudo ln -s RTP_NS2009.v RTP.v
sudo ln -s 07B_RTP_NS2009 07_RTP
```

Update `06_IO_Devices/00_HACK/HACK_tb.v` refs:

```
	// AR1021 wires
	// wire RTP_SDI;
	// wire RTP_SDO;
	// wire RTP_SCK;

	// NS2009 wires
	wire RTP_SDA;
	wire RTP_SCL;

  // ...

  // AR1021 wires
  // .RTP_SDI(RTP_SDI),   // RTP serial data in
  // .RTP_SDO(RTP_SDO),   // RTP serial data out in
  // .RTP_SCK(RTP_SCK)    // RTP serial clock

  // NS2009 wires
  .RTP_SDA(RTP_SDA),      // RTP data line
  .RTP_SCL(RTP_SCL)       // RTP serial clock
```

Update `06_IO_Devices/00_HACK/iCE40HX1K-EVB.pcf` refs:

```
# AR1021 pins
# set_io RTP_SDI 19		# PIO3_8B connected to pin 29 of GPIO1, pin 4 TXD (SDO) on MOD-LCD2.8RTP
# set_io RTP_SDO 20		# PIO3_10A connected to pin 31 of GPIO1, pin 6 SDA (SDI) on MOD-LCD2.8RTP
# set_io RTP_SCK 21		# PIO3_10B connected to pin 33 of GPIO1, pin 5 SCL (SCK) on MOD-LCD2.8RTP

# NS2009 pins
set_io RTP_SDA 20		# PIO3_10A connected to pin 31 of GPIO1, pin 6 SDA on MOD-LCD2.8RTP
set_io RTP_SCL 21		# PIO3_10B connected to pin 33 of GPIO1, pin 5 SCL on MOD-LCD2.8RTP
```