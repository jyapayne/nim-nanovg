import os
import nanovg

type
  WindowConfig* = object
    cornerRadiusTopLeft*: float
    cornerRadiusTopRight*: float
    cornerRadiusBottomLeft*: float
    cornerRadiusBottomRight*: float

const ICON_TRASH* = ""
const ICON_SEARCH* = "🔍"
const ICON_CIRCLED_CROSS* = "✖"
const ICON_CHEVRON_RIGHT* = "\uE75E"
const ICON_CHECK* = "✓"
const ICON_LOGIN* = "\uE740"

proc currentSourceDir*(): string {.inline.} =
  return currentSourcePath.parentDir()

# Config

proc drawLabel*(vg: Context, text: string, x, y, w, h: float, font="sans") =
  vg.setFontSize(50.0)
  vg.setFont(font)
  vg.setFillColor(1.0, 1.0, 1.0, 1.0)

  vg.textAlign("left middle")
  vg.text(text, x, y+h*0.5)

proc drawWindow*(vg: Context, title: string, x, y, w, h: float, font="sans") =
  let cornerRadius = 3.0
  withState(vg):
    vg.beginPath()
    vg.pathRoundedRect(x, y, w, h, cornerRadius)
    #vg.setFillColor(rgba(255,255,255,192))
    vg.setFillColor(rgba(28,30,34,192))
    vg.pathFill()

    vg.setFontSize(30.0)
    vg.setFont(font)
    vg.textAlign("center middle")

    vg.setFontBlur(2)
    vg.setFillColor(rgba(0,0,0,128))
    vg.text(title, x+w/2, y+16+1)

    vg.setFontBlur(0)
    vg.setFillColor(rgba(220,220,220,160))
    vg.text(title, x+w/2,y+16)

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

proc drawButton*(vg: Context, text: string, x, y, width, height: float) =
  let bg = vg.linearGradient(
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
    vg.beginPath()
    vg.pathRoundedRect(x+1+shadowOffset, y+1+shadowOffset, width-2, height-2, radius)
    vg.setFillColor(shadowColor)
    vg.pathFill()

  vg.beginPath()
  vg.pathRoundedRect(x+1, y+1, width-2, height-2, radius)
  vg.setFillColor(color)
  vg.pathFill()

  vg.setFillPaint(bg)
  vg.pathFill()

  vg.beginPath()
  vg.pathMoveTo(x+radius, y+lightWidth+1)
  vg.setStrokeWidth(lightWidth)
  vg.setStrokeColor(highlightColor)
  vg.pathLineTo(x+width-(radius), y+lightWidth+1)
  vg.pathStroke()


proc drawButton*(vg: Context, preicon: string, text: string, x, y, w, h: float, color: Color) =

  var
    bg: Paint
    cornerRadius = 4.0
    tb: TextBounds
    ib: TextBounds
    tw = 0.0
    iw = 0.0

  bg = vg.linearGradient(
    x,y,x,y+h,
    rgba(255,255,255, if isBlack(color): 16 else:32),
    rgba(0,0,0, if isBlack(color): 16 else:32)
  )

  vg.beginPath()
  vg.pathRoundedRect(x+1, y+1, w-2, h-2, cornerRadius-1)

  if not isBlack(color):
    vg.setFillColor(color)
    vg.pathFill()

  vg.setFillPaint(bg)
  vg.pathFill()

  vg.beginPath()
  vg.pathRoundedRect(x+0.5, y+0.5, w-1, h-1, cornerRadius-0.5)
  vg.setStrokeColor(rgba(0,0,0,48))
  vg.pathStroke()

  vg.setFontSize(20.0)
  vg.setFont("sans-bold")
  tb = vg.textBounds(text, 0.0, 0.0)
  tw = tb.horizontalAdvance

  vg.setFontSize(h*0.5)
  vg.setFont("fa")
  ib = vg.textBounds(preicon, 0, 0)
  iw = ib.horizontalAdvance
  iw += h*0.15

  vg.setFontSize(h*0.5)
  vg.setFont("fa")
  vg.setFillColor(rgba(255,255,255,96))
  vg.textAlign("left middle")
  vg.text(preicon, x+w*0.5-tw*0.5-iw*0.75, y+h*0.5)

  vg.setFontSize(20.0)
  vg.setFont("sans-bold")
  vg.textAlign("left middle")
  vg.setFillColor(rgba(0,0,0,160))
  vg.text(text, x+w*0.5-tw*0.5+iw*0.25, y+h*0.5-1)
  vg.setFillColor(rgba(255,255,255,160))
  vg.text(text, x+w*0.5-tw*0.5+iw*0.25, y+h*0.5)