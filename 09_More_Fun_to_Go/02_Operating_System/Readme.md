# 02 Operating System

- Imported the following classes from nand2tetris course implementation to restore behaviour to original spec:
  - `Keyboard.jack`: `RTP` used in lieu of keyboard previously.
  - `Output.jack`: Reverted to original resolution & row/col layout.
  - `Screen.jack`: Reverted to original resolution & drawing APIs.
- Updated `Memory.jack` with new memory ranges so heap doesn't overlap with the memory mapped I/O addresses.
  - This is probably the one main change left currently blocking ABI compatibility with spec compliant HACK binaries.
- Updated `Sys.jack` to initialize `VRAM` on boot.

Other test specific changes mentioned in their directories, implementation brought forward from `07_Operating_System` if not otherwise mentioned.
