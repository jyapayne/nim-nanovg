import nanovg
import strformat

const GRAPH_HISTORY_COUNT = 100

type
  RenderStyle* {.pure.} = enum
    FPS,
    MS,
    PERCENT

  PerfGraph* = ref object
    style: RenderStyle
    name: string
    values: array[GRAPH_HISTORY_COUNT, float]
    head: int


proc newGraph*(style: RenderStyle, name: string): PerfGraph =
  new(result)
  result.style = style
  result.name = name

proc update*(graph: PerfGraph, frameTime: float) =
  graph.head = (graph.head + 1) mod GRAPH_HISTORY_COUNT
  graph.values[graph.head] = frameTime

proc getGraphAverage(graph: PerfGraph): float =
  var avg: float = 0.0
  for i in 0 ..< GRAPH_HISTORY_COUNT:
    avg += graph.values[i]

  return avg / GRAPH_HISTORY_COUNT.float

proc render*(graph: PerfGraph, x, y: float) =
  let
    avg = getGraphAverage(graph)
    width: float = 200
    height: float = 35

  nanovg.beginPath()
  nanovg.pathRect(x, y, width, height)
  nanovg.setFillColor(0, 0, 0, 128)
  nanovg.pathFill()

  nanovg.beginPath()
  nanovg.pathMoveTo(x, y+height)

  case graph.style:
    of RenderStyle.FPS:
      for i in 0 ..< GRAPH_HISTORY_COUNT:
        var v: float = 1.0 / (0.00001 + graph.values[(graph.head+i) mod GRAPH_HISTORY_COUNT])
        var vx, vy: float

        if v > 80:
          v = 80

        vx = x + (i/(GRAPH_HISTORY_COUNT-1)) * width
        vy = y + height - ((v / 80) * height)

        nanovg.pathLineTo(vx, vy)

    of RenderStyle.PERCENT:
      for i in 0 ..< GRAPH_HISTORY_COUNT:
        var v: float = graph.values[(graph.head+i) mod GRAPH_HISTORY_COUNT]
        var vx, vy: float

        if v > 100:
          v = 100

        vx = x + (i/(GRAPH_HISTORY_COUNT-1)) * width
        vy = y + height - ((v / 100) * height)

        nanovg.pathLineTo(vx, vy)

    of RenderStyle.MS:
      for i in 0 ..< GRAPH_HISTORY_COUNT:
        var v: float = graph.values[(graph.head+i) mod GRAPH_HISTORY_COUNT] * 1000
        var vx, vy: float

        if v > 20:
          v = 20

        vx = x + (i/(GRAPH_HISTORY_COUNT-1)) * width
        vy = y + height - ((v / 20) * height)

        nanovg.pathLineTo(vx, vy)

  nanovg.pathLineTo(x+width, y+height)
  nanovg.setFillColor(255, 192, 0, 128)
  nanovg.pathFill()

  nanovg.setFont("sans")

  if graph.name.len() > 0:
    nanovg.setFontSize(14)
    nanovg.textAlign("top left")
    nanovg.setFillColor(240, 240, 240, 192)
    nanovg.text(x+3, y+1, graph.name)

  nanovg.setFontSize(18)
  nanovg.textAlign("top right")
  nanovg.setFillColor(240, 240, 240, 255)

  case graph.style:
    of RenderStyle.FPS:
      var str = fmt"{1.0/avg:.2f} FPS"

      nanovg.text(x+width-3, y+1, str)
      nanovg.setFontSize(15)
      nanovg.textAlign("bottom right")
      nanovg.setFillColor(240, 240, 240, 160)

      str = fmt"{avg*1000:.2f} ms"
      nanovg.text(x+width-3, y+height-1, str)

    of RenderStyle.PERCENT:
      let str = fmt"{avg:.1f} %"
      nanovg.text(x+width-3, y+1, str)

    of RenderStyle.MS:
      let str = fmt"{avg*1000:.2f} ms"
      nanovg.text(x+width-3, y+1, str)
