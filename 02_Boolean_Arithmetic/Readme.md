# 02 Arithmetic Logic

Proceed and implement the chips `HalfAdder`, `FullAdder`, `Add16`, `Inc16` and `ALU`.

Keep in mind the following remarks:

* In order to use the chips implemented in project `01_Boolean_Logic`, they must be listed in the file `Include.v`, which can be found in every sub-folder.

* You can use a `Buffer` to split the signal wires. e.g. `ng` signal of ALU can be derived from `out[15]`.

* Clear cache every time you edit and change your implementation in the Verilog file `<chipname>.v`.

* Test your chip implementation with:
  
  ```
  $ cd <XX_chip>
  $ apio clean
  $ apio sim
  ```

* The chip `HalfAdder` can be uploaded to `iCE40HX1K-EVB` and tested using `BUT1/2` and `LED1/2`. Keep in mind that due to pull up resistors at the buttons the signals appear inverted:
  
  | Pin      | Function                                            |
  | -------- | --------------------------------------------------- |
  | `LED1/2` | =0 `LED` is off, =1 `LED` is on                     |
  | `BUT1/2` | =0 button is pressed down, =1 button is released up |