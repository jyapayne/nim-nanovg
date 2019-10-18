import macros
import sequtils
import typetraits
import strutils
import strformat
import nanovg/wrapper

converter intToCuchar*(source: uint8 | int): cuchar =
  return source.cuchar

export HSL
export HSLA
export RGBA
export RGBAf
export RGB
export RGBf
export LerpRGBA
export TransRGBA
export TransRGBAf

#{.experimental: "dynamicBindSym".}

type
  FontLoadError* = object of Exception
  ImageLoadError* = object of Exception
  ContextInitError* = object of Exception
  Context = ptr NVGContext

  Alignment* {.size: sizeof(cint), pure.} = enum
    NONE = 0
    # Horizontal
    LEFT = NVG_ALIGN_LEFT
    CENTER = NVG_ALIGN_CENTER
    RIGHT = NVG_ALIGN_RIGHT

    # Vertical
    TOP = NVG_ALIGN_TOP
    MIDDLE = NVG_ALIGN_MIDDLE
    BOTTOM = NVG_ALIGN_BOTTOM
    BASELINE = NVG_ALIGN_BASELINE # Default

  LineCap* {.size: sizeof(cint), pure.} = enum
    BUTT = NVG_BUTT
    ROUND = NVG_ROUND
    SQUARE = NVG_SQUARE
    BEVEL = NVG_BEVEL
    MITER = NVG_MITER

  LineJoin* {.size: sizeof(cint), pure.} = enum
    ROUND = NVG_ROUND
    BEVEL = NVG_BEVEL
    MITER = NVG_MITER

  CompositeOperation* {.size: sizeof(cint), pure.} = enum
    SOURCE_OVER, SOURCE_IN, SOURCE_OUT, ATOP, DESTINATION_OVER,
    DESTINATION_IN, DESTINATION_OUT, DESTINATION_ATOP, LIGHTER,
    COPY, XOR

  BlendFactor* {.size: sizeof(cint), pure.} = enum
    ZERO = NVG_ZERO, ONE = NVG_ONE, SRC_COLOR = NVG_SRC_COLOR,
    ONE_MINUS_SRC_COLOR = NVG_ONE_MINUS_SRC_COLOR, DST_COLOR = NVG_DST_COLOR,
    ONE_MINUS_DST_COLOR = NVG_ONE_MINUS_DST_COLOR, SRC_ALPHA = NVG_SRC_ALPHA,
    ONE_MINUS_SRC_ALPHA = NVG_ONE_MINUS_SRC_ALPHA, DST_ALPHA = NVG_DST_ALPHA,
    ONE_MINUS_DST_ALPHA = NVG_ONE_MINUS_DST_ALPHA, SRC_ALPHA_SATURATE = NVG_SRC_ALPHA_SATURATE

  Bounds* = tuple[xmin, ymin, xmax, ymax: float]

  TextBounds* = tuple[horizontalAdvance: float, bounds: Bounds]

  Size* = tuple[width, height: int]

  GlyphPosition* = object
    glyph: string
    x, y: float
    minX, maxX: float
    height: float

  Paint* = NVGPaint
  Color* = NVGColor
  Image* = cint
  Font* = cint

  Winding* {.size: sizeof(cint), pure.} = enum
    CCW = NVG_CCW
    CW = NVG_CW

  Solidity* {.size: sizeof(cint), pure.} = enum
    SOLID = NVG_SOLID
    HOLE = NVG_HOLE

  TextMetrics* = tuple[ascender, descender, lineHeight: float]

  TextRow* = tuple[x, y, minX, maxX, height: float]

  ImageFlags* {.size: sizeof(cint).} = enum
    NONE = 0,
    GENERATE_MIPMAPS = NVG_IMAGE_GENERATE_MIPMAPS, ##  Generate mipmaps during creation of the image.
    REPEATX = NVG_IMAGE_REPEATX,  ##  Repeat image in X direction.
    REPEATY = NVG_IMAGE_REPEATY,  ##  Repeat image in Y direction.
    FLIPY = NVG_IMAGE_FLIPY,    ##  Flips (inverses) image in Y direction when rendered.
    PREMULTIPLIED = NVG_IMAGE_PREMULTIPLIED, ##  Image data has premultiplied alpha.
    NEAREST = NVG_IMAGE_NEAREST   ##  Image interpolation is Nearest instead Linear

  View* = concept v
    v.size() is tuple[w, h: int32]
    v.frameBufferSize() is tuple[w, h: int32]

proc width*(pos: GlyphPosition): float =
  return pos.maxX - pos.minX

proc createExpr*(ty, name: string, descriptor: NimNode, args: varargs[NimNode]): NimNode =
  let tokens = ($descriptor).toUpper().split(" ").map(
    proc(s: string): string =
      return ty & "." & s
  )

  let argTokens = args.map(
    proc(arg: NimNode): string =
      $arg.toStrLit()
  )

  let allTokens = argTokens.concat(tokens)

  let newExpr = name & "(" & allTokens.join(",") & ")"

  result = parseStmt(newExpr)


template reduce[T](elements: openArray[T], op: untyped): untyped =
  var res = T.NONE

  for element in elements:
    res = op(res, element)

  res

proc createContext(antialias = true, stencilStrokes = true, debugChecks = false): Context =
  var flags: cint

  if antialias:
    flags = flags or NVG_ANTIALIAS.cint
  if stencilStrokes:
    flags = flags or NVG_STENCIL_STROKES.cint
  if debugChecks:
    flags = flags or NVG_DEBUG.cint

  result = CreateGL3(flags)

  if result.isNil:
    raise newException(ContextInitError, "Could not initialize graphics context")

var context: Context

proc init*() =
  context = createContext()

proc loadFont*(path, name: string): Font {.discardable.} =
  ## Load the font from `path` and give it a `name` that can be used to reference it.
  result = context.CreateFont(name, path)

  if result == -1:
    raise newException(FontLoadError, fmt"Could not load font {name}.")

proc loadFontMem*(data: openArray[uint8], name: string, freeDataAutomatically = true): Font {.discardable.} =
  ## Load the font from `path` and give it a `name` that can be used to reference it.
  result = context.CreateFontMem(name, cast[ptr cuchar](data[0].unsafeAddr), data.len.cint, freeDataAutomatically.cint)

  if result == -1:
    raise newException(FontLoadError, fmt"Could not load font {name}.")

proc findFont*(name: string): Font =
  return context.FindFont(name)

proc setFallbackFont*(baseFont, fallbackFont: string): Font =
  return context.AddFallbackFont(baseFont, fallbackFont)

proc setFallbackFont*(baseFont, fallbackFont: Font): Font =
  return context.AddFallbackFontId(baseFont, fallbackFont)

proc setFont*(font: Font) =
  context.FontFaceId(font)

proc setFont*(name: string) =
  context.FontFace(name)

proc setFontSize*(size: float) =
  context.FontSize(size)

proc setFontBlur*(blur: float) =
  context.FontBlur(blur)

proc setTextLetterSpacing*(spacing: float) =
  context.TextLetterSpacing(spacing)

proc setTextLineHeight*(lineHeight: float) =
  context.TextLineHeight(lineHeight)

proc `or`(align1: Alignment, align2: Alignment): Alignment =
  return (align1.cint or align2.cint).Alignment

proc textAlign*(alignments: varargs[Alignment]) =
  var alignment = reduce(alignments, `or`)

  context.TextAlign(alignment.cint)

macro textAlign*(descriptor: string) =
  result = createExpr("Alignment", "textAlign", descriptor)

proc textBounds*(x, y: float, text: string): TextBounds =
  var res: array[4, cfloat]
  let horizonalAdvance = context.TextBounds(x, y, text, nil, res[0].addr)

  let bounds: Bounds = (res[0].float, res[1].float, res[2].float, res[3].float)
  return (horizonalAdvance.float, bounds)

proc text*(x, y: float, content: string) =
  discard context.Text(x, y, content, nil)

proc textBoxBounds*(x, y, breakRowWidth: float, text: string): Bounds =
  var res: array[4, cfloat]
  context.TextBoxBounds(x, y, breakRowWidth, text, nil, res[0].addr)

  return (res[0].float, res[1].float, res[2].float, res[3].float)

proc textBox*(x, y, breakRowWidth: float, content: string) =
  context.TextBox(x, y, breakRowWidth, content, nil)

proc textMetrics*(): TextMetrics =
  var
    ascender, descender, lineHeight: cfloat

  context.TextMetrics(ascender.addr, descender.addr, lineHeight.addr)

  return (ascender.float, descender.float, lineHeight.float)

# TODO Continue with TextGlyphPos
proc glyphPositions*(text: string, x, y: float): seq[GlyphPosition] =
  const maxPositions = 100
  var
    positions: array[maxPositions, NVGglyphPosition]
    numGlyphs = 0
    bytesProcessed = 0
    lastX = x
    strIndex = 0
    lineHeight = textMetrics().lineHeight

  result = newSeqOfCap[GlyphPosition](maxPositions)

  while (strIndex < text.len):
    numGlyphs = context.TextGlyphPositions(
      lastX, y, cast[cstring](text[strIndex].unsafeAddr), nil,
      positions[0].addr, maxPositions
    )

    for i in 0..<numGlyphs:
      var byteWidth = 1
      let
        retPos = positions[i]
      if i < (numGlyphs - 1):
        let
          nextPos = positions[i+1]
          nextBaddr = cast[ByteAddress](nextPos.str[0].unsafeAddr)
          baddr = cast[ByteAddress](retPos.str[0].unsafeAddr)

        byteWidth = nextBaddr - baddr
      elif i == (numGlyphs - 1):
        byteWidth = len(text) - bytesProcessed

      var glyph = newStringOfCap(byteWidth)
      for j in 0..<byteWidth:
        glyph.add(retPos.str[j])

      let pos = GlyphPosition(
        glyph: glyph, x: retPos.x, y: y, minX: retPos.minX, maxX: retPos.maxX,
        height: lineHeight
      )

      result.add(pos)
      bytesProcessed += byteWidth

    lastX = positions[numGlyphs-1].x
    strIndex += maxPositions

proc glyphPositions*(text: string, x, y, maxWidth: float): seq[GlyphPosition] =
  const maxRows = 100
  var
    rows: array[maxRows, NVGtextRow]

  

proc beginFrame*(width, height, pxRatio: float) =
  context.BeginFrame(width, height, pxRatio)

proc cancelFrame*() =
  context.CancelFrame()

proc endFrame*() =
  context.EndFrame()

proc globalCompositeOperation*(op: CompositeOperation) =
  context.GlobalCompositeOperation(op.cint)

proc globalCompositeBlendFunc*(sourceFactor, destFactor: BlendFactor) =
  context.GlobalCompositeBlendFunc(sourceFactor.cint, destFactor.cint)

proc globalCompositeBlendFuncSeparate*(srcRGB, destRGB, srcAlpha, destAlpha: BlendFactor) =
  context.GlobalCompositeBlendFuncSeparate(srcRGB.cint, destRGB.cint, srcAlpha.cint, destAlpha.cint)

template withFrame*(window: View, code: untyped) =
  let
    winSize = window.size()
    fbSize = window.frameBufferSize()
    pxRatio = cfloat(fbSize.w) / cfloat(winSize.w)

  beginFrame(winSize.w.cfloat, winSize.h.cfloat, pxRatio)
  code
  endFrame()


#
# State Handling
#
# NanoVG contains state which represents how paths will be rendered.
# The state contains transform, fill and stroke styles, text and font styles,
# and scissor clipping.
#
proc saveState*() =
  ## Pushes and saves the current render state into a state stack.
  ## A matching restoreState() must be used to restore the state.
  context.Save()

proc restoreState*() =
  ## Pops and restores current render state.
  context.Restore()

proc resetState*() =
  ## Resets current render state to default values. Does not affect the render state stack.
  context.Reset()

template withState*(code: untyped) =
  saveState()
  try:
    code
  except:
    raise
  finally:
    restoreState()

proc setShapeAntialias*(enabled = true) =
  context.ShapeAntiAlias(enabled.cint)

proc setStrokeColor*(color: Color) =
  context.StrokeColor(color)

proc setStrokePaint*(paint: Paint) =
  context.StrokePaint(paint)

proc setFillPaint*(paint: Paint) =
  context.FillPaint(paint)

proc setFillColor*(color: Color) =
  context.FillColor(color)

proc setFillColor*(r, g, b: uint8) =
  context.FillColor(RGB(r.cuchar, g.cuchar, b.cuchar))

proc setFillColor*(r, g, b: float) =
  context.FillColor(RGBf(r, g, b))

proc setFillColor*(r, g, b, a: float) =
  context.FillColor(RGBAf(r, g, b, a))

proc setFillColor*(r, g, b, a: uint8) =
  context.FillColor(RGBA(r.cuchar, g.cuchar, b.cuchar, a.cuchar))

proc setMiterLimit*(limit: float) =
  context.MiterLimit(limit)

proc setStrokeWidth*(size: float) =
  context.StrokeWidth(size)

proc setLineCap*(cap: LineCap) =
  context.LineCap(cap.cint)

proc setLineJoin*(join: LineJoin) =
  context.LineJoin(join.cint)

proc setGlobalAlpha*(alpha: float) =
  context.GlobalAlpha(alpha)

# Transforms

proc resetTransform*() =
  context.ResetTransform()

proc transform*(a, b, c, d, e, f: float) =
  context.Transform(a, b, c, d, e, f)

proc translate*(x, y: float) =
  context.Translate(x, y)

proc rotate*(angle: float) =
  context.Rotate(angle)

proc skewX*(angle: float) =
  context.SkewX(angle)

proc skewY*(angle: float) =
  context.SkewY(angle)

proc scale*(x, y: float) =
  context.Scale(x, y)

proc copyArray[T, U](src: T): U =
  for i in 0..<src.len:
    result[i] = type(result[i])((src[i]))

proc getCurrentTransform*(): array[6, float] =
  var res: array[6, cfloat]
  context.CurrentTransform(res[0].addr)
  return copyArray[array[6, cfloat], array[6, float]](res)

proc setTransformIdentity*(dest: array[6, float]) =
  var dst = copyArray[array[6, float], array[6, cfloat]](dest)
  TransformIdentity(dst[0].addr)


proc degreesToRadians*(degrees: float): float =
  return DegToRad(degrees)

proc radiansToDegrees*(radians: float): float =
  return RadToDeg(radians)

# Images

proc `or`(imageflags1: ImageFlags, imageflags2: ImageFlags): ImageFlags =
  return (imageflags1.cint or imageflags2.cint).ImageFlags

proc loadImage*(fileName: string, flags: varargs[ImageFlags]): Image =
  var flagArgs = reduce(flags, `or`)
  result = context.CreateImage(fileName, flagArgs.cint)

  if result == -1:
    raise newException(ImageLoadError, fmt"Could not load image {fileName}.")

macro loadImage*(fileName, flags: string): Image =
  return createExpr("ImageFlags", "loadImage", flags, fileName)

proc createImageFromArray*(data: openArray[uint8], flags: varargs[ImageFlags]): Image =
  var flagArgs = reduce(flags, `or`)
  result = context.CreateImageMem(flagArgs.cint, cast[ptr cuchar](data[0].unsafeAddr), data.len.cint)

  if result == -1:
    raise newException(ImageLoadError, fmt"Could not load image from data.")

proc size*(image: Image): Size =
  var rw, rh: cint
  context.ImageSize(image, rw.addr, rh.addr)
  result.width = rw
  result.height = rh

proc delete*(image: Image) =
  context.DeleteImage(image)

# Paths
proc beginPath*() =
  context.BeginPath()

proc pathMoveTo*(x, y: float) =
  context.MoveTo(x, y)

proc pathLineTo*(x, y: float) =
  context.LineTo(x, y)

proc pathBezierTo*(c1x, c1y, c2x, c2y, x, y: float) =
  context.BezierTo(c1x, c1y, c2x, c2y, x, y)

proc pathQuadTo*(cx, cy, x, y: float) =
  context.QuadTo(cx, cy, x, y)

proc pathArcTo*(x1, y1, x2, y2, radius: float) =
  context.ArcTo(x1, y1, x2, y2, radius)

proc closePath*() =
  context.ClosePath()

proc pathWinding*(dir: Winding) =
  context.PathWinding(dir.cint)

proc setSolidity*(solidity: Solidity) =
  context.PathWinding(solidity.cint)

proc pathArc*(cx, cy, r, a0, a1: float, dir: int) =
  context.Arc(cx, cy, r, a0, a1, dir.cint)

proc pathRect*(x, y, width, height: float) =
  context.Rect(x, y, width, height)

proc pathRoundedRect*(x, y, width, height, radius: float) =
  context.RoundedRect(x, y, width, height, radius)

proc pathRoundedRectVarying*(x, y, width, height, radiusTopLeft, radiusTopRight,
                             radiusBottomRight, radiusBottomLeft: float) =
  context.RoundedRectVarying(
    x, y, width, height,
    radiusTopLeft, radiusTopRight, radiusBottomRight, radiusBottomLeft
  )

proc pathEllipse*(cx, cy, radiusX, radiusY: float) =
  context.Ellipse(cx, cy, radiusX, radiusY)

proc pathCircle*(cx, cy, radius: float) =
  context.Circle(cx, cy, radius)

proc pathFill*() =
  context.Fill()

proc pathStroke*() =
  context.Stroke()

proc linearGradient*(startX, startY, endX, endY: float, startColor, endColor: Color): Paint =
  result = context.LinearGradient(startX, startY, endX, endY, startColor, endColor)

proc boxGradient*(x, y, width, height, radius, feather: float, startColor, endColor: Color): Paint =
  result = context.BoxGradient(x, y, width, height, radius, feather, startColor, endColor)

proc radialGradient*(centerX, centerY, innerRadius, outerRadius: float, startColor, endColor: Color): Paint =
  result = context.RadialGradient(centerX, centerY, innerRadius, outerRadius, startColor, endColor)

proc imagePattern*(originX, originY, renderSizeX, renderSizeY, angle: float, image: Image, alpha: float): Paint =
  result = context.ImagePattern(originX, originY, renderSizeX, renderSizeY, angle, image, alpha)

proc setScissor*(x, y, width, height: float) =
  context.Scissor(x, y, width, height)

proc intersectScissor*(x, y, width, height: float) =
  context.IntersectScissor(x, y, width, height)

proc resetScissor*() =
  context.ResetScissor()

proc cleanup() {.noconv.} =
  echo "running cleanup"
  context.DeleteGL3()

addQuitProc(cleanup)
