function eval(editor, mod, code, file, bounds)
  try
    result = include_string(mod, code, file, bounds[1])
    displayinline!(editor, result, bounds)
  catch e
    showexception(editor, e.error, catch_backtrace(), bounds)
  end
end

handle("editor.eval.julia") do editor, data
  file = @or data["path"] "REPL"
  code, bounds = Jewel.getblock(data["code"], data["start"]["line"])
  mod = Jewel.getmodule(data["code"], bounds[1], filemod = data["module"])
  eval(editor, mod, code, file, bounds)
end
