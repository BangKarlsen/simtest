.PHONY: dev run native deps wasm serve clean clean-wasm clean-all setup help

# ── Native (daily development) ──────────────────────────────────────

dev:
	janet src/dev.janet

run:
	janet src/main.janet

native:
	jpm build

deps:
	jpm deps

# ── WASM (browser deployment) ───────────────────────────────────────

wasm:
	janet wasm/build.janet

serve:
	@echo "Serving at http://localhost:8000/main.html"
	cd public && python3 -m http.server 8000

# ── Clean ───────────────────────────────────────────────────────────

clean:
	rm -rf build/
	-jpm clean 2>/dev/null

clean-wasm:
	rm -rf public/
	rm -f resources/game.janet resources/jaylib.janet

clean-all: clean clean-wasm

# ── First-time setup ────────────────────────────────────────────────

setup:
	@echo "=== Install Janet ==="
	brew install janet
	@echo ""
	@echo "=== Install Jaylib ==="
	jpm install https://github.com/janet-lang/jaylib.git
	@echo ""
	@echo "=== Install Spork (netrepl for live coding) ==="
	@echo "If this fails, see README troubleshooting section."
	jpm install https://github.com/janet-lang/spork.git
	@echo ""
	@echo "=== Init git submodules (for WASM build) ==="
	git submodule update --init --recursive
	@echo ""
	@echo "=== Done! ==="
	@echo ""
	@echo "Native build ready. Try:  make run"
	@echo ""
	@echo "For WASM builds, also install emsdk:"
	@echo "  git clone https://github.com/emscripten-core/emsdk.git ~/emsdk"
	@echo "  cd ~/emsdk && ./emsdk install latest && ./emsdk activate latest"
	@echo "  source ~/emsdk/emsdk_env.sh"
	@echo "  make wasm && make serve"

help:
	@echo "Native development:"
	@echo "  make dev        Run with netrepl (interactive live-coding)"
	@echo "  make run        Run simulation natively (no REPL)"
	@echo "  make native     Build standalone executable via jpm"
	@echo "  make deps       Install Janet dependencies"
	@echo ""
	@echo "WASM / browser:"
	@echo "  make wasm       Build WASM (requires emsdk in PATH)"
	@echo "  make serve      Serve public/ at localhost:8000"
	@echo ""
	@echo "Housekeeping:"
	@echo "  make clean      Remove native build artifacts"
	@echo "  make clean-wasm Remove WASM build artifacts"
	@echo "  make setup      First-time dependency install"
