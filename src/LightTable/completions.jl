handle("editor.julia.hints") do editor, data
  cur = cursor(data["cursor"]["line"], data["cursor"]["col"])
  code = data["code"]
  mod = data["module"] == nothing ? Main : Jewel.getthing(data["module"])
  completions = allcompletions(code, cur, mod = mod, file = data["path"])
  if completions == nothing
    raise(editor, "editor.julia.hints.update",
          {:hints => {}})
  else
    raise(editor, "editor.julia.hints.update",
          {:hints => completions[:hints],
           :pattern => completions[:pattern].pattern})
  end
end
