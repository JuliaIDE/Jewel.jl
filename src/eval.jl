#jewel module Jewel

# ----
# Eval
# ----

# TODO: remove result display in eval.all
#       fix error for one-line fns

handle("editor.eval.julia") do req, data
  info = get_code(data)
  # println(info[:code])

  val = nothing
  mod = get(Main, info[:module], Main)

  task_local_storage()[:SOURCE_PATH] = get(data, "path", nothing)

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

  display_result(req, val, info[:lines])
end
