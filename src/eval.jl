#jewel module Jewel

# ----
# Eval
# ----

# Shoud be split into eval and eval.all
handle("editor.eval.julia") do req, data
  info = get_code(data)
  all = get(data, "all", false)
  # println(info[:code])

  val = nothing
  mod = to_module(info[:module])

  path = get(data, "path", nothing)
  task_local_storage()[:SOURCE_PATH] = path

  try
    code = parse("begin; " * info[:code] * "; end")
    code = Expr(:toplevel, code.args...)
    val = eval(mod, code)
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
