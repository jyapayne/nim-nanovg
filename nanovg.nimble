# Package

version       = "0.1.0"
author        = "Joey Yakimowich-Payne"
description   = "A wrapper around nanovg"
license       = "MIT"
srcDir        = "src"

# Dependencies

requires "nim >= 1.0.6",
         "nimterop#head",
         "regex >= 0.14.1",
         "opengl >= 1.2.6",
         "nim-glfw#head",
         "nim_sdl2"

import os

proc setupBuildDir(buildDir: string, prefixes: openArray[string]) =
  var arch = ""
  if system.existsDir(buildDir):
    rmDir buildDir
  if defined(amd64):
    arch = "64bit"
  else:
    arch = "32bit"
  mkDir buildDir

  if not defined(windows):
    return

  var files = listFiles "lib/" & arch & "/"
  for fpath in files:
    let fname = fpath.extractFileName()
    for prefix in prefixes:
      if fname.startsWith(prefix):
        cpFile fpath, buildDir & "/" & fname

proc setupGLFW(): string =
  switch("define", "useGlfw")
  let buildDir = "build/demo"
  setupBuildDir(buildDir, ["gl"])
  return buildDir

proc setupSDL2(): string =
  let buildDir = "build/demosdl2"
  setupBuildDir(buildDir, ["lib", "SDL2", "glew"])
  return buildDir

task buildSDL2Example, "Build SDL2 example":
  let buildDir = setupSDL2()
  exec "nimble c --app:gui -d:release -d:danger -o:" & buildDir & "/" & "demo_sdl2".toExe & " -r examples/demo_sdl2.nim"

task buildSDL2ExampleDebug, "Build SDL2 example debug":
  let buildDir = setupSDL2()
  exec "nimble c --app:gui --debugger:native -o:" & buildDir & "/" & "demo_sdl2_debug".toExe & " -r examples/demo_sdl2.nim"

task buildSDL2GPUExample, "Build SDL2 GPU example":
  let buildDir = setupSDL2()
  exec "nimble c --app:gui -d:release -d:danger -o:" & buildDir & "/" & "demo_sdl2_gpu".toExe & " -r examples/demo_sdl2_gpu.nim"

task buildSDL2GPUExampleDebug, "Build SDL2 GPU debug example":
  let buildDir = setupSDL2()
  exec "nimble c --app:gui --debugger:native -o:" & buildDir & "/" & "demo_sdl2_gpu".toExe & " -r examples/demo_sdl2_gpu.nim"

task buildGLFWExample, "Build GLFW example":
  let buildDir = setupGLFW()
  exec "nimble c --app:gui -d:useGlfw -d:release -d:danger -o:" & buildDir & "/" & "demo_glfw".toExe & " -r examples/demo.nim"

task buildGLFWExampleDebug, "Build GLFW example debug":
  let buildDir = setupGLFW()
  exec "nimble c --app:gui --debugger:native -o:" & buildDir & "/" & "demo_glfw_debug".toExe & " -r examples/demo.nim"