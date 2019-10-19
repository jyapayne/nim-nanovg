import os
import opengl
import strutils

import nimterop/[cimport, build]

# Documentation:
#   https://github.com/nimterop/nimterop
#   https://nimterop.github.io/nimterop/cimport.html

const
  # Location where any sources should get downloaded. Adjust depending on
  # actual location of wrapper file relative to project.
  baseDir = currentSourcePath.parentDir().parentDir().parentDir()/"build"

  # All files and dirs should be inside to baseDir
  srcDir = baseDir/"nanovg"

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
  let newContents = contents.replace("#define NANOVG_GL_H\n", """
#define NANOVG_GL_USE_UNIFORMBUFFER
#define NANOVG_GL3
#define GLFW_INCLUDE_GLEXT
#ifdef __APPLE__
#  define GLFW_INCLUDE_GLCOREARB
#endif
#include <GLFW/glfw3.h>
#include "nanovg.h"
""")
  writeFile(srcDir/"src/nanovg_gl.h", newContents)

# Manually wrap any symbols since nimterop cannot or incorrectly wraps them
cOverride:
  # Standard Nim code to wrap types, consts, procs, etc.
  type
     NVGcolor* {.importc: "struct NVGcolor", bycopy.} = object
       r* {.importc: "r".}: cfloat
       g* {.importc: "g".}: cfloat
       b* {.importc: "b".}: cfloat
       a* {.importc: "a".}: cfloat

# Specify include directories for gcc and Nim
cIncludeDir(srcDir/"src")

# Define global symbols
cDefine("NANOVG_GL3_IMPLEMENTATION", "1")

# Any global compiler options
when defined(macosx):
  # cDefine("GLFW_INCLUDE_GLCOREARB", "1")
  {.passC: "-DNANOVG_GL3_IMPLEMENTATION -DNANOVG_GLEW -D_GLFW_USE_RETINA -D_GLFW_COCOA -D_GLFW_USE_CHDir -D_GLFW_USE_MENUBAR".}
  {.passL: "-m64 -framework GLUT -framework OpenGL -framework Cocoa -framework IOKit -framework CoreVideo -framework Carbon -lm".}

elif defined(unix):
  {.passC: "-DNANOVG_GL3_IMPLEMENTATION -DNANOVG_GLEW".}
  {.passL: "-lGL -lGLU -lGLEW -lm -lglfw".}
elif defined(windows):
  {.passC: "-DNANOVG_GL3_IMPLEMENTATION -DNANOVG_GLEW -D_CRT_SECURE_NO_WARNINGS".}
  {.passL: "-lglew32 -lm -lglfw3 -lgdi32 -lwinmm -luser32 -lglu32 -lopengl32 -lkernel32".}


# Compile in any common source code
cCompile(srcDir/"src/*.c")

# Use cPlugin() to make any symbol changes
cPlugin:
  import strutils

  # Symbol renaming examples
  proc onSymbol*(sym: var Symbol) {.exportc, dynlib.} =
    # Get rid of leading and trailing underscores
    # sym.name = sym.name.strip(chars = {'_'})

    # Remove prefixes or suffixes from procs
    if sym.kind == nskProc:
      sym.name = sym.name.replace("glnvg__", "")
      sym.name = sym.name.replace("nvg__", "")
      sym.name = sym.name.replace("nvglu", "")
      sym.name = sym.name.replace("nvgl", "")
      sym.name = sym.name.replace("nvg", "")

# Finally import wrapped header file. Recurse if #include files should also
# be wrapped. Set dynlib if binding to dynamic library.
cImport(srcDir/"src/nanovg.h")
cImport(srcDir/"src/nanovg_gl.h")
cImport(srcDir/"src/nanovg_gl_utils.h")
