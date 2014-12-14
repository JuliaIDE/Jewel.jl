# Eval

const evalerr = :secret_lighttable_eval_err_keyword

# Data gets attached to the result in Julia
# Info gets attached to the result in LT
function eval(editor, mod, code, file, bounds)
  task_local_storage()[:SOURCE_PATH] = file
  file == nothing && (file = "REPL")
  try
    result = include_string(mod, code, file, bounds[1])
    Jewel.isdefinition(code) && (result = nothing)
    return result
  catch e
    showexception(editor, isa(e, LoadError)?e.error:e, catch_backtrace(), bounds)
    return evalerr
  end
end

function evaldisplay(editor, mod, code, file, bounds; data = Dict(), info = Dict())
  try
    result = eval(editor, mod, code, file, bounds)
    result === evalerr && return
    withcurrentresult(register_result(result, data)) do
      displayinline!(result, @d(:editor => editor,
                                :bounds => bounds,
                                :info => merge(info, @d(:id => string(_currentresult_.id)))))
    end
  catch e
    showexception(editor, e, catch_backtrace(), bounds)
  end
end

noselection(data) = data["start"] == data["end"]

LNR.cursor(data::Dict) = cursor(data["line"], data["col"])

handle("eval.selection") do editor, data
  code, bounds =
    noselection(data) ?
      Jewel.getblock(data["code"], data["start"]["line"]) :
      Jewel.getblock(data["code"], cursor(data["start"]), cursor(data["end"]))
  code == "" && return notify_done()
  mod = Jewel.getmodule(data["code"], bounds[1], filemod = data["module"])
  evaldisplay(editor, mod, code, data["path"], bounds)
end

handle("eval.block") do editor, data
  code = data["block"]
  bounds = data["bounds"]
  mod = Jewel.getmodule(data["code"], bounds[1], filemod = data["module"])
  # We need some custom data to enable reevaluation
  evaldisplay(editor, mod, code, data["path"], bounds,
              data = @d(:editor => editor,
                        :mod => mod,
                        :bounds => bounds,
                        :code => code,
                        :path => data["path"]),
              info = @d(:scales => bounds))
end

handle("eval.all") do editor, data
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

handle("editor.block") do editor, data
  block, bounds = Jewel.getblock(data["code"], data["line"])
  raise(editor, "return-block", @d("block" => block,
                                   "bounds" => bounds,
                                   "id" => data["id"]))
end

# Reevaluation

handle("result.reval") do _, data
  withcurrentresult(data["id"]) do

    jscall("lt.plugins.reptile.working();")

    code = fillranges(_currentresult_.data[:code],
                      data["vals"],
                      data["locs"],
                      _currentresult_.data[:bounds][1])
    result = eval(_currentresult_.data[:editor],
                  _currentresult_.data[:mod],
                  code,
                  _currentresult_.data[:path],
                  _currentresult_.data[:bounds])

    local html
    try
      html = stringmime(MIME"text/html"(), applydisplayinline(result))
    catch e
      return showexception(_currentresult_.data[:editor], e, catch_backtrace(), _currentresult_.data[:bounds])
    end

    jscall("""
      this.querySelector('.julia.result').innerHTML = '$(jsescapestring(html))';
      lt.plugins.reptile.done_working();
    """)

    queuecmds()
    while length(cmdqueue) > 1 && cmdqueue[1][2] == cmdqueue[2][2] == "result.reval"
      shift!(cmdqueue)
    end
  end
end
