# Tools

This folder contains the toolchain for `HACK`/Jack development.

## Assembler

Assembler translates `HACK` assembly files to machine code. Outputs the machine code to `filename.hack`.

`usage: ./Assembler/assembler.pyc [filename.asm]`

## JackCompiler

Compiles Jack classes (single file or all `*.jack` files in directory) to VM code via a 3-step pipeline: tokenizer → analyzer → compiler.

```
usage: ./JackCompiler/tokenizer.pyc [filename.jack] or [dir]
       ./JackCompiler/analyzer.pyc [filename.jack] or [dir]
       ./JackCompiler/compiler.pyc [filename.jack] or [dir]
```

## VMTranslator

Translates VM code (single file or all files with ending `*.vm` in directory) to assembly.

`usage: ./VMTranslator/translator.pyc [dir]`

## AsciiToBin.py

Translates `.hack` files to binary files that can be uploaded with `iceprogduino`.

`usage: ./AsciiToBin.py [filename.hack]`

## iceprogduino

`iceprogduino` is the programmer to upload bitstream files to iCE40 boards via `olimexino-32u4` (an Arduino-like board).

For this you first have to upload firmware to `olimexino-32u4`.

Connect:

* `iCE40HX18K-EVB` to `olimexino-32u4` (over UEXT).
* `olimexino-32u4` (with installed firmware) to PC over USB.
