import os
import nanovg

type
  WindowConfig* = object
    cornerRadiusTopLeft*: float
    cornerRadiusTopRight*: float
    cornerRadiusBottomLeft*: float
    cornerRadiusBottomRight*: float

# const ICON_TRASH: cint = 0x0000f1f8
const ICON_TRASH* = ""
# const ICON_TRASH = "\uf1f8"
#const ICON_TRASH: cint = 0xE729

proc currentSourceDir*(): string {.inline.} =
  return currentSourcePath.parentDir()

# Config

proc drawLabel*(text: string, x, y, w, h: float) =
  nanovg.setFontSize(50.0)
  nanovg.setFont("sans")
  nanovg.setFillColor(1.0, 1.0, 1.0, 1.0)

  nanovg.textAlign("left middle")
  nanovg.text(text, x, y+h*0.5)

proc drawWindow*(title: string, x, y, w, h: float) =
  let cornerRadius = 3.0
  withState:
    nanovg.beginPath()
    nanovg.pathRoundedRect(x, y, w, h, cornerRadius)
    #nanovg.setFillColor(rgba(255,255,255,192))
    nanovg.setFillColor(rgba(28,30,34,192))
    nanovg.pathFill()

    nanovg.setFontSize(30.0)
    nanovg.setFont("sans")
    nanovg.textAlign("center middle")

    nanovg.setFontBlur(2)
    nanovg.setFillColor(rgba(0,0,0,128))
    nanovg.text(title, x+w/2, y+16+1)

    nanovg.setFontBlur(0)
    nanovg.setFillColor(rgba(220,220,220,160))
    nanovg.text(title, x+w/2,y+16)

proc isBlack*(color: Color): bool =
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
    rgba(255, 255, 255, 16),
    rgba(100, 100, 100, 16)
  )

  let color = rgba(29, 100, 210, 255)
  let shadowColor = rgba(0, 0, 0, 90)
  let highlightColor = rgba(255, 255, 255, 100)
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
    rgba(255,255,255, if isBlack(color): 16 else:32),
    rgba(0,0,0, if isBlack(color): 16 else:32)
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
  nanovg.setStrokeColor(rgba(0,0,0,48))
  nanovg.pathStroke()

  nanovg.setFontSize(20.0)
  nanovg.setFont("sans-bold")
  tb = nanovg.textBounds(text, 0.0, 0.0)
  tw = tb.horizontalAdvance

  nanovg.setFontSize(h*0.5)
  nanovg.setFont("fa")
  ib = nanovg.textBounds(preicon, 0, 0)
  iw = ib.horizontalAdvance
  iw += h*0.15

  nanovg.setFontSize(h*0.5)
  nanovg.setFont("fa")
  nanovg.setFillColor(rgba(255,255,255,96))
  nanovg.textAlign("left middle")
  nanovg.text(preicon, x+w*0.5-tw*0.5-iw*0.75, y+h*0.5)

  nanovg.setFontSize(20.0)
  nanovg.setFont("sans-bold")
  nanovg.textAlign("left middle")
  nanovg.setFillColor(rgba(0,0,0,160))
  nanovg.text(text, x+w*0.5-tw*0.5+iw*0.25, y+h*0.5-1)
  nanovg.setFillColor(rgba(255,255,255,160))
  nanovg.text(text, x+w*0.5-tw*0.5+iw*0.25, y+h*0.5)

proc glewInit*() {.header:"<GL/glew.h>".}