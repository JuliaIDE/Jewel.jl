function eval(editor, mod, code, file, bounds)
  try
    result = include_string(mod, code, file, bounds[1])
    Jewel.isdefinition(code) && (result = nothing)
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

handle("editor.eval.julia.all") do editor, data
  file = @or data["path"] "REPL"
  code = data["code"]
  mod = Jewel.getthing(data["module"], Main)
  try
    include_string(mod, code, file)
  catch e
    println(STDERR, "Error evaluating $file:")
    showerror(STDERR, e.error, catch_backtrace())
    println(STDERR)

    notify_error(sprint(showerror, e.error))
  end
  notify_done()
end
