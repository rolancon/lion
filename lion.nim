import rdstdin, sequtils, os
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
#rep "(def! version (fn* () (\"0.9\")))"

if paramCount() >= 1:
  rep "(load-file \"" & paramStr(1) & "\")"
  quit()

while true:
  try:
    let line = readLineFromStdin("> ")
    var jsonNode = parseJson(line)
    if jsonNode.kind == SExpr:
        echo line.rep
  except Blank: discard
  except IOError: quit()
  except MalError:
    let exc = (ref MalError) getCurrentException()
    echo "Error: " & exc.t.list[0].pr_str
  except:
    stdout.write "Error: "
    echo getCurrentExceptionMsg()
    echo getCurrentException().getStackTrace()
