# Modules

handle("editor.julia.module.update") do editor, data
  mod = data["path"] == nothing ? "Main" : Jewel.filemodule(data["path"])
  mod == "" && (mod = "Main")
  if Jewel.getthing(mod) == nothing
    notify("This file's module, `$mod`, isn't loaded yet.", class = "error")
    mod = "Main"
  end
  raise(editor, "julia.set-module", mod)
  raise(global_client, "julia.set-modules", {:modules => [string(m) for m in Jewel.allchildren(Main)]})
end
