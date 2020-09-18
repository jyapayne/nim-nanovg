import options
import os
import nanovg
import icons

type
  StyleConfig* = ref object
    cornerRadiusTopLeft*: float
    cornerRadiusTopRight*: float
    cornerRadiusBottomLeft*: float
    cornerRadiusBottomRight*: float

    paddingLeft*: float
    paddingRight*: float
    paddingBottom*: float
    paddingTop*: float

    icon*: Option[Icon]
    iconFont*: string

    fontBlur*: float
    font*: string
    fontSize*: float
    fontColor*: Color
    hasFontShadow*: bool
    fontShadowColor*: Color
    fontShadowXOffset*: float
    fontShadowYOffset*: float
    textAlignments*: seq[Alignment]

    hasShadow*: bool
    shadowColor*: Color
    shadowXOffset*: float
    shadowYOffset*: float

    highlightColor*: Color
    highlightWidth*: float

    fillColor*: Color
    gradientStartColor*: Color
    gradientEndColor*: Color

  WindowConfig* = object
    cornerRadiusTopLeft*: float
    cornerRadiusTopRight*: float
    cornerRadiusBottomLeft*: float
    cornerRadiusBottomRight*: float

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

    vg.setFontBlur(0)
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

let Colors: tuple[Red, Green, Blue, Yellow, Orange, Purple, White, Grey, Black: Color] =
  (
    Red: rgb(231, 64, 74),
    Green: rgb(40, 184, 115),
    Blue: rgb(43, 183, 209),
    Yellow: rgb(243, 203, 57),
    Orange: rgb(255, 130, 76),
    Purple: rgb(97, 18, 204),
    White: rgb(255, 255, 255),
    Grey: rgb(129, 110, 96),
    Black: rgb(0, 0, 0)
  )

proc defaultButtonStyle(fillColor: Color): StyleConfig {.inline.} =
  StyleConfig(
    cornerRadiusTopLeft: 3.0,
    cornerRadiusTopRight: 3.0,
    cornerRadiusBottomLeft: 3.0,
    cornerRadiusBottomRight: 3.0,
    paddingLeft: 10.0,
    paddingRight: 10.0,
    paddingTop: 5.0,
    paddingBottom: 5.0,
    iconFont: "fa",
    fontBlur: 0.0,
    font: "sans-bold",
    fontSize: 20.0,
    fontColor: rgba(255, 255, 255, 160),
    hasFontShadow: true,
    fontShadowColor: rgba(0, 0, 0, 160),
    fontShadowXOffset: 0.0,
    fontShadowYOffset: 1.0,
    highlightColor: rgba(255, 255, 255, 100),
    highlightWidth: 0.5,
    hasShadow: true,
    shadowColor: rgba(0, 0, 0, 90),
    shadowXOffset: 3.0,
    shadowYOffset: 3.0,
    gradientStartColor: rgba(255, 255, 255, if fillColor.isBlack: 16 else: 32),
    gradientEndColor: rgba(0, 0, 0, if fillColor.isBlack: 16 else: 32),
    textAlignments: @[Alignment.Center, Alignment.Middle]
  )

let DefaultButtonStyles: tuple[Red, Green, Blue, Yellow, Orange, Purple, White, Grey, Black: StyleConfig] =
  (
    Red: defaultButtonStyle(Colors.Red),
    Green: defaultButtonStyle(Colors.Green),
    Blue: defaultButtonStyle(Colors.Blue),
    Yellow: defaultButtonStyle(Colors.Yellow),
    Orange: defaultButtonStyle(Colors.Orange),
    Purple: defaultButtonStyle(Colors.Purple),
    White: defaultButtonStyle(Colors.White),
    Grey: defaultButtonStyle(Colors.Grey),
    Black: defaultButtonStyle(Colors.Black)
  )

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

proc drawButton*(vg: Context, text: string, x, y: float, style: StyleConfig = DefaultButtonStyles.Blue) =

  vg.setFontSize(style.fontSize)
  vg.setFont(style.font)
  let textBounds = vg.textBounds(text, 0.0, 0.0)
  let textWidth = textBounds.horizontalAdvance
  let height = (textBounds.bounds.ymax - textBounds.bounds.ymin) + style.paddingTop + style.paddingBottom

  vg.setFontSize(height * 0.5)
  vg.setFont(style.iconFont)
  let iconBounds = vg.textBounds($style.icon, 0, 0)
  var iconWidth = iconBounds.horizontalAdvance
  # iconWidth += height*0.15

  let width = textWidth + iconWidth + style.paddingLeft + style.paddingRight

  let bg = vg.linearGradient(
    x, y, x, y+height,
    style.gradientStartColor,
    style.gradientEndColor
  )

  let color = style.fillColor
  let shadowColor = style.shadowColor
  let lightWidth = style.highlightWidth

  if style.hasShadow:
    vg.beginPath()
    vg.pathRoundedRect(
      x+1+style.shadowXOffset,
      y+1+style.shadowYOffset,
      width-2, height-2,
      style.cornerRadiusTopLeft, style.cornerRadiusTopRight,
      style.cornerRadiusBottomRight, style.cornerRadiusBottomLeft
    )
    vg.setFillColor(style.shadowColor)
    vg.pathFill()

  vg.beginPath()
  vg.pathRoundedRect(
    x+1, y+1, width-2, height-2,
    style.cornerRadiusTopLeft, style.cornerRadiusTopRight,
    style.cornerRadiusBottomRight, style.cornerRadiusBottomLeft
  )
  vg.setFillColor(style.fillColor)
  vg.pathFill()

  vg.setFillPaint(bg)
  vg.pathFill()

  vg.beginPath()
  vg.pathMoveTo(x+style.cornerRadiusBottomLeft, y+lightWidth+1)
  vg.setStrokeWidth(lightWidth)
  vg.setStrokeColor(style.highlightColor)
  vg.pathLineTo(x+width-(style.cornerRadiusBottomLeft), y+lightWidth+1)
  vg.pathStroke()

  vg.setFont(style.font)
  vg.textAlign(style.textAlignments)
  vg.setFillColor(style.fontColor)
  vg.text(text, x + width, y + height - 1)

proc drawButton*(vg: Context, preicon: Icon, text: string, x, y, w, h: float, color: Color) =

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
  ib = vg.textBounds($preicon, 0, 0)
  iw = ib.horizontalAdvance
  iw += h*0.15

  vg.setFontSize(h*0.5)
  vg.setFont("fa")
  vg.setFillColor(rgba(255,255,255,96))
  vg.textAlign("left middle")
  vg.text($preicon, x+w*0.5-tw*0.5-iw*0.75, y+h*0.5)

  vg.setFontSize(20.0)
  vg.setFont("sans-bold")
  vg.textAlign("left middle")
  vg.setFillColor(rgba(0,0,0,160))
  vg.text(text, x+w*0.5-tw*0.5+iw*0.25, y+h*0.5-1)
  vg.setFillColor(rgba(255,255,255,160))
  vg.text(text, x+w*0.5-tw*0.5+iw*0.25, y+h*0.5)

proc drawSearchBox*(vg: Context, text: string, x, y, w, h: float) =
  let cornerRadius = h/2 - 1

  let bg = vg.boxGradient(x, y+1.5, w, h, h/2, 5, rgba(0, 0, 0, 16), rgba(0, 0, 0, 92))
  vg.beginPath()
  vg.pathRoundedRect(x,y, w,h, cornerRadius)
  vg.setFillPaint(bg)
  vg.pathFill()

  vg.setFontSize(h*1.3)
  vg.setFont("icons")
  vg.setFillColor(rgba(255,255,255,64))
  vg.textAlign("center middle")
  vg.text($Icon.Search, x+h*0.55f, y+h*0.55f)

  vg.setFontSize(20.0f)
  vg.setFont("sans")
  vg.setFillColor(rgba(255,255,255,32))

  vg.textAlign("left middle")
  vg.text(text, x+h*1.05f,y+h*0.5f)

  vg.setFontSize(h*1.3f)
  vg.setFont("icons")
  vg.setFillColor(rgba(255,255,255,32))
  vg.textAlign("center middle")
  vg.text($Icon.TimesCircle, x+w-h*0.55f, y+h*0.55f)
