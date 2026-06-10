(import jaylib :as j)

# --- Constants ---

(def screen-width 800)
(def screen-height 450)

(def road-left 200)
(def road-width 400)
(def lane-count 4)
(def lane-width (/ road-width lane-count))

# --- State ---

(var state @{:cars @[@{:x 280 :y 300 :speed 2 :color [220 50 50]}
                     @{:x 480 :y 100 :speed 3 :color [50 120 220]}
                     @{:x 380 :y 200 :speed 1.5 :color [50 200 80]}]
              :scroll 0})

# --- Update ---

(defn update-game!
  [st]
  # Scroll road markings
  (update st :scroll |(mod (+ $ 2) 60))
  # Move each car upward, wrap around
  (each car (st :cars)
    (update car :y |(- $ (car :speed)))
    (when (< (car :y) -60)
      (put car :y (+ screen-height 60))))
  st)

# --- Draw ---

(defn draw-game
  [st]
  (j/begin-drawing)
  (j/clear-background [30 30 30])

  # Road surface
  (j/draw-rectangle road-left 0 road-width screen-height [80 80 80])

  # Lane markings (dashed lines)
  (for lane 1 lane-count
    (def lx (+ road-left (* lane lane-width)))
    (var y (- (math/floor (st :scroll)) 60))
    (while (< y screen-height)
      (j/draw-rectangle (- lx 2) y 4 30 [255 255 0])
      (+= y 60)))

  # Road edge lines
  (j/draw-rectangle road-left 0 3 screen-height [255 255 255])
  (j/draw-rectangle (- (+ road-left road-width) 3) 0 3 screen-height [255 255 255])

  # Cars
  (each car (st :cars)
    (j/draw-rectangle
      (math/floor (car :x))
      (math/floor (car :y))
      40 60 (car :color)))

  # HUD
  (j/draw-text "Traffic Simba 200" 10 10 20 :ray-white)
  (j/draw-fps 10 (- screen-height 30))

  (j/end-drawing))

# --- Per-frame callback ---

(defn update-draw-frame!
  []
  (update-game! state)
  (draw-game state))

# --- Platform setup ---

(defn desktop
  []
  (j/set-config-flags :msaa-4x-hint)
  (j/set-target-fps 60))

# Filled in by common-startup (used by wasm/main.c)
(var update-draw-frame nil)
(var main-fiber nil)

(defn common-startup
  []
  (j/init-window screen-width screen-height "Traffic Sim")
  (set update-draw-frame update-draw-frame!)
  (set main-fiber
       (fiber/new
         (fn []
           (while (not (j/window-should-close))
             (update-draw-frame!)
             (yield)))
         :i)))
