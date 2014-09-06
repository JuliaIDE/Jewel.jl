# Eval

function eval(editor, mod, code, file, bounds)
  task_local_storage()[:SOURCE_PATH] = file
  file == nothing && (file = "REPL")
  try
    result = include_string(mod, code, file, bounds[1])
    Jewel.isdefinition(code) && (result = nothing)
    displayinline!(result, {:editor => editor, :bounds => bounds, :id => register_result(result)})
  catch e
    showexception(editor, isa(e, LoadError)?e.error:e, catch_backtrace(), bounds)
  end
end

noselection(data) = data["start"] == data["end"]

LNR.cursor(data::Dict) = cursor(data["line"], data["col"])

handle("editor.eval.julia") do editor, data
  code, bounds =
    noselection(data) ?
      Jewel.getblock(data["code"], data["start"]["line"]) :
      Jewel.getblock(data["code"], cursor(data["start"]), cursor(data["end"]))
  code == "" && return notify_done()
  mod = Jewel.getmodule(data["code"], bounds[1], filemod = data["module"])
  eval(editor, mod, code, data["path"], bounds)
end

handle("editor.eval.julia.all") do editor, data
  file = @or data["path"] "REPL"
  code = data["code"]
  mod = Jewel.getthing(data["module"], Main)
  try
    task_local_storage()[:SOURCE_PATH] = data["path"]
    include_string(mod, code, file)
  catch e
    println(STDERR, "Error evaluating $file:")
    showerror(STDERR, e.error, catch_backtrace())
    println(STDERR)
    notify_error(sprint(showerror, e.error))
  end
  notify_done()
end
