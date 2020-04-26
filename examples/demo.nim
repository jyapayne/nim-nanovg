import os
import nanovg
import glfw, opengl
import perf
import common

proc main =
  var c = DefaultOpenglWindowConfig
  c.version = glv32
  c.title = "Minimal Nim-GLFW example"
  c.forwardCompat = true
  c.profile = opCoreProfile
  c.debugContext = false

  let
    fps = newGraph(RenderStyle.FPS, "Frame Time")
    cpuGraph = newGraph(RenderStyle.MS, "CPU Time")


  glfw.initialize()
  var w = newWindow(c)
  swapInterval(0)
  setTime(0)

  glewInit()
  let vg = nanovg.newContext()
  vg.loadFont(currentSourceDir()/"resources/Roboto-Regular.ttf", "sans")
  vg.loadFont(currentSourceDir()/"resources/Roboto-Bold.ttf", "sans-bold")
  vg.loadFont(currentSourceDir()/"resources/fa.ttf", "fa")
  var prevt = getTime()

  while not w.shouldClose():
    let t = getTime()
    let dt = t - prevt
    prevt = t

    #let pos = w.cursorPos()
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

  w.destroy()
  vg.delete()
  glfw.terminate()

main()
