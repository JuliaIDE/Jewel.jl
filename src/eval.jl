# ----
# Eval
# ----

handle("editor.eval.julia") do req, data
  info = get_code(data)
  val = nothing
  mod = @or get(Main, info[:module], nothing) Main

  try
    if get(data, "all", false) || mod == Main
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
