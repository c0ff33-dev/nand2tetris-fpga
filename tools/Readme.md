# Tools

This folder contains the toolchain for `HACK`/Jack development.

## vim

vim configuration file to highlight syntax of jack/hack-files, when editing with vim. Copy the content of the subfolders into the appropriate vim configuration directory situated in your home directory  `~/.vim`.

```
$ cp vim/syntax/* ~/.vim/syntax/
$ cp vim/ftdetect/* ~/.vim/ftdetect/
```

## Assembler

Assembler translates `HACK` assembly files to machine code. Outputs the machine code to `filename.hack`.

`usage: ./Assembler/assembler.pyc [filename.asm]`

## JackCompiler

Compiles Jack classes (single file or all `*.jack` files in directory) to VM code.

`usage: ./JackCompiler/JackCompiler.pyc [filename.jack] or [dir]`

## VMTranslator

Translates VM code (single file or all files with ending `*.vm` in directory) to assembly.

`usage: ./VMTranslator/VMTranslator.pyc [filename.vm] or [dir]`

## AsciiToBin.py

Translates `.hack` files to binary files that can be uploaded with `iceprogduino`.

`usage: ./AsciiToBin.py [filename.hack]`

## iceprogduino

`iceprogduino` is the programmer to upload bitstream files to iCE40 boards via `olimexino-32u4` (an Arduino-like board).

For this you first have to upload firmware to `olimexino-32u4`.

Connect:

1. `iCE40HX18K-EVB` to `olimexino-32u4` (over UEXT).
2. `olimexino-32u4` (with installed firmware) to PC over USB.
