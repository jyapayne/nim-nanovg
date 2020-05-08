import sdl2/sdl2 as sdl
import sdl2/sdl2_image as img, glew

import os
import nanovg
import perf
import common

proc events(): bool =
  result = false
  var e: sdl.Event

  while sdl.pollEvent(addr(e)) != 0:

    # Quit requested
    if e.kind.EventType == sdl.EventQuit:
      return true

    # Key pressed
    elif e.kind.EventType == sdl.EventKeyDown:
      # Exit on Escape key press
      if e.key.keysym.sym == sdl.KeycodeEscape:
        return true

proc frameBufferSize*(window: ptr Window): tuple[w, h: int32] =
  var
    fbWidth: cint
    fbHeight: cint

  window.glGetDrawableSize(fbWidth.addr, fbHeight.addr)

  return (fbWidth.int32, fbHeight.int32)

proc size*(window: ptr Window): tuple[w, h: int32] =
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
    windowFlags = sdl.WINDOW_OPENGL or sdl.WINDOW_ALLOW_HIGHDPI or sdl.WINDOW_SHOWN
    screenWidth = 640
    screenHeight = 480

  discard sdl.init(sdl.INIT_EVERYTHING.uint32)

  discard sdl.glSetAttribute(sdl.GL_CONTEXT_PROFILE_MASK, sdl.GL_CONTEXT_PROFILE_CORE.cint)
  discard sdl.glSetAttribute(sdl.GL_CONTEXT_FLAGS, sdl.GL_CONTEXT_FORWARD_COMPATIBLE_FLAG.cint)
  discard sdl.glSetAttribute(sdl.GL_CONTEXT_MAJOR_VERSION, 3)
  discard sdl.glSetAttribute(sdl.GL_CONTEXT_MINOR_VERSION, 2)

  let window = sdl.createWindow(
    "SDL2 Test",
    sdl.WINDOWPOS_CENTERED.cint,
    sdl.WINDOWPOS_CENTERED.cint,
    screenWidth.cint, screenHeight.cint, windowFlags.uint32
  )

  let context = glCreateContext(window)

  discard sdl.glSetSwapInterval(0)

  var done = false
  var prevt: float = sdl.getTicks().float/1000.0

  glewInit()
  let vg = nanovg.newContext()
  vg.loadFont(currentSourceDir()/"resources"/"Roboto-Regular.ttf", "sans")
  vg.loadFont(currentSourceDir()/"resources"/"Roboto-Bold.ttf", "sans-bold")
  vg.loadFont(currentSourceDir()/"resources"/"fa.ttf", "fa")
  vg.loadFont(currentSourceDir()/"resources"/"entypo.ttf", "icons")

  while not done:
    let fbSize = window.frameBufferSize()

    glViewPort(0, 0, fbSize.w, fbSize.h)
    glCullFace(GL_BACK)
    glFrontFace(GL_CCW)
    glClearColor(0.3, 0.3, 0.32, 1.0)
    glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT or GL_STENCIL_BUFFER_BIT)

    vg.withFrame(window):
      vg.text("Some仮名thing is up", 100, 100, 100)
      vg.drawWindow("Title", 50, 50, 300, 400)
      vg.drawLabel("Hello!", 10, 10, 280, 20)
      vg.drawButton(ICON_TRASH, "Delete", 100, 200, 160, 28, rgba(128, 16, 8, 255))
      vg.drawButton(ICON_TRASH, "Deleter", 100, 250, 160, 28, rgba(12, 130, 80, 255))
      vg.drawButton("Testing", 100, 300, 160, 28)

      vg.render(fps, 5, 5)
      vg.render(cpuGraph, 210, 5)

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
  vg.delete()
  img.quit()
  sdl.quit()

main()