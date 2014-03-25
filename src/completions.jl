#jewel module Jewel

const builtins = ["begin", "function", "type", "immutable", "let", "macro", "for", "while", "quote", "if", "else", "elseif", "try", "finally", "catch", "do", "end", "else", "elseif", "catch", "finally", "true", "false"]

module_usings(mod) = ccall(:jl_module_usings, Any, (Any,), mod)

accessible_names(mod = Main) =
  [names(mod, true, true),
   map(names, module_usings(mod))...,
   builtins] |> unique

packages() =
  @>> Pkg.dir() readdir filter(x->!ismatch(r"^\.|^METADATA$|^REQUIRE$", x))

function get_submodule(mod, names)
  sub = nothing
  for m in names
    sub = get(mod, m, nothing)
    sub == nothing && break
  end
  return sub
end

handle("editor.julia.hints") do req, data
  cur_line = lines(data["code"])[data["cursor"]["line"]]
  qualified = @> cur_line get_qualified_name(data["cursor"]["col"]) split(".") (x->map(symbol, x))

  ismatch(r"^using ", cur_line) && # Straight after using
    return editor_command(req, "hints", {:hints => packages()})

  mod = get_module_name(lines(data["code"]), data["cursor"]["line"])
  mod = get(Main, mod, Main)

  if length(qualified) > 1
    sub = get_submodule(mod, qualified[1:end-1])
    sub != nothing &&
      return editor_command(req, "hints", {:hints => [string(n) for n in names(sub, true)], :notextual => true})
  end

  return editor_command(req, "hints", {:hints => [string(n) for n in accessible_names(mod)]})
end
