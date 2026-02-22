// sram_go_test.asm
// launch straight into run mode
// test bench will prepare the SRAM
// check dout==999 & the 2 go instructions are emitted
// followed by the run program was stored in HACK_tb.v

@GO // 0x1007
M=1 // 0xEFC8