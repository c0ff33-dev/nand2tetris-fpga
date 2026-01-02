## Memory.jack

This library provides two services: direct access to the computer's main memory (RAM), and allocation and recycling of memory blocks. The Hack RAM consists of  3584 words, each holding a 16 bit binary number.

Don't be afraid of the limited memory size of "only" 3584 words. Let the heap start at address 1024 with `do Memory.init()` in the `Sys.init()`. This will leave 768 words of stack, which is surely enough to run Tetris.

| addr      | segment                       |
| --------- | ----------------------------- |
| 0-15      | R0-R15 (SP,LCL,ARG,THIS,THAT) |
| 16-255    | static                        |
| 256-1023  | stack                         |
| 1024-3583 | heap                          |
| 4096-4111 | IO-devices                    |

***

### Project

* Implement `Memory.jack`

**Attention:** Don't init the other Jack libraries in `Sys.init()` beyond what it is included in this folder (`GPIO`, `Memory`, `Sys`, `UART`).

* Test in simulation:
  
  ```
  $ cd 04_Memory_Test
  $ make
  $ cd ../00_HACK
  $ apio clean
  $ apio sim
  ```

* Check the content of special function register DEBUG0-DEBUG4.
  
  ![](memory.png)
