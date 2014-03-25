#jewel module Jewel

const builtins = ["begin", "function", "type", "immutable", "let", "macro",
                  "for", "while", "quote", "if", "else", "elseif", "try",
                  "finally", "catch", "do", "end", "else", "elseif", "catch",
                  "finally", "true", "false", "using"]

module_usings(mod) = ccall(:jl_module_usings, Any, (Any,), mod)

filter_valid(names) =
  filter(x->!ismatch(r"[\W]", x), [string(x) for x in names])

accessible_names(mod = Main) =
  [names(mod, true, true),
   map(names, module_usings(mod))...,
   builtins] |> unique |> filter_valid

function get_submodule(mod, names)
  sub = nothing
  for m in names
    sub = get(mod, m, nothing)
    sub == nothing && break
  end
  return sub
end

const completions = Dict{String,Function}()

complete(f, s) = completions[s] = f

handle("editor.julia.hints") do req, data
  cur_line = lines(data["code"])[data["cursor"]["line"]]
  cur_line |> isempty && return
  pos = data["cursor"]["col"]

  mod = get_module_name(lines(data["code"]), data["cursor"]["line"])
  mod = get(Main, mod, Main)

  qualified = @> cur_line get_qualified_name(pos) split(".") (x->map(symbol, x))

  # Module.name completions
  if length(qualified) > 1
    sub = get_submodule(mod, qualified[1:end-1])
    sub != nothing &&
      return editor_command(req, "hints", {:hints => [string(n) for n in names(sub, true)], :notextual => true})
  end

  # Specific completions
  for (s, f) in completions
    ret = f(cur_line, pos)
    ret in (nothing, false) || return editor_command(req, "hints", ret)
  end

  # Otherwise, suggest all accessible names
  return editor_command(req, "hints", {:hints => [string(n) for n in accessible_names(mod)]})
end

# Package Completions

packages(dir = Pkg.dir()) =
  @>> dir readdir filter(x->!ismatch(r"^\.|^METADATA$|^REQUIRE$", x))

complete("using") do line, pos
  beginswith(line, "using ") &&
    {:hints => packages(), :notextual => true}
end

all_packages() = packages(Pkg.dir("METADATA"))

complete("pkg-add") do line, pos
  beginswith(line, "Pkg.add(") &&
    {:hints => all_packages(), :notextual => true}
end

req_packages() =
  @>> Pkg.dir("REQUIRE") readall lines

complete("pkg-rm") do line, pos
  beginswith(line, "Pkg.rm(") &&
    {:hints => req_packages(), :notextual => true}
end
