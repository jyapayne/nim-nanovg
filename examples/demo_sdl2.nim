import sdl2/sdl except Color
import sdl2/sdl_image as img, opengl

import os
import nanovg
import perf
import common

proc events(): bool =
  result = false
  var e: sdl.Event

  while sdl.pollEvent(addr(e)) != 0:

    # Quit requested
    if e.kind == sdl.Quit:
      return true

    # Key pressed
    elif e.kind == sdl.KeyDown:
      # Exit on Escape key press
      if e.key.keysym.sym == sdl.K_Escape:
        return true

proc frameBufferSize*(window: Window): tuple[w, h: int32] =
  var
    fbWidth: cint
    fbHeight: cint

  window.glGetDrawableSize(fbWidth.addr, fbHeight.addr)

  return (fbWidth.int32, fbHeight.int32)

proc size*(window: Window): tuple[w, h: int32] =
  var
    width: cint
    height: cint

  window.getWindowSize(width.addr, height.addr)

  return (width.int32, height.int32)

proc main() =
  let
    fps = newGraph(RenderStyle.FPS, "Frame Time")
    cpuGraph = newGraph(RenderStyle.MS, "CPU Time")
  let
    windowFlags: uint32 = sdl.WINDOW_OPENGL or sdl.WINDOW_ALLOW_HIGHDPI or sdl.WINDOW_SHOWN
    screenWidth = 640
    screenHeight = 480

  discard sdl.init(sdl.INIT_EVERYTHING)

  discard sdl.glSetAttribute(sdl.GL_CONTEXT_PROFILE_MASK, sdl.GL_CONTEXT_PROFILE_CORE)
  discard sdl.glSetAttribute(sdl.GL_CONTEXT_FLAGS, sdl.GL_CONTEXT_FORWARD_COMPATIBLE_FLAG)
  discard sdl.glSetAttribute(sdl.GL_CONTEXT_MAJOR_VERSION, 3)
  discard sdl.glSetAttribute(sdl.GL_CONTEXT_MINOR_VERSION, 2)

  let window = sdl.createWindow(
    "SDL2 Test",
    sdl.WINDOWPOS_CENTERED,
    sdl.WINDOWPOS_CENTERED,
    screenWidth, screenHeight, windowFlags
  )

  let context = glCreateContext(window)

  discard sdl.glSetSwapInterval(0)

  var done = false
  var prevt: float = sdl.getTicks().float/1000.0

  glewInit()
  nanovg.init()
  nanovg.loadFont(currentSourceDir()/"resources/Roboto-Regular.ttf", "sans")
  nanovg.loadFont(currentSourceDir()/"resources/Roboto-Bold.ttf", "sans-bold")
  nanovg.loadFont(currentSourceDir()/"resources/fa.ttf", "fa")
  nanovg.loadFont(currentSourceDir()/"resources/entypo.ttf", "icons")

  while not done:
    let fbSize = window.frameBufferSize()

    glViewPort(0, 0, fbSize.w, fbSize.h)
    glCullFace(GL_BACK)
    glFrontFace(GL_CCW)
    glClearColor(0.3, 0.3, 0.32, 1.0)
    glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT or GL_STENCIL_BUFFER_BIT)

    withFrame(window):
      let x = glyphPositions("Some仮名thing is up", 0, 0)
      drawWindow("Title", 50, 50, 300, 400)
      drawLabel("Hello!", 10, 10, 280, 20)
      drawButton(ICON_TRASH, "Delete", 100, 200, 160, 28, RGBA(128, 16, 8, 255))
      drawButton(ICON_TRASH, "Deleter", 100, 250, 160, 28, RGBA(12, 130, 80, 255))
      drawButton("Testing", 100, 300, 160, 28)

      fps.render(5, 5)
      cpuGraph.render(210, 5)

    let t: float = sdl.getTicks().float/1000.0
    let dt = t - prevt
    prevt = t

    window.glSwapWindow()
    done = events()

    let cpuTime: float = sdl.getTicks().float/1000.0 - t

    fps.update(dt)
    cpuGraph.update(cpuTime)


  sdl.glDeleteContext(context)
  window.destroyWindow()
  img.quit()
  sdl.quit()

main()