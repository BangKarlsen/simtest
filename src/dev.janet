(import jaylib :as j)
(import spork/netrepl)

# Load game module, keeping a reference to its environment
(def game-env (dofile "./src/game.janet"))

(defn- gv
  "Get a value from the game environment (handles both def and var)."
  [name]
  (when-let [entry (get game-env (symbol name))]
    (if-let [r (get entry :ref)] (in r 0)
      (get entry :value))))

(defn- sv
  "Set a value in the game environment (handles both def and var)."
  [name val]
  (when-let [entry (get game-env (symbol name))]
    (if-let [r (get entry :ref)] (put r 0 val)
      (put entry :value val))))

(defn reload
  "Reload src/game.janet. Preserves game state, picks up new code."
  []
  (def old-state (gv "state"))
  (dofile "./src/game.janet" :env game-env)
  (sv "state" old-state)
  (sv "update-draw-frame" (gv "update-draw-frame!"))
  (print "reloaded src/game.janet"))

(put game-env 'reload @{:value reload
                         :doc "(reload)\n\nReload src/game.janet, preserving state."})

# Initialize the simulation
((gv "desktop"))
((gv "common-startup"))

# Start netrepl server sharing the game environment
(printf "netrepl listening on 127.0.0.1:9365")
(printf "connect from another terminal:")
(printf "  janet -e '(import spork/netrepl) (netrepl/client)'")
(netrepl/server-single "127.0.0.1" "9365" game-env)

# Game loop — ev/sleep yields to the event loop each frame,
# letting the netrepl server process commands between frames
(while (not (j/window-should-close))
  ((gv "update-draw-frame!"))
  (ev/sleep 0))

(j/close-window)
