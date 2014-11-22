handle("editor.julia.hints") do editor, data
  cur = cursor(data["cursor"]["line"], data["cursor"]["col"])
  code = data["code"]
  mod = Jewel.getmodule(code, cur, filemod = data["module"])
  completions = allcompletions(code, cur, mod = mod, file = data["path"])
  if completions == nothing
    temp = @compat Dict(:hints => [])
    raise(editor, "editor.julia.hints.update",
            temp)
  else
    temp = @compat Dict(:hints => completions[:hints],
                        :pattern => completions[:pattern].pattern)
    raise(editor, "editor.julia.hints.update",
          temp)
  end
end
