#jewel module Jewel

module_usings(mod) = ccall(:jl_module_usings, Any, (Any,), mod)

accessible_names(mod = Main) =
  @as _ mod [_, module_usings(_)...] map(names, _) [_...]

packages() =
  @>> Pkg.dir() readdir filter(x->!ismatch(r"^\.|^METADATA", x))

handle("editor.julia.hints") do req, data
  editor_command(req, "hints", {:hints => [string(n) for n in accessible_names()]})
end
