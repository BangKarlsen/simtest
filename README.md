# simtest — Traffic Simulation in Janet

A small graphical traffic simulation built with [Janet](https://janet-lang.org/) and [Raylib](https://www.raylib.com/) (via [Jaylib](https://github.com/janet-lang/jaylib)). Runs natively on macOS and compiles to WASM for the browser.

## Bootstrap

After cloning or copying this project, initialize git and pull in the submodules:

```bash
git init
git submodule add https://github.com/janet-lang/janet.git janet
git submodule add https://github.com/sogaiu/jaylib.git jaylib
git submodule update --init --recursive
```

Then install dependencies and run:

```bash
make setup   # install Janet, Jaylib, Spork via Homebrew/jpm
make dev     # run simulation with live REPL
```

## Live-Coding with the Network REPL

The recommended development workflow uses `make dev`, which runs the simulation **and** starts a network REPL server. You connect from a second terminal and can modify the running simulation interactively — change state, redefine functions, and see the results immediately in the window.

### 1. Start the simulation with REPL server

```bash
make dev
```

This opens the Raylib window and prints connection instructions.

### 2. Connect from another terminal

```bash
janet -e '(import spork/netrepl) (netrepl/client)'
```

You're now in the game's environment. Everything defined in `src/game.janet` is available directly.

### 3. Inspect and tweak state live

```janet
# See the current game state
state
# => @{:cars @[@{:x 280 :y 300 :speed 2 :color [220 50 50]} ...] :scroll 0}

# Speed up the first car — watch it move faster in the window
(put ((state :cars) 0) :speed 10)

# Change its color to gold
(put ((state :cars) 0) :color [255 203 0])

# Add a new car
(array/push (state :cars) @{:x 320 :y 0 :speed 4 :color [255 0 255]})
```

Changes take effect on the next frame — you'll see them in the window immediately.

### 4. Reload code after editing

After saving changes to `src/game.janet`, call the built-in reload helper:

```janet
(reload)
# => reloaded src/game.janet
```

This re-evaluates the file, picking up new function definitions and constants. Game state (car positions, speeds, etc.) is preserved across reloads.

### 5. Redefine functions on the fly

You can also redefine individual functions directly in the REPL without editing the file:

```janet
# Make the road wider, just to try it
(defn draw-game [st]
  (j/begin-drawing)
  (j/clear-background [30 30 30])
  (j/draw-rectangle 100 0 600 screen-height [80 80 80])
  # ... rest of your draw code
  (j/end-drawing))
```

Note: if you redefine a function that's called by another function (e.g. redefining `draw-game` which is called by `update-draw-frame!`), you'll also need to redefine the caller, or just use `(reload)` to reload the whole file.

### How it works

`src/dev.janet` loads the game module and shares its environment with a `spork/netrepl` server. The game loop yields to Janet's event loop each frame (`ev/sleep 0`), giving the REPL server a chance to process your input between frames. The simulation and REPL run cooperatively in the same process.

## Standalone REPL (no window)

You can also use the basic Janet REPL to test logic without any graphics:

```bash
janet
```

```janet
repl:1:> (+ 1 2)
3
repl:2:> (string "hello " "world")
"hello world"
```

Load the game module (without opening a window):

```janet
repl:1:> (import jaylib :as j)
repl:2:> (import ./src/game :prefix "" :fresh true)
```

The `:prefix ""` pulls all exports into scope. `:fresh true` forces re-evaluation (bypasses module cache) — use it to pick up edits.

This is useful for testing pure logic functions without the graphics:

```janet
repl:3:> (update-game! state)
repl:4:> ((state :cars) 0)
@{:x 280 :y 298 :speed 2 :color [220 50 50]}
```

### Useful REPL expressions

| Expression | What it does |
|---|---|
| `(doc j/draw-rectangle)` | Show function signature and docstring |
| `(doc update-game!)` | Works for your own functions too |
| `(type state)` | Check a value's type |
| `(keys state)` | List keys in a table/struct |
| `(pp state)` | Pretty-print any value |
| `(reload)` | Reload game.janet (in `make dev` netrepl only) |

## Jaylib color keywords

Colors can be tuples `[r g b]` or `[r g b a]`, or these keywords:

`:white` `:black` `:ray-white` `:red` `:green` `:blue` `:yellow` `:orange`
`:pink` `:purple` `:violet` `:magenta` `:maroon` `:gold` `:lime` `:beige`
`:brown` `:gray` `:dark-gray` `:light-gray` `:dark-green` `:dark-blue`
`:dark-purple` `:dark-brown` `:sky-blue` `:blank`
