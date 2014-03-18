# ----
# Eval
# ----

handle("editor.eval.julia") do req, data
  data = get_code(data)
  code, lines = data[:code], data[:lines]
  val = nothing
  try
    code = parse(code)
    val = Main.eval(code)
  catch e
    show_exception(req, sprint(showerror, e), lines)
    return
  end
  display_result(req, val, lines)
end
