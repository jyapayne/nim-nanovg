import os
import nanovg
import glfw, opengl
import perf
import common

proc main =
  glfw.initialize()
  var c = DefaultOpenglWindowConfig
  c.version = glv32
  c.title = "Minimal Nim-GLFW example"
  c.forwardCompat = true
  c.profile = opCompatProfile
  c.debugContext = false

  let
    fps = newGraph(RenderStyle.FPS, "Frame Time")
    cpuGraph = newGraph(RenderStyle.MS, "CPU Time")


  var w = newWindow(c)
  swapInterval(0)
  setTime(0)

  glewInit()
  nanovg.init()
  nanovg.loadFont(currentSourceDir()/"resources/Roboto-Regular.ttf", "sans")
  nanovg.loadFont(currentSourceDir()/"resources/Roboto-Bold.ttf", "sans-bold")
  nanovg.loadFont(currentSourceDir()/"resources/fa.ttf", "fa")
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

    withFrame(w):
      let x = glyphPositions("Some仮名thing is up", 0, 0)
      drawWindow("Title", 50, 50, 300, 400)
      drawLabel("Hello!", 10, 10, 280, 20)
      drawButton(ICON_TRASH, "Delete", 100, 200, 160, 28, RGBA(128, 16, 8, 255))
      drawButton(ICON_TRASH, "Deleter", 100, 250, 160, 28, RGBA(12, 130, 80, 255))
      drawButton("Testing", 100, 300, 160, 28)

      fps.render(5, 5)
      cpuGraph.render(210, 5)

    w.swapBuffers()
    pollEvents()

    let cpuTime = glfw.getTime() - t

    fps.update(dt)
    cpuGraph.update(cpuTime)
    waitEvents()

  w.destroy()
  glfw.terminate()

main()
