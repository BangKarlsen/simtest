# Generate resources/jaylib.janet shim for WASM builds.
#
# In native builds, jaylib loads as a compiled .so module. In WASM builds,
# jaylib C functions are registered directly into the Janet environment by
# main.c. This shim creates (def fn-name fn-name) entries so that
# (import jaylib) resolves correctly in the WASM virtual filesystem.
#
# Usage: janet wasm/make-shim.janet jaylib/src resources/jaylib.janet

(defn main
  [& args]
  (def dir-root
    (when-let [dir (get args 1)]
      dir))
  (def shim-file-path
    (when-let [filepath (get args 2)]
      filepath))
  #
  (default dir-root "jaylib/src")
  (default shim-file-path "resources/jaylib.janet")
  #
  (def shim-file-dir
    (if-let [rev-path (string/reverse shim-file-path)
             slash-idx (string/find "/" rev-path)]
      (-> (string/slice rev-path (inc slash-idx))
          (string/reverse))
      "."))
  (unless (= :directory
             (os/stat shim-file-dir :mode))
    (eprintf "%p should exist and be a directory" shim-file-dir)
    (os/exit 1))
  #
  (def cfuns @[])
  (def dups @{})
  # parse *.h files in jaylib, collecting function names
  (each hf (os/dir dir-root)
    (def res
      (->> (slurp (string dir-root "/" hf))
           (peg/match
             ~(sequence (thru "_cfuns[] = {")
                        (thru "\n")
                        (some (sequence (thru `"`)
                                        (capture (to `"`))
                                        `"`
                                        (thru "\n")))))))
    (array/concat cfuns res))
  # write jaylib.janet with def forms
  (def jjf
    (try
      (file/open shim-file-path :w)
      ([e]
        (eprintf "problem opening file for writing: %p" e)
        (os/exit 1))))
  (each cf cfuns
    (when cf
      (when (nil? (get dups cf))
        (file/write jjf
                    (string "(def " cf " " cf ")\n"))
        (put dups cf true))))
  (file/close jjf))
