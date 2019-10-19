# Package

version       = "0.1.0"
author        = "Joey Yakimowich-Payne"
description   = "A wrapper around nanovg"
license       = "MIT"
srcDir        = "src"

# Dependencies

requires "nim >= 1.0.0",
         "nimterop >= 0.2.1",
         "regex >= 0.12.0",
         "opengl >= 1.2.2",
         "https://github.com/jyapayne/nim-glfw#d4f30db"

task buildExample, "Build example":
    exec "nim c -d:release -d:danger -r examples/demo.nim"
