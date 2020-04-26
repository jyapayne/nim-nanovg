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

proc render*(vg: Context, graph: PerfGraph, x, y: float) =
  let
    avg = getGraphAverage(graph)
    width: float = 200
    height: float = 35

  vg.beginPath()
  vg.pathRect(x, y, width, height)
  vg.setFillColor(0, 0, 0, 128)
  vg.pathFill()

  vg.beginPath()
  vg.pathMoveTo(x, y+height)

  case graph.style:
    of RenderStyle.FPS:
      for i in 0 ..< GRAPH_HISTORY_COUNT:
        var v: float = 1.0 / (0.00001 + graph.values[(graph.head+i) mod GRAPH_HISTORY_COUNT])
        var vx, vy: float

        if v > 80:
          v = 80

        vx = x + (i/(GRAPH_HISTORY_COUNT-1)) * width
        vy = y + height - ((v / 80) * height)

        vg.pathLineTo(vx, vy)

    of RenderStyle.PERCENT:
      for i in 0 ..< GRAPH_HISTORY_COUNT:
        var v: float = graph.values[(graph.head+i) mod GRAPH_HISTORY_COUNT]
        var vx, vy: float

        if v > 100:
          v = 100

        vx = x + (i/(GRAPH_HISTORY_COUNT-1)) * width
        vy = y + height - ((v / 100) * height)

        vg.pathLineTo(vx, vy)

    of RenderStyle.MS:
      for i in 0 ..< GRAPH_HISTORY_COUNT:
        var v: float = graph.values[(graph.head+i) mod GRAPH_HISTORY_COUNT] * 1000
        var vx, vy: float

        if v > 20:
          v = 20

        vx = x + (i/(GRAPH_HISTORY_COUNT-1)) * width
        vy = y + height - ((v / 20) * height)

        vg.pathLineTo(vx, vy)

  vg.pathLineTo(x+width, y+height)
  vg.setFillColor(255, 192, 0, 128)
  vg.pathFill()

  vg.setFont("sans")

  if graph.name.len() > 0:
    vg.setFontSize(14)
    vg.textAlign("top left")
    vg.setFillColor(240, 240, 240, 192)
    vg.text(graph.name, x+3, y+1)

  vg.setFontSize(18)
  vg.textAlign("top right")
  vg.setFillColor(240, 240, 240, 255)

  case graph.style:
    of RenderStyle.FPS:
      var str = fmt"{1.0/avg:.2f} FPS"

      vg.text(str, x+width-3, y+1)
      vg.setFontSize(15)
      vg.textAlign("bottom right")
      vg.setFillColor(240, 240, 240, 160)

      str = fmt"{avg*1000:.2f} ms"
      vg.text(str, x+width-3, y+height-1)

    of RenderStyle.PERCENT:
      let str = fmt"{avg:.1f} %"
      vg.text(str, x+width-3, y+1)

    of RenderStyle.MS:
      let str = fmt"{avg*1000:.2f} ms"
      vg.text(str, x+width-3, y+1)
