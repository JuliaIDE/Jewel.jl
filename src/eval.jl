# ----
# Eval
# ----

handle("editor.eval.julia") do req, data
  info = get_code(data)
  # println(info[:code])

  val = nothing
  mod = get(Main, info[:module], Main)

  path = get(data, "path", nothing)
  path = path == nothing ? homedir() : splitdir(path)[1]

  try
    cd(path) do
      if get(data, "all", false) || mod == Main
        val = include_string(info[:code])
      else
        code = parse("begin\n"*info[:code]*"\nend")
        val = eval(mod, code)
      end
    end
  catch e
    show_exception(req, sprint(showerror, e), info[:lines])
    return
  end

  display_result(req, val, info[:lines])
end
