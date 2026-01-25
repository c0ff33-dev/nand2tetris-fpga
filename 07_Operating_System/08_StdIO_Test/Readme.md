## StdIO.jack

A library of functions for text based input and output over `UART`.

***

### Project

* Implement `StdIO.jack`.

  **Attention:** Don't init the other Jack libraries in `Sys.init()` beyond what is included in this folder (`GPIO`, `UART`, `Memory`, `Math`).

* Run `StdIO_Test` on real hardware on `iCE40HX1K-EVB` using a terminal program connected to `UART`.

* Compare your terminal output with:
  
  ```
  StdIO test:
  Please press the number '3': 
  ok
  readLine test:
  (Verify echo and usage of 'backspace')
  Please type 'JACK' and press enter: JACK
  ok
  readInt test:
  Please type '-32123' and press enter: -32123
  ok
  
  Test completed successfully
  ```