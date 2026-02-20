# Agent Guidance

- In every new shell, run `source ~/src/nand2tetris-fpga/.venv/bin/activate`.
- Feature work for this request is scoped to `09_More_Fun_to_Go`.
- You may read other repository areas for context, but keep implementation edits in `09_More_Fun_to_Go` unless explicitly requested otherwise.
- Build with virtual environment activated, then run: `apio clean && apio build`.
- Run headless simulation with `cd ~/src/nand2tetris-fpga/09_More_Fun_to_Go/00_Hack && source ~/src/nand2tetris-fpga/.venv/bin/activate && apio clean && apio test` (use `apio sim` only when you want GTKWave GUI).
- Grep for `// COPILOT` directives in the repo at the start of each session and action them. These are inline requests left by the developer for the agent to fulfill.
- After actioning a `// COPILOT` directive, remove it from the source file unless it explicitly says to leave it in place.
- Track progress on `// COPILOT` directives in `TODO.md` at the repo root.
