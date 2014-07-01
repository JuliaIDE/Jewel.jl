function get_module(data::Dict)
  mod = get_module_name(data)
  mod == "" || return getthing(mod)
  mod = data["module"]
  mod == nothing || return getthing(mod)
  return Main
end

# ----
# Eval
# ----

# Shoud be split into eval and eval.all
handle("editor.eval.julia") do req, data
  info = get_code(data)
  all = get(data, "all", false)

  val = nothing
  mod = info[:module] != nothing ? info[:module] :
        data["module"] != nothing ? getthing(data["module"]) : Main

  mod == nothing && error("Module $(data["mod"]) not found")

  path = get(data, "path", nothing)
  task_local_storage()[:SOURCE_PATH] = path
  path == nothing && (path = "REPL")

  try
    val = include_string(mod, info[:code], path, info[:lines][1])
  catch e
    show_exception(req, sprint(io->showerror_html(io, e.error, catch_backtrace(), :include_string)), info[:lines])
    return
  end

  if all
    notify_done()
    file = path == nothing ? "file" : splitdir(path)[2]
    notify("✓ Evaluated $file in module $mod")
  else
    display_result(req, val, info[:lines])
  end
end
