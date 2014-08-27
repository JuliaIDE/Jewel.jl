# Modules

handle("editor.julia.module.update") do editor, data
  mod = data["path"] == nothing ? "Main" : Jewel.filemodule(data["path"])
  mod == "" && (mod = "Main")
  if Jewel.getthing(mod) == nothing
    notify("This file's module, `$mod`, isn't loaded yet.", class = "error")
    mod = "Main"
  end
  raise(editor, "editor.julia.module.update", mod)
end

# Profile tree

function toabspath(file)
  isabspath(file) && file
  path = basepath(file)
  return path == nothing ? file : path
end

@require Jewel.ProfileView begin
  function displayinline!(req, tree::Jewel.ProfileView.ProfileTree, bounds)
    raise(req, "julia.profile-result",
          {"value" => stringmime("text/html", tree),
           "start" => bounds[1],
           "end"   => bounds[2],
           "lines" => [{:file => toabspath(li.file),
                        :line => li.line,
                        :percent => p} for (li, p) in Jewel.ProfileView.fetch() |> Jewel.ProfileView.flatlines]})
  end
end
