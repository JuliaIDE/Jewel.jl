cursor(c::Dict) = c["line"], c["col"]

handle("editor.julia.hints") do editor, data
  cur = data["cursor"] |> cursor
  code = data["code"]
  mod = data["module"] == nothing ? Main : getthing(data["module"])
  completions = allcompletions(code, cur, mod)
  if completions == nothing
    raise(editor, "editor.julia.hints.update",
        {:hints => {}})
  else
    @show completions[:pattern]
    raise(editor, "editor.julia.hints.update",
          {:hints => completions[:hints],
           :pattern => completions[:pattern].pattern})
  end
end
