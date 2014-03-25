#jewel module Jewel

const builtins = ["begin", "function", "type", "immutable", "let", "macro", "for", "while", "quote", "if", "else", "elseif", "try", "finally", "catch", "do", "end", "else", "elseif", "catch", "finally"]

module_usings(mod) = ccall(:jl_module_usings, Any, (Any,), mod)

accessible_names(mod = Main) =
  [names(mod, true, true),
   map(names, module_usings(mod))...,
   builtins] |> unique

packages() =
  @>> Pkg.dir() readdir filter(x->!ismatch(r"^\.|^METADATA$|^REQUIRE$", x))

# TODO: Module.name

handle("editor.julia.hints") do req, data
  cur_line = lines(data["code"])[data["cursor"]["line"]]

  if ismatch(r"^using ", cur_line) # Straight after using
    editor_command(req, "hints", {:hints => packages()})

  else
    mod = get_module_name(lines(data["code"]), data["cursor"]["line"])
    mod = get(Main, mod, Main)
    editor_command(req, "hints", {:hints => [string(n) for n in accessible_names(mod)]})
  end
end
