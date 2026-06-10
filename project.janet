(declare-project
  :name "simtest"
  :description "Traffic simulation with Janet and Raylib"
  :dependencies ["https://github.com/janet-lang/jaylib.git"
                 "https://github.com/janet-lang/spork.git"])

(declare-executable
  :name "simtest"
  :entry "src/main.janet")
