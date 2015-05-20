handle("editor.julia.hints") do editor, data
  cur = cursor(data["cursor"]["line"], data["cursor"]["col"])
  code = data["code"]
  mod = Jewel.getmodule(code, cur, filemod = data["module"])
  completions = allcompletions(code, cur, mod = mod, file = data["path"])
  if completions == nothing
    raise(editor, "editor.julia.hints.update",
          @d(:hints => c()))
  else
    raise(editor, "editor.julia.hints.update",
          @d(:hints => completions[:hints],
             :pattern => completions[:pattern].pattern))
  end
end
