#jewel module Jewel

# ----
# Eval
# ----

# TODO: fix error for two-line fns

handle("editor.eval.julia") do req, data
  info = get_code(data)
  all = get(data, "all", false)
  # println(info[:code])

  val = nothing
  mod = get(Main, info[:module], Main)

  path = get(data, "path", nothing)
  task_local_storage()[:SOURCE_PATH] = path

  try
    if mod == Main
      val = include_string(info[:code])
    else
      code = parse("begin\n"*info[:code]*"\nend")
      val = eval(mod, code)
    end
  catch e
    show_exception(req, sprint(showerror, e), info[:lines])
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
