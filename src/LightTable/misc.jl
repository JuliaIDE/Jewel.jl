# Modules

handle("editor.julia.module.update") do editor, data
  mod = data["path"] == nothing ? "Main" : Jewel.filemodule(data["path"])
  mod == "" && (mod = "Main")
  if Jewel.getthing(mod) == nothing
    notify("This file's module, `$mod`, isn't loaded yet.", class = "error")
    mod = "Main"
  end
  raise(editor, "julia.set-module", mod)
raise(global_client, "julia.set-modules", @compat Dict(:modules => [string(m) for m in Jewel.allchildren(Main)]))
end

# Browser

objs(mod) =
  @>> mod begin
    (m->names(m, true))
    map(n->@compat Any[n, Jewel.getthing(mod, [n])])
    filter(p->!isa(p[2], Module) && p[2] ≠ nothing && !ismatch(r"#", string(p[1])))
    map(p-> @compat [p[1], applydisplayinline(p[2])])
    map(p-> @compat [p[1], stringmime(bestmime(p[2]), p[2])])
    xs->sort(xs, by = first)
  end

handle("browser.get-objects") do browser, data
  mod = data["module"] == nothing ? Main : Jewel.getthing(data["module"])
  raise(browser, "update", @compat Dict(:objs => objs(mod)))
end
