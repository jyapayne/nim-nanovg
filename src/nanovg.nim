import macros
import sequtils
import strutils
import strformat
import nanovg/wrapper

converter intToCuchar*(source: uint8 | int): cuchar =
  return source.cuchar

export hsl
export hsla
export rgba
export rgbaf
export rgb
export rgbf
export lerpRGBA
export transRGBA
export transRGBAf

#{.experimental: "dynamicBindSym".}

type
  FontLoadError* = object of CatchableError
  ImageLoadError* = object of CatchableError
  ContextInitError* = object of CatchableError
  Context* = ptr NVGContext

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

  FrameBuffer* = ptr NVGLUframebuffer

  ImageFlagsGL* {.size: sizeof(cint), pure.} = enum
    NONE = 0,
    NO_DELETE = NVG_IMAGE_NODELETE

  ImageFlags* {.size: sizeof(cint), pure.} = enum
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

proc createExpr*(context: NimNode, ty, name: string, descriptor: NimNode, args: varargs[NimNode]): NimNode =
  let tokens = ($descriptor).toUpper().split(" ").map(
    proc(s: string): string =
      return ty & "." & s
  )

  let argTokens = args.map(
    proc(arg: NimNode): string =
      $arg.toStrLit()
  )

  let allTokens = argTokens.concat(tokens)

  let newExpr = name & "(" & $context.toStrLit & ", " & allTokens.join(",") & ")"

  result = parseStmt(newExpr)


template reduce[T](elements: openArray[T], op: untyped): untyped =
  var res = T.NONE

  for element in elements:
    res = op(res, element)

  res

proc delete*(context: Context) =
  context.deleteGL3()

proc newContext*(antialias = true, stencilStrokes = true, debugChecks = false): Context =
  var flags: cint

  if antialias:
    flags = flags or NVG_ANTIALIAS.cint
  if stencilStrokes:
    flags = flags or NVG_STENCIL_STROKES.cint
  if debugChecks:
    flags = flags or NVG_DEBUG.cint

  result = createGL3(flags)

  if result.isNil:
    raise newException(ContextInitError, "Could not initialize graphics context")

proc loadFont*(context: Context, path, name: string): Font {.discardable.} =
  ## Load the font from `path` and give it a `name` that can be used to reference it.
  result = context.createFont(name, path)

  if result == -1:
    raise newException(FontLoadError, fmt"Could not load font {name}.")

proc loadFontMem*(context: Context, data: openArray[uint8], name: string, freeDataAutomatically = true): Font {.discardable.} =
  ## Load the font from `path` and give it a `name` that can be used to reference it.
  result = context.createFontMem(name, cast[ptr cuchar](data[0].unsafeAddr), data.len.cint, freeDataAutomatically.cint)

  if result == -1:
    raise newException(FontLoadError, fmt"Could not load font {name}.")

proc findFont*(context: Context, name: string): Font =
  return context.findFont(name)

proc setFallbackFont*(context: Context, baseFont, fallbackFont: string): Font =
  return context.addFallbackFont(baseFont, fallbackFont)

proc setFallbackFont*(context: Context, baseFont, fallbackFont: Font): Font =
  return context.addFallbackFontId(baseFont, fallbackFont)

proc `font=`*(context: Context, font: Font) =
  context.fontFaceId(font)

proc setFont*(context: Context, name: string) =
  context.fontFace(name)

proc setFontSize*(context: Context, size: float) =
  context.fontSize(size)

proc setFontBlur*(context: Context, blur: float) =
  context.fontBlur(blur)

proc setTextLetterSpacing*(context: Context, spacing: float) =
  context.textLetterSpacing(spacing)

proc setTextLineHeight*(context: Context, lineHeight: float) =
  context.textLineHeight(lineHeight)

proc `or`(align1: Alignment, align2: Alignment): Alignment =
  return (align1.cint or align2.cint).Alignment

proc textAlign*(context: Context, alignments: varargs[Alignment]) =
  var alignment = reduce(alignments, `or`)

  context.textAlign(alignment.cint)

macro textAlign*(context: Context, descriptor: string) =
  result = createExpr(context, "Alignment", "textAlign", descriptor)

proc textBounds*(context: Context, text: string, x, y: float): TextBounds =
  var res: array[4, cfloat]
  let horizonalAdvance = context.textBounds(x, y, text, nil, res[0].addr)

  let bounds: Bounds = (res[0].float, res[1].float, res[2].float, res[3].float)
  return (horizonalAdvance.float, bounds)

proc text*(context: Context, text: string, x, y: float) =
  discard context.text(x, y, text, nil)

proc textBoxBounds*(context: Context, text: string, x, y, breakRowWidth: float): Bounds =
  var res: array[4, cfloat]
  context.textBoxBounds(x, y, breakRowWidth, text, nil, res[0].addr)

  return (res[0].float, res[1].float, res[2].float, res[3].float)

proc textBox*(context: Context, text: string, x, y, breakRowWidth: float) =
  context.textBox(x, y, breakRowWidth, text, nil)

proc textMetrics*(context: Context): TextMetrics =
  var
    ascender, descender, lineHeight: cfloat

  context.textMetrics(ascender.addr, descender.addr, lineHeight.addr)

  return (ascender.float, descender.float, lineHeight.float)

iterator glyphPositions(context: Context, start: cstring, endPos: cstring, x, y: float): GlyphPosition =
  const maxPositions = 100
  var
    positions: array[maxPositions, NVGglyphPosition]
    numGlyphs = 0
    bytesProcessed = 0
    lastX = x
    strIndex = 0
    lineHeight = context.textMetrics().lineHeight

  let strLen = cast[ByteAddress](endPos) - cast[ByteAddress](start)

  while (strIndex < strLen):
    numGlyphs = context.textGlyphPositions(
      lastX, y, cast[cstring](start[strIndex].unsafeAddr), endPos,
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
        byteWidth = strLen - bytesProcessed

      var glyph = newStringOfCap(byteWidth)
      for j in 0..<byteWidth:
        glyph.add(retPos.str[j])

      yield GlyphPosition(
        glyph: glyph, x: retPos.x, y: y, minX: retPos.minX, maxX: retPos.maxX,
        height: lineHeight
      )

      bytesProcessed += byteWidth

    lastX = positions[numGlyphs-1].x
    strIndex += maxPositions

proc glyphPositions*(context: Context, text: string, x, y: float): seq[GlyphPosition] =
  result = newSeqOfCap[GlyphPosition](100)
  for gpos in context.glyphPositions(cast[cstring](text[0].unsafeAddr), nil, x, y):
    result.add gpos

proc glyphPositions*(context: Context, row: NVGtextRow, x, y: float): seq[GlyphPosition] =
  result = newSeqOfCap[GlyphPosition](100)
  for gpos in context.glyphPositions(row.start, row.`end`, x, y):
    result.add gpos

iterator textRows(context: Context, text: string, x, y, maxWidth: float): NVGtextRow =
  const maxRows = 10
  var
    rows: array[maxRows, NVGtextRow]
    numRows: int
    start = cast[cstring](text[0].unsafeAddr)

  while true:
    numRows = context.textBreakLines(
      start,
      nil,
      maxWidth, rows[0].addr, maxRows
    )
    if numRows == 0:
      break
    for i in 0 ..< numRows:
      yield rows[i]

    start = rows[numRows-1].next

proc glyphPositions*(context: Context, text: string, x, y, maxWidth: float): seq[GlyphPosition] =
  var newY = y

  for row in context.textRows(text, x, y, maxWidth):
    let glyphPositions = context.glyphPositions(row, x, newY)
    result.add(glyphPositions)
    newY += glyphPositions[0].height

proc text*(context: Context, text: string, x, y, maxWidth: float) =
  var newY = y

  for row in context.textRows(text, x, y, maxWidth):
    discard context.text(x, newY, row.start, row.`end`)
    newY += context.textMetrics().lineHeight

export beginFrame
export endFrame
export cancelFrame

proc globalCompositeOperation*(context: Context, op: CompositeOperation) =
  context.globalCompositeOperation(op.cint)

proc globalCompositeBlendFunc*(context: Context, sourceFactor, destFactor: BlendFactor) =
  context.globalCompositeBlendFunc(sourceFactor.cint, destFactor.cint)

proc globalCompositeBlendFuncSeparate*(context: Context, srcRGB, destRGB, srcAlpha, destAlpha: BlendFactor) =
  context.globalCompositeBlendFuncSeparate(srcRGB.cint, destRGB.cint, srcAlpha.cint, destAlpha.cint)

template withFrame*(context: Context, window: View, code: untyped) =
  let
    winSize = window.size()
    fbSize = window.frameBufferSize()
    pxRatio = cfloat(fbSize.w) / cfloat(winSize.w)

  context.beginFrame(winSize.w.cfloat, winSize.h.cfloat, pxRatio)
  code
  context.endFrame()


#
# State Handling
#
# NanoVG contains state which represents how paths will be rendered.
# The state contains transform, fill and stroke styles, text and font styles,
# and scissor clipping.
#
proc saveState*(context: Context, ) =
  ## Pushes and saves the current render state into a state stack.
  ## A matching restoreState() must be used to restore the state.
  context.save()

proc restoreState*(context: Context, ) =
  ## Pops and restores current render state.
  context.restore()

proc resetState*(context: Context, ) =
  ## Resets current render state to default values. Does not affect the render state stack.
  context.reset()

template withState*(context: Context, code: untyped) =
  context.saveState()
  try:
    code
  except:
    raise
  finally:
    context.restoreState()

proc setShapeAntialias*(context: Context, enabled = true) =
  context.shapeAntiAlias(enabled.cint)

proc setStrokeColor*(context: Context, color: Color) =
  context.strokeColor(color)

proc setStrokePaint*(context: Context, paint: Paint) =
  context.strokePaint(paint)

proc setFillPaint*(context: Context, paint: Paint) =
  context.fillPaint(paint)

proc setFillColor*(context: Context, color: Color) =
  context.fillColor(color)

proc setFillColor*(context: Context, r, g, b: uint8) =
  context.fillColor(rgb(r.cuchar, g.cuchar, b.cuchar))

proc setFillColor*(context: Context, r, g, b: float) =
  context.fillColor(rgbf(r, g, b))

proc setFillColor*(context: Context, r, g, b, a: float) =
  context.fillColor(rgbaf(r, g, b, a))

proc setFillColor*(context: Context, r, g, b, a: uint8) =
  context.fillColor(rgba(r.cuchar, g.cuchar, b.cuchar, a.cuchar))

proc setMiterLimit*(context: Context, limit: float) =
  context.miterLimit(limit)

proc setStrokeWidth*(context: Context, size: float) =
  context.strokeWidth(size)

proc setLineCap*(context: Context, cap: LineCap) =
  context.lineCap(cap.cint)

proc setLineJoin*(context: Context, join: LineJoin) =
  context.lineJoin(join.cint)

proc setGlobalAlpha*(context: Context, alpha: float) =
  context.globalAlpha(alpha)

proc `shapeAntialias=`*(context: Context, enabled: bool) =
  context.shapeAntiAlias(enabled.cint)

proc `strokeColor`*(context: Context, color: Color) =
  context.strokeColor(color)

proc `strokePaint=`*(context: Context, paint: Paint) =
  context.strokePaint(paint)

proc `fillPaint=`*(context: Context, paint: Paint) =
  context.fillPaint(paint)

proc `fillColor=`*(context: Context, color: Color) =
  context.fillColor(color)

proc `fillColor=`*(context: Context, color: tuple[r, g, b: uint8]) =
  context.fillColor(rgb(color.r.cuchar, color.g.cuchar, color.b.cuchar))

proc `fillColor=`*(context: Context, color: tuple[r, g, b: float]) =
  context.fillColor(rgbf(color.r, color.g, color.b))

proc `fillColor=`*(context: Context, color: tuple[r, g, b, a: float]) =
  context.fillColor(rgbaf(color.r, color.g, color.b, color.a))

proc setFillColor*(context: Context, color: tuple[r, g, b, a: uint8]) =
  context.fillColor(rgba(color.r.cuchar, color.g.cuchar, color.b.cuchar, color.a.cuchar))

proc `miterLimit=`*(context: Context, limit: float) =
  context.miterLimit(limit)

proc `strokeWidth=`*(context: Context, size: float) =
  context.strokeWidth(size)

proc `lineCap=`*(context: Context, cap: LineCap) =
  context.lineCap(cap.cint)

proc `lineJoin=`*(context: Context, join: LineJoin) =
  context.lineJoin(join.cint)

proc `globalAlpha=`*(context: Context, alpha: float) =
  context.globalAlpha(alpha)

# Transforms

proc resetTransform*(context: Context) {.inline.} =
  wrapper.resetTransform(context)

proc transform*(context: Context, a, b, c, d, e, f: float) =
  wrapper.transform(context, a, b, c, d, e, f)

proc translate*(context: Context, x, y: float) {.inline.} =
  wrapper.translate(context, x, y)

proc rotate*(context: Context, angle: float) {.inline.} =
  wrapper.rotate(context, angle)

proc skewX*(context: Context, angle: float) {.inline.} =
  wrapper.skewX(context, angle)

proc skewY*(context: Context, angle: float) {.inline.} =
  wrapper.skewY(context, angle)

proc scale*(context: Context, x, y: float) {.inline.} =
  wrapper.scale(context, x, y)

proc copyArray[T, U](src: T): U =
  for i in 0..<src.len:
    result[i] = type(result[i])((src[i]))

proc getCurrentTransform*(context: Context, ): array[6, float] =
  var res: array[6, cfloat]
  context.currentTransform(res[0].addr)
  return copyArray[array[6, cfloat], array[6, float]](res)

proc setTransformIdentity*(dest: array[6, float]) =
  var dst = copyArray[array[6, float], array[6, cfloat]](dest)
  transformIdentity(dst[0].addr)

proc degreesToRadians*(degrees: float): float =
  return degToRad(degrees)

proc radiansToDegrees*(radians: float): float =
  return radToDeg(radians)

proc createFrameBuffer*(context: Context, width, height: float, imageFlags: ImageFlagsGL = ImageFlagsGL.NONE): FrameBuffer =
  return context.createFramebuffer(width.cint, height.cint, imageFlags.cint)

proc binde*(fb: FrameBuffer) =
  bindFramebuffer(fb)

proc delete*(fb: FrameBuffer) =
  fb.deleteFramebuffer()

# Images

proc `or`(imageflags1: ImageFlags, imageflags2: ImageFlags): ImageFlags =
  return (imageflags1.cint or imageflags2.cint).ImageFlags

proc loadImage*(context: Context, fileName: string, flags: varargs[ImageFlags]): Image =
  var flagArgs = reduce(flags, `or`)
  result = context.createImage(fileName, flagArgs.cint)

  if result == -1:
    raise newException(ImageLoadError, fmt"Could not load image {fileName}.")

macro loadImage*(context: Context, fileName, flags: string): Image =
  return createExpr(context, "ImageFlags", "loadImage", flags, fileName)

proc createImageFromArray*(context: Context, data: openArray[uint8], flags: varargs[ImageFlags]): Image =
  var flagArgs = reduce(flags, `or`)
  result = context.createImageMem(flagArgs.cint, cast[ptr cuchar](data[0].unsafeAddr), data.len.cint)

  if result == -1:
    raise newException(ImageLoadError, fmt"Could not load image from data.")

proc size*(context: Context, image: Image): Size =
  var rw, rh: cint
  context.imageSize(image, rw.addr, rh.addr)
  result.width = rw
  result.height = rh

export deleteImage
export beginPath

proc pathMoveTo*(context: Context, x, y: float) =
  context.moveTo(x, y)

proc pathLineTo*(context: Context, x, y: float) =
  context.lineTo(x, y)

proc pathBezierTo*(context: Context, c1x, c1y, c2x, c2y, x, y: float) =
  context.bezierTo(c1x, c1y, c2x, c2y, x, y)

proc pathQuadTo*(context: Context, cx, cy, x, y: float) =
  context.quadTo(cx, cy, x, y)

proc pathArcTo*(context: Context, x1, y1, x2, y2, radius: float) =
  context.arcTo(x1, y1, x2, y2, radius)

export closePath

proc pathWinding*(context: Context, dir: Winding) =
  context.pathWinding(dir.cint)

proc `solidity=`*(context: Context, solidity: Solidity) =
  context.pathWinding(solidity.cint)

proc pathArc*(context: Context, cx, cy, r, a0, a1: float, dir: int) =
  context.arc(cx, cy, r, a0, a1, dir.cint)

proc pathRect*(context: Context, x, y, width, height: float) =
  context.rect(x, y, width, height)

proc pathRoundedRect*(context: Context, x, y, width, height, radius: float) =
  context.roundedRect(x, y, width, height, radius)

proc pathRoundedRectVarying*(context: Context, x, y, width, height, radiusTopLeft, radiusTopRight,
                             radiusBottomRight, radiusBottomLeft: float) =
  context.roundedRectVarying(
    x, y, width, height,
    radiusTopLeft, radiusTopRight, radiusBottomRight, radiusBottomLeft
  )

proc pathEllipse*(context: Context, cx, cy, radiusX, radiusY: float) =
  context.ellipse(cx, cy, radiusX, radiusY)

proc pathCircle*(context: Context, cx, cy, radius: float) =
  context.circle(cx, cy, radius)

proc pathFill*(context: Context) =
  context.fill()

proc pathStroke*(context: Context) =
  context.stroke()

proc linearGradient*(context: Context, startX, startY, endX, endY: float, startColor, endColor: Color): Paint =
  result = wrapper.linearGradient(context, startX, startY, endX, endY, startColor, endColor)

proc boxGradient*(context: Context, x, y, width, height, radius, feather: float, startColor, endColor: Color): Paint =
  result = wrapper.boxGradient(context, x, y, width, height, radius, feather, startColor, endColor)

proc radialGradient*(context: Context, centerX, centerY, innerRadius, outerRadius: float, startColor, endColor: Color): Paint =
  result = wrapper.radialGradient(context, centerX, centerY, innerRadius, outerRadius, startColor, endColor)

proc imagePattern*(context: Context, originX, originY, renderSizeX, renderSizeY, angle: float, image: Image, alpha: float): Paint =
  result = wrapper.imagePattern(context, originX, originY, renderSizeX, renderSizeY, angle, image, alpha)

proc setScissor*(context: Context, x, y, width, height: float) =
  context.scissor(x, y, width, height)

proc intersectScissor*(context: Context, x, y, width, height: float) =
  context.intersectScissor(x, y, width, height)

proc resetScissor*(context: Context) =
  context.resetScissor()

