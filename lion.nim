import rdstdin, sequtils, tables, os
import json, mal, types, reader, printer, env, core

for k, v in ns.items:
  repl_env.set(k, v)
repl_env.set("eval", fun(proc(xs: varargs[MalType]): MalType = eval(xs[0], repl_env)))
let ps = commandLineParams()
repl_env.set("*ARGV*", list((if paramCount() > 1: ps[1..ps.high] else: @[]).map(str)))

# core.mal: defined using mal itself
rep "(def! not (fn* (a) (if a false true)))"
rep "(def! load-file (fn* (f) (eval (read-string (str \"(do \" (slurp f) \"\nnil)\")))))"
rep "(defmacro! cond (fn* (& xs) (if (> (count xs) 0) (list 'if (first xs) (if (> (count xs) 1) (nth xs 1) (throw \"odd number of forms to cond\")) (cons 'cond (rest (rest xs)))))))"

if paramCount() >= 1:
  rep "(load-file \"" & paramStr(1) & "\")"
  quit()

proc toStr(result: var string, node: JsonNode) =
  case node.kind
  of SExpr:
    if len(node.sexprs) != 0:
      result.add("(")
      for i in 0..len(node.sexprs)-1:
        if i > 0:
          result.add(" ")
        toStr(result, node.sexprs[i])
      result.add(")")
    else: result.add("())")
  of JString:
    toUgly(result, node)
  of Symbol:
    toUgly(result, node)
  # of Keyword:
  #   toUgly(result, node)
  of JInt:
    result.addInt(node.num)
  of JBool:
    result.add(if node.bval: "true" else: "false")
  of Nil:
    result.add("nil")
  else: discard

proc evalSExprs(node: JsonNode) =
  var result: string
  case node.kind
  of SExpr:
      result.toStr node
      echo result.rep
  of JObject:
    for key, value in pairs(node.fields):
      evalSExprs(value)
  else: return

while true:
  try:
    let line = readLineFromStdin("> ")
    var jsonNode = parseJson(line)
    evalSExprs(jsonNode)
  except Blank: discard
  except IOError: quit()
  except MalError:
    let exc = (ref MalError) getCurrentException()
    echo "Error: " & exc.t.list[0].pr_str
  except:
    stdout.write "Error: "
    echo getCurrentExceptionMsg()
    echo getCurrentException().getStackTrace()

# nim c --os:windows --cpu:amd64 \
#     --cc:gcc \
#     --gcc.exe:x86_64-w64-mingw32-gcc \
#     --gcc.linkerexe:x86_64-w64-mingw32-gcc \
#     -d:release lion.nim
