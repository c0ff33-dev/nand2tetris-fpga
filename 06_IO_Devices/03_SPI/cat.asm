// cat.asm
//
// load spi flash rom starting at address 0x040000 and write the
// data to UART_TX
//
// Put your code here:

// TODO: send wake command (0xAB), wait 3μs
// TODO: send read data command @ 0x40000 [256k] (0x03, 0x04, 0x00, 0x00) x 4 consecutive bytes
// TODO: send sleep command (0xB9)

// TODO: pre-flash the data to read on W25Q16BV
// echo SPI! > spi.txt
// iceprogduino -o 256k -w spi.txt