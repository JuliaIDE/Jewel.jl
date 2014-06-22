const builtins = ["begin", "function", "type", "immutable", "let", "macro",
                  "for", "while", "quote", "if", "else", "elseif", "try",
                  "finally", "catch", "do", "end", "else", "elseif", "catch",
                  "finally", "true", "false", "using"]

module_usings(mod) = ccall(:jl_module_usings, Any, (Any,), mod)

filter_valid(names) =
  filter(x->!ismatch(r"#", x), [string(x) for x in names])

accessible_names(mod::Module = Main) =
  [names(mod, true, true),
   map(names, module_usings(mod))...,
   builtins] |> unique |> filter_valid

accessible_names(m) = accessible_names(get_thing(m, Main))

const completions = Dict{String,Function}()

complete(f, s) = completions[s] = f

const tab_length = 8

tabpad(s, ts) = s * "\t"^max((ts - length(s)÷tab_length), 1)

const latex_completions = [{:completion => completion, :text => tabpad(text, 2) * completion}
                           for (text, completion) in Base.REPLCompletions.latex_symbols]

function islatexinput(str::String, index)
  pre = str[1:(index-1 <= endof(str) ? index-1 : end)]
  ismatch(r"\\[a-zA-Z0-9_^]*$", pre)
end

handle("editor.julia.hints") do req, data
  cur_line = lines(data["code"])[data["cursor"]["line"]]
  cur_line |> isempty && return
  pos = data["cursor"]["col"]

  if islatexinput(cur_line, pos)
    return raise(req, "editor.julia.hints.update", {:hints => latex_completions,
                                                    :notextual => true,
                                                    :pattern => r"\\[a-zA-Z0-9^_]*".pattern})
  end

  mod = get_module_name(data)
  mod = get_thing(mod, Main)

  qualified = @as _ cur_line get_qualified_name(_, pos) split(_, ".") map(symbol, _)

  # Module.name completions
  if length(qualified) > 1
    sub = get_thing(mod, qualified[1:end-1])
    isa(sub, Module) &&
      return raise(req, "editor.julia.hints.update", {:hints => filter_valid(names(sub, true)),
                                                      :notextual => true})
    # Experimental – complete fields of a type
    # Should only work in global scope
    return raise(req, "editor.julia.hints.update", {:hints => filter_valid(names(typeof(sub))),
                                                    :notextual => true})
  end

  # Specific completions
  for (s, f) in completions
    ret = f(cur_line, pos)
    ret in (nothing, false) || return raise(req, "editor.julia.hints.update", ret)
  end

  # Otherwise, suggest all accessible names
  return raise(req, "editor.julia.hints.update", {:hints => accessible_names(mod)})
end

# Path completions

path_completions(path, root = true) =
  [path == "" ? readdir(pwd()) : [path*name for name in readdir(path)],
   root ? path_completions("/", false) : []]

# Package Completions

packages(dir = Pkg.dir()) =
  @>> dir readdir filter(x->!ismatch(r"^\.|^METADATA$|^REQUIRE$", x))

all_packages() = packages(Pkg.dir("METADATA"))

required_packages() =
  @>> Pkg.dir("REQUIRE") readall lines

available_packages() = setdiff(all_packages(), required_packages())

complete("using") do line, pos
  beginswith(line, "using ") &&
    {:hints => packages(), :notextual => true}
end

complete("pkg-add") do line, pos
  beginswith(line, "Pkg.add(") &&
    {:hints => available_packages(), :notextual => true}
end

complete("pkg-rm") do line, pos
  beginswith(line, "Pkg.rm(") &&
    {:hints => required_packages(), :notextual => true}
end
