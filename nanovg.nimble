# Package

version       = "0.1.0"
author        = "Joey Yakimowich-Payne"
description   = "A wrapper around nanovg"
license       = "MIT"
srcDir        = "src"

# Dependencies

requires "nim >= 1.0.0",
         "nimterop#head",
         "regex >= 0.12.0",
         "opengl >= 1.2.2",
         "https://github.com/jyapayne/nim-glfw#d4f30db",
         "sdl2_nim >= 2.0.5.0"

import os

task buildSDL2Example, "Build SDL2 example":
  let buildDir = "build/demosdl2"
  if system.existsDir(buildDir):
    rmDir buildDir
  var arch = ""
  if defined(amd64):
    arch = "64bit"
  else:
    arch = "32bit"
  mkDir buildDir
  var files = listFiles "lib/" & arch & "/"
  for fpath in files:
    let fname = fpath.extractFileName()
    if fname.startsWith("lib") or fname.startsWith("SDL2") or fname.startsWith("glew"):
      cpFile fpath, buildDir & "/" & fname
  exec "nim c --app:gui -d:release -d:danger -o:" & buildDir & "/" & "demo_sdl2".toExe & " -r examples/demo_sdl2.nim"

task buildGLFWExample, "Build GLFW example":
  switch("define", "useGlfw")
  var arch = ""
  let buildDir = "build/demo"
  if system.existsDir(buildDir):
    rmDir buildDir
  if defined(amd64):
    arch = "64bit"
  else:
    arch = "32bit"
  mkDir buildDir
  var files = listFiles "lib/" & arch & "/"
  for fpath in files:
    let fname = fpath.extractFileName()
    if fname.startsWith("gl"):
      cpFile fpath, buildDir & "/" & fname
  exec "nim c --app:gui -d:release -d:danger -o:" & buildDir & "/" & "demo_glfw".toExe & " -r examples/demo.nim"