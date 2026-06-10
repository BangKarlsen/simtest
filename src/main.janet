(import jaylib :as j)
(import ./game :prefix "")

(desktop)
(common-startup)
(while (not (j/window-should-close))
  (update-draw-frame))
(j/close-window)
