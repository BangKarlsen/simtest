# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## First-Time Setup

```bash
# Install Janet (includes jpm package manager)
brew install janet

# Install Jaylib native module (compiles Raylib from source)
jpm install https://github.com/janet-lang/jaylib.git

# Initialize git submodules (needed for WASM builds)
git submodule update --init --recursive

# Or do all of the above:
make setup
```

For WASM builds, also install Emscripten SDK:
```bash
git clone https://github.com/emscripten-core/emsdk.git ~/emsdk
cd ~/emsdk && ./emsdk install latest && ./emsdk activate latest
```

## Build & Development

### Native (daily development)
```bash
make dev                 # Run with live netrepl (recommended)
make run                 # Run without REPL
make native              # Build standalone executable to build/simtest
```

### WASM (browser)
```bash
source ~/emsdk/emsdk_env.sh    # Activate Emscripten (once per shell)
make wasm                       # Build to public/
make serve                      # Serve at http://localhost:8000/main.html
```

Set `SIMTEST_SKIP_DEPS=1` to skip rebuilding Janet/Raylib when only game code changed:
```bash
SIMTEST_SKIP_DEPS=1 janet wasm/build.janet
```

### Live REPL (with running simulation)
```bash
make dev                                         # Terminal 1: starts sim + netrepl server
janet -e '(import spork/netrepl) (netrepl/client)'  # Terminal 2: connect to running sim
# In the netrepl:
state                                            # Inspect game state
(put ((state :cars) 0) :speed 10)                # Tweak — see change in window immediately
(reload)                                         # After editing game.janet, reload code
```

### Standalone REPL (no window)
```bash
janet
(import jaylib :as j)
(import ./src/game :prefix "" :fresh true)       # :fresh true to hot-reload
```

Useful for testing pure logic without graphics.

## Architecture

**Language**: Janet (Lisp-on-C). **Graphics**: Raylib via Jaylib bindings. **Web target**: Emscripten (C → WASM).

### Two build paths

- **Native**: `jpm` reads `project.janet`, links the system-installed jaylib `.so` module. `janet src/main.janet` runs directly.
- **WASM**: `wasm/build.janet` orchestrates: build Janet amalgamated C → build libraylib.a for web → generate jaylib shim → copy game.janet to `resources/` → compile everything with `emcc`. The C wrapper `wasm/main.c` embeds the Janet runtime, registers jaylib C functions, loads `resources/game.janet`, and runs `emscripten_set_main_loop`. Based on [jaylib-wasm-demo](https://github.com/sogaiu/jaylib-wasm-demo).

### Source layout

- `src/game.janet` — Shared simulation logic. Exports `common-startup`, `update-draw-frame`, `main-fiber`, `desktop` (the names `wasm/main.c` looks up by string).
- `src/main.janet` — Native entry point (no REPL). Thin wrapper that calls game module functions in a loop.
- `src/dev.janet` — Development entry point. Runs the game loop with a `spork/netrepl` server for live coding. Provides a `(reload)` helper that re-evaluates game.janet while preserving state.
- `wasm/main.c` — C embedding wrapper for WASM. Registers jaylib C functions into Janet environment, loads game module, drives the frame loop.
- `wasm/build.janet` — WASM build script (replaces Makefile for the WASM pipeline).
- `wasm/make-shim.janet` — Generates `resources/jaylib.janet` so `(import jaylib)` works in the WASM virtual filesystem.
- `wasm/shell.html` — HTML template with canvas for Emscripten output.

### Jaylib API conventions

- Raylib `PascalCase` → Janet `kebab-case`: `DrawRectangle` → `(j/draw-rectangle ...)`
- Colors: keywords `:white`, `:ray-white`, `:red` etc. (kebab-case) or tuples `[r g b]` / `[r g b a]`
- Vectors: tuples `[x y]`, `[x y z]`
- Resources (textures, sounds) are **not garbage-collected** — free them manually
- Check function signatures in `jaylib/src/*.h` — the `_cfuns[]` arrays have doc strings

### Git submodules (WASM build only)

- `janet/` — Janet language source (built to amalgamated C)
- `jaylib/` — sogaiu's fork with Raylib as a nested submodule at `jaylib/raylib/`
