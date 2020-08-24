import os
import nanovg
import glfw, glew
import perf
import common

proc frameBufferSize*(window: ptr Window): tuple[w, h: int32] =
  var fbWidth, fbHeight: cint
  window.getFramebufferSize(fbWidth.addr, fbHeight.addr)

  return (w: fbWidth, h: fbHeight)

proc size*(window: ptr Window): tuple[w, h: int32] =
  var width, height: cint
  window.getWindowSize(width.addr, height.addr)

  return (w: width, h: height)

proc main =

  let
    fps = newGraph(RenderStyle.FPS, "Frame Time")
    cpuGraph = newGraph(RenderStyle.MS, "CPU Time")

  discard glfw.init()

  initHint(CONTEXT_VERSION_MAJOR, 3)
  initHint(CONTEXT_VERSION_MINOR, 2)
  when defined(macosx):
    initHint(OPENGL_FORWARD_COMPAT, 1)
    initHint(OPENGL_PROFILE, OPENGL_COMPAT_PROFILE)
  else:
    initHint(OPENGL_PROFILE, OPENGL_CORE_PROFILE)

  var w = createWindow(800, 600, "Minimal Nim-GLFW Example", nil, nil)
  w.makeContextCurrent()
  swapInterval(0)
  setTime(0)

  discard glew.init()
  let vg = nanovg.newContext()
  vg.loadFont(currentSourceDir()/"resources/Roboto-Regular.ttf", "sans")
  vg.loadFont(currentSourceDir()/"resources/Roboto-Bold.ttf", "sans-bold")
  vg.loadFont(currentSourceDir()/"resources/fa.ttf", "fa")
  var prevt = getTime()

  while not w.windowShouldClose().bool:
    let t = getTime()
    let dt = t - prevt
    prevt = t

    let fbSize = w.frameBufferSize()

    glViewPort(0, 0, fbSize.w, fbSize.h)

    glCullFace(GL_BACK)
    glFrontFace(GL_CCW)
    glClearColor(0.3, 0.3, 0.32, 1.0)
    glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT or GL_STENCIL_BUFFER_BIT)

    vg.withFrame(w):
      let x = vg.glyphPositions("Some仮名thing is up", 0, 0)
      vg.drawWindow("Title", 50, 50, 300, 400)
      vg.drawLabel("Hello!", 10, 10, 280, 20)
      vg.drawButton(ICON_TRASH, "Delete", 100, 200, 160, 28, rgba(128, 16, 8, 255))
      vg.drawButton(ICON_TRASH, "Deleter", 100, 250, 160, 28, rgba(12, 130, 80, 255))
      vg.drawButton("Testing", 100, 300, 160, 28)

      vg.render(fps, 5, 5)
      vg.render(cpuGraph, 210, 5)

    w.swapBuffers()
    pollEvents()

    let cpuTime = glfw.getTime() - t

    fps.update(dt)
    cpuGraph.update(cpuTime)
    waitEvents()

  w.destroyWindow()
  vg.delete()
  glfw.terminate()

main()
