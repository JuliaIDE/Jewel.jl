# ----
# Eval
# ----

handle("editor.eval.julia") do req, data
  data = get_code(data)
  val = nothing
  try
    code = parse("begin\n"*data[:code]*"\nend")
    val = Main.eval(code)
  catch e
    show_exception(req, sprint(showerror, e), data[:lines])
    return
  end
  display_result(req, val, data[:lines])
end
