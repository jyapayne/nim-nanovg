import macros, nimterop / plugin
import strutils

template camelCase(str: string): string =
  var res = newStringOfCap(str.len)
  var i = 0
  while i < str.len:
    if str[i] == '_' and i < str.len - 1:
      res.add(str[i+1].toUpperAscii)
      i += 1
    else:
      res.add(str[i])
    i += 1
  res

template lowerFirstLetter(str, rep: string): string =
  if str.startsWith(rep):
    var res = str[rep.len .. ^1]
    res[0] = res[0].toLowerAscii
    res
  else:
    str

template removeBeginning(str, rep: string): string =
  if str.startsWith(rep):
    str[rep.len .. ^1]
  else:
    str

const replacements = [
  "glnvg__",
  "nvg__",
  "nvglu",
  "nvgl",
  "nvg",
]

# Symbol renaming examples
proc onSymbol*(sym: var Symbol) {.exportc, dynlib.} =
  for rep in replacements:
    if sym.kind == nskProc:
      sym.name = lowerFirstLetter(sym.name, rep)
    elif sym.kind == nskType:
      if sym.name.startsWith(rep):
        sym.name = camelCase(removeBeginning(sym.name, rep))
    else:
      sym.name = removeBeginning(sym.name, rep)

  if sym.kind == nskField:
    sym.name = camelCase(sym.name)
    if sym.name == "type":
      sym.name = "kind"

  # Get rid of leading and trailing underscores
  if sym.kind == nskProc or sym.kind == nskType or sym.kind == nskConst:
    if sym.name != "_":
      sym.name = sym.name.strip(chars={'_'}).replace("__", "_").strip(chars={'_'})
