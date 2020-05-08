import sdl2/sdl2 as sdl
import sdl2/sdl2_gpu as gpu
import glew

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

template generateFbo(width, height: float, code: untyped): gpu.Image =
  let fb = createFrameBuffer(width, height, ImageFlagsGL.NO_DELETE)
  fb.binde()

  glViewPort(0, 0, width.int, height.int)
  glCullFace(GL_BACK)
  glFrontFace(GL_CCW)
  glClearColor(0.3, 0.3, 0.32, 1.0)
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT or GL_STENCIL_BUFFER_BIT)
  beginFrame(width, height, 1.0)
  code
  endFrame()
  gpu.resetRendererState()
  echo fb.texture
  let res = gpu.createImageUsingTexture(cast[TextureHandle](fb.texture), false)
  fb.delete()
  res

proc main() =
  let
    fps = newGraph(RenderStyle.FPS, "Frame Time")
    cpuGraph = newGraph(RenderStyle.MS, "CPU Time")

  discard sdl.init(sdl.INIT_EVERYTHING.uint32)
  discard sdl.glSetAttribute(sdl.GL_STENCIL_SIZE, 1)
  discard sdl.glSetAttribute(sdl.GL_CONTEXT_PROFILE_MASK, sdl.GL_CONTEXT_PROFILE_CORE.cint)
  discard sdl.glSetAttribute(sdl.GL_CONTEXT_FLAGS, sdl.GL_CONTEXT_FORWARD_COMPATIBLE_FLAG.cint)
  discard sdl.glSetAttribute(sdl.GL_CONTEXT_MAJOR_VERSION, 3)
  discard sdl.glSetAttribute(sdl.GL_CONTEXT_MINOR_VERSION, 2)
  var w, h: cint

  # let
  #   vert = gpu.loadShader(gpu.VERTEX_SHADER, currentSourceDir()/"resources/untextured.vert")
  #   frag = gpu.loadShader(gpu.FRAGMENT_SHADER, currentSourceDir()/"resources/untextured.frag")
  #   program = gpu.linkShaders(vert, frag)

  # glUseProgram(program)

  # let
  #   vertLoc = gpu.getAttributeLocation(program, "gpu_Vertex")
  #   colorLoc = gpu.getAttributeLocation(program, "gpu_Color")
  #   mvpLoc = gpu.getUniformLocation(program, "gpu_ModelViewProjectionMatrix")

  let screen = gpu.initRenderer(gpu.RENDERER_OPENGL_3, 640, 480, sdl.WINDOW_ALLOW_HIGHDPI)
  gpu.setRequiredFeatures(gpu.FEATURE_BASIC_SHADERS)


  let vg = nanovg.newContext()
  discard sdl.glSetSwapInterval(0)
  vg.loadFont(currentSourceDir()/"resources"/"Roboto-Regular.ttf", "sans")
  vg.loadFont(currentSourceDir()/"resources"/"umeboshi.ttf", "umeboshi")
  vg.loadFont(currentSourceDir()/"resources"/"Roboto-Bold.ttf", "sans-bold")
  vg.loadFont(currentSourceDir()/"resources"/"fa.ttf", "fa")
  vg.loadFont(currentSourceDir()/"resources"/"entypo.ttf", "icons")

  var done = false
  var prevt: float = sdl.getTicks().float/1000.0

  var image = gpu.loadImage(currentSourceDir()/"resources/howl.png")

  let window = sdl.getWindowFromID(screen.context.windowID)

  while not done:
    gpu.clearRGBA(screen, 0, 0, 0, 0xFF)

    # do gpu drawing

    let fbSize = window.frameBufferSize()

    glViewPort(0, 0, fbSize.w, fbSize.h)
    glCullFace(GL_BACK)
    glFrontFace(GL_CCW)
    glClearColor(0.3, 0.3, 0.32, 1.0)
    glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT or GL_STENCIL_BUFFER_BIT)

    gpu.blit(image, nil, screen, 400, 100)

    gpu.flushBlitBuffer()

    withFrame(vg, window):
      vg.setFont("umeboshi")
      vg.text("Some仮名thing is up", 100, 100, 100)
      vg.drawWindow("Title", 50, 50, 300, 400)
      vg.drawLabel("Hello!", 10, 10, 500, 20)
      vg.drawButton(ICON_TRASH, "Delete", 100, 200, 160, 28, rgba(128, 16, 8, 255))
      vg.drawButton(ICON_TRASH, "Deleter", 100, 250, 160, 28, rgba(12, 130, 80, 255))
      vg.drawButton("Testing", 100, 300, 160, 28)
      vg.drawSearchBox("Search...", 60, 400, 280, 25)

    gpu.resetRendererState()

    vg.render(fps, 5, 5)
    vg.render(cpuGraph, 210, 5)


    gpu.flip(screen)

    let t: float = sdl.getTicks().float/1000.0
    let dt = t - prevt
    prevt = t

    let cpuTime: float = sdl.getTicks().float/1000.0 - t

    fps.update(dt)
    cpuGraph.update(cpuTime)

    done = events()
  gpu.freeImage(image)
  vg.delete()
  gpu.quit()

main()