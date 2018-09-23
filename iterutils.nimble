# Package
version = "0.4"
author = "Dennis Felsing"
description = "Functional operations for iterators and slices, similar to sequtils"
license = "MIT"

srcDir = "src"

# Deps
requires "nim >= 0.13.0"

task test, "Test":
  exec "nim c -r src/iterutils.nim"
