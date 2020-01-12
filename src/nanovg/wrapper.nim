import os
import opengl
import regex

import nimterop/[cimport, build]

# Documentation:
#   https://github.com/nimterop/nimterop
#   https://nimterop.github.io/nimterop/cimport.html

const
  baseDir = currentSourcePath.parentDir().parentDir().parentDir()
  srcDir = baseDir/"build"/"nanovg"

static:
  # Print generated Nim to output
  # cDebug()

  # Disable caching so that wrapper is generated every time. Useful during
  # development. Remove once wrapper is working as expected.
  # cDisableCaching()

  # Download C/C++ source code from a git repository
  gitPull("https://github.com/memononen/nanovg", outdir=srcDir, plist="""
src/*.h
src/*.c
""", checkout = "1f9c8864fc556a1be4d4bf1d6bfe20cde25734b4")

  let contents = readFile(srcDir/"src/nanovg_gl.h")
  when defined(useGlfw):
    let newContents = contents.replace(re"#define NANOVG_GL_H", """
#define NANOVG_GL_H
#define NANOVG_GL_USE_UNIFORMBUFFER
#define NANOVG_GL3
#define GLFW_INCLUDE_GLEXT
#ifdef __APPLE__
#  define GLFW_INCLUDE_GLCOREARB
#endif
#include <GL/glew.h>
#include <GLFW/glfw3.h>
#include "nanovg.h"
""", limit=1)
  else:
    let newContents = contents.replace(re"#define NANOVG_GL_H", """
#define NANOVG_GL_H
#define NANOVG_GL_USE_UNIFORMBUFFER
#define NANOVG_GL3
#include <GL/glew.h>
#include "nanovg.h"
""", limit=1)

  writeFile(srcDir/"src/nanovg_gl.h", newContents)

cDefine("NANOVG_GL3_IMPLEMENTATION", "")

# Manually wrap any symbols since nimterop cannot or incorrectly wraps them
cOverride:
  # Standard Nim code to wrap types, consts, procs, etc.
  type
     NVGcontext* {.importc: "struct NVGcontext", bycopy.} = object
     NVGcolor* {.importc: "struct NVGcolor", bycopy.} = object
       r* {.importc: "r".}: cfloat
       g* {.importc: "g".}: cfloat
       b* {.importc: "b".}: cfloat
       a* {.importc: "a".}: cfloat

# Specify include directories for gcc and Nim
cIncludeDir(srcDir/"src")

# Any global compiler options
when defined(macosx):
  # cDefine("GLFW_INCLUDE_GLCOREARB", "1")
  when defined(useGlfw):
    {.passC: "-DNANOVG_GL3_IMPLEMENTATION -DNANOVG_GLEW -D_GLFW_USE_RETINA -D_GLFW_COCOA -D_GLFW_USE_CHDir -D_GLFW_USE_MENUBAR".}
    {.passL: "-m64 -lglew -framework GLUT -framework OpenGL -framework Cocoa -framework IOKit -framework CoreVideo -framework Carbon -lm".}
  else:
    {.passC: "-DNANOVG_GL3_IMPLEMENTATION -DNANOVG_GLEW".}
    {.passL: "-m64 -lglew -framework GLUT -framework OpenGL -framework Cocoa -framework IOKit -framework CoreVideo -framework Carbon -lm".}

elif defined(unix):
  {.passC: "-DNANOVG_GL3_IMPLEMENTATION -DNANOVG_GLEW".}
  when defined(useGlfw):
    {.passL: "-lGL -lGLU -lGLEW -lm -lglfw".}
  else:
    {.passL: "-lGL -lGLU -lGLEW -lm -lSDL2".}
elif defined(windows):
  const inclPath = baseDir/"lib"/"include"
  when defined(amd64):
    const libPath = baseDir/"lib"/"64bit"
  else:
    const libPath = baseDir/"lib"/"32bit"
  when defined(useGlfw):
    {.passC: "-I" & inclPath & "-DNANOVG_GL3_IMPLEMENTATION -DNANOVG_GLEW -DGLEW_STATIC -D_CRT_SECURE_NO_WARNINGS -w -fmax-errors=10".}
    {.passL: "-L" & libPath & " -static -lglew32 -lm -lglfw3 -lgdi32 -lwinmm -luser32 -lglu32 -lopengl32 -lkernel32".}
  else:
    {.passC: "-I" & inclPath & "-DNANOVG_GL3_IMPLEMENTATION -D_CRT_SECURE_NO_WARNINGS -w -fmax-errors=10".}
    {.passL: "-L" & libPath & "-lSDL2 -lSDL2_image -lm -lgdi32 -lglew32 -lwinmm -luser32 -lglu32 -lopengl32 -lkernel32".}


# Compile in any common source code
cCompile(srcDir/"src/*.c")

# Use cPlugin() to make any symbol changes
cPlugin:
  import strutils, regex

  # Symbol renaming examples
  proc onSymbol*(sym: var Symbol) {.exportc, dynlib.} =
    # Get rid of leading and trailing underscores
    # sym.name = sym.name.strip(chars = {'_'})

    # Remove prefixes or suffixes from procs
    if sym.name.startsWith("nvg__"):
      sym.name = sym.name.replace(re"nvg__", "")

    if sym.kind == nskProc:
      sym.name = sym.name.replace(re"glnvg__", "")
      sym.name = sym.name.replace(re"nvg__", "")
      sym.name = sym.name.replace(re"nvglu", "")
      sym.name = sym.name.replace(re"nvgl", "")
      sym.name = sym.name.replace(re"nvg", "")

# Finally import wrapped header file. Recurse if #include files should also
# be wrapped. Set dynlib if binding to dynamic library.
cImport(srcDir/"src/nanovg.h")
cImport(srcDir/"src/nanovg_gl.h")
cImport(srcDir/"src/nanovg_gl_utils.h")
