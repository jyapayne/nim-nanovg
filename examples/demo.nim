import os
import nanovg
import glfw, opengl
import perf

type
  WindowConfig = object
    cornerRadiusTopLeft: float
    cornerRadiusTopRight: float
    cornerRadiusBottomLeft: float
    cornerRadiusBottomRight: float

# const ICON_TRASH: cint = 0x0000f1f8
const ICON_TRASH = ""
# const ICON_TRASH = "\uf1f8"
#const ICON_TRASH: cint = 0xE729

proc currentSourceDir(): string {.inline.} =
  return currentSourcePath.parentDir()

# Config

proc drawLabel(text: string, x, y, w, h: float) =
  nanovg.setFontSize(50.0)
  nanovg.setFont("sans")
  nanovg.setFillColor(1.0, 1.0, 1.0, 1.0)

  nanovg.textAlign("left middle")
  nanovg.text(x, y+h*0.5, text)

proc drawWindow(title: string, x, y, w, h: float) =
  let cornerRadius = 3.0
  withState:
    nanovg.beginPath()
    nanovg.pathRoundedRect(x, y, w, h, cornerRadius)
    #nanovg.setFillColor(RGBA(255,255,255,192))
    nanovg.setFillColor(RGBA(28,30,34,192))
    nanovg.pathFill()

    nanovg.setFontSize(30.0)
    nanovg.setFont("sans")
    nanovg.textAlign("center middle")

    nanovg.setFontBlur(2)
    nanovg.setFillColor(RGBA(0,0,0,128))
    nanovg.text(x+w/2, y+16+1, title)

    nanovg.setFontBlur(0)
    nanovg.setFillColor(RGBA(220,220,220,160))
    nanovg.text(x+w/2,y+16, title)

proc isBlack(color: Color): bool =
  result = true

  for n, v in color.fieldPairs:
    if v != 0:
      return false

proc cpToUtf8*(code: int): string =
  var n = 0
  var cp = code

  if cp < 0x80: n = 1
  elif cp < 0x800: n = 2
  elif cp < 0x10000: n = 3
  elif cp < 0x200000: n = 4
  elif cp < 0x4000000: n = 5
  elif cp <= 0x7fffffff: n = 6

  var res = newStringOfCap(n)
  res.setLen(n)

  if n >= 6:
    res[5] = char(0x80 or (cp and 0x3f))
    cp = cp shr 6
    cp = cp or 0x4000000
  if n >= 5:
    res[4] = char(0x80 or (cp and 0x3f))
    cp = cp shr 6
    cp = cp or 0x200000
  if n >= 4:
    res[3] = char(0x80 or (cp and 0x3f))
    cp = cp shr 6
    cp = cp or 0x10000
  if n >= 3:
    res[2] = char(0x80 or (cp and 0x3f))
    cp = cp shr 6
    cp = cp or 0x800
  if n >= 2:
    res[1] = char(0x80 or (cp and 0x3f))
    cp = cp shr 6
    cp = cp or 0xc0
  if n >= 1:
    res[0] = char(cp)

  return res

proc drawButton*(text: string, x, y, width, height: float) =
  let bg = linearGradient(
    x, y, x, y+height,
    RGBA(255, 255, 255, 16),
    RGBA(100, 100, 100, 16)
  )

  let color = RGBA(29, 100, 210, 255)
  let shadowColor = RGBA(0, 0, 0, 90)
  let highlightColor = RGBA(255, 255, 255, 100)
  let radius = 3.0
  let lightWidth = 0.5
  let shadowOffset = 3.0
  let drawShadow = true

  if drawShadow:
    nanovg.beginPath()
    nanovg.pathRoundedRect(x+1+shadowOffset, y+1+shadowOffset, width-2, height-2, radius)
    nanovg.setFillColor(shadowColor)
    nanovg.pathFill()

  nanovg.beginPath()
  nanovg.pathRoundedRect(x+1, y+1, width-2, height-2, radius)
  nanovg.setFillColor(color)
  nanovg.pathFill()

  nanovg.setFillPaint(bg)
  nanovg.pathFill()

  nanovg.beginPath()
  nanovg.pathMoveTo(x+radius, y+lightWidth+1)
  nanovg.setStrokeWidth(lightWidth)
  nanovg.setStrokeColor(highlightColor)
  nanovg.pathLineTo(x+width-(radius), y+lightWidth+1)
  nanovg.pathStroke()


proc drawButton*(preicon: string, text: string, x, y, w, h: float, color: Color) =

  var
    bg: Paint
    cornerRadius = 4.0
    tb: TextBounds
    ib: TextBounds
    tw = 0.0
    iw = 0.0

  bg = nanovg.linearGradient(
    x,y,x,y+h,
    RGBA(255,255,255, if isBlack(color): 16 else:32),
    RGBA(0,0,0, if isBlack(color): 16 else:32)
  )

  nanovg.beginPath()
  nanovg.pathRoundedRect(x+1, y+1, w-2, h-2, cornerRadius-1)

  if not isBlack(color):
    nanovg.setFillColor(color)
    nanovg.pathFill()

  nanovg.setFillPaint(bg)
  nanovg.pathFill()

  nanovg.beginPath()
  nanovg.pathRoundedRect(x+0.5, y+0.5, w-1, h-1, cornerRadius-0.5)
  nanovg.setStrokeColor(RGBA(0,0,0,48))
  nanovg.pathStroke()

  nanovg.setFontSize(20.0)
  nanovg.setFont("sans-bold")
  tb = nanovg.textBounds(0.0, 0.0, text)
  tw = tb.horizontalAdvance

  nanovg.setFontSize(h*0.5)
  nanovg.setFont("fa")
  ib = nanovg.textBounds(0,0, preicon)
  iw = ib.horizontalAdvance
  iw += h*0.15

  nanovg.setFontSize(h*0.5)
  nanovg.setFont("fa")
  nanovg.setFillColor(RGBA(255,255,255,96))
  nanovg.textAlign("left middle")
  nanovg.text(x+w*0.5-tw*0.5-iw*0.75, y+h*0.5, preicon)

  nanovg.setFontSize(20.0)
  nanovg.setFont("sans-bold")
  nanovg.textAlign("left middle")
  nanovg.setFillColor(RGBA(0,0,0,160))
  nanovg.text(x+w*0.5-tw*0.5+iw*0.25, y+h*0.5-1, text)
  nanovg.setFillColor(RGBA(255,255,255,160))
  nanovg.text(x+w*0.5-tw*0.5+iw*0.25, y+h*0.5, text)

proc main =
  glfw.initialize()

  var c = DefaultOpenglWindowConfig
  c.version = glv32
  c.title = "Minimal Nim-GLFW example"
  c.forwardCompat = true
  c.profile = opCoreProfile
  c.debugContext = false

  let
    fps = newGraph(RenderStyle.FPS, "Frame Time")
    cpuGraph = newGraph(RenderStyle.MS, "CPU Time")


  var w = newWindow(c)
  nanovg.init()
  nanovg.loadFont(currentSourceDir()/"resources/Roboto-Regular.ttf", "sans")
  nanovg.loadFont(currentSourceDir()/"resources/Roboto-Bold.ttf", "sans-bold")
  nanovg.loadFont(currentSourceDir()/"resources/fa.ttf", "fa")
  nanovg.loadFont(currentSourceDir()/"resources/entypo.ttf", "icons")
  swapInterval(0)
  setTime(0)

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
