LNR.cursor(d::Dict) = cursor(d["line"], d["col"])

handle("editor.eval.julia") do editor, data
  file = @or data["path"] "REPL"
  line = data["start"]["line"]
  code, bounds = Jewel.getblock(data["code"], line)
  mod = Jewel.getmodule(data["code"], line, filemod = data["module"])
  try
    result = include_string(mod, code, file, line)
    displayinline!(editor, result, bounds)
  catch e
    showexception(editor, e.error, catch_backtrace(), bounds)
  end
end
