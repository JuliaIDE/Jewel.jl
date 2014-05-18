#jewel module Jewel

# ----
# Eval
# ----

function Base.include_string(s::String, fname::String, line::Integer)
  include_string("\n"^(line-1)*s, fname)
end

function Base.include_string(mod::Module, args...)
  eval(mod, :(include_string($(args...))))
end

# Shoud be split into eval and eval.all
handle("editor.eval.julia") do req, data
  info = get_code(data)
  all = get(data, "all", false)

  val = nothing
  mod = to_module(info[:module])

  path = get(data, "path", nothing)
  task_local_storage()[:SOURCE_PATH] = path
  path == nothing && (path = "REPL")

  try
    val = include_string(mod, info[:code], path, info[:lines][1])
  catch e
    show_exception(req, sprint(showerror, e, catch_backtrace()), info[:lines])
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
