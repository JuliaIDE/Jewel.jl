export completions, allcompletions, complete

const builtins = ["abstract", "baremodule", "begin", "bitstype", "break",
                  "catch", "ccall", "const", "continue", "do", "else",
                  "elseif", "end", "export", "finally", "for", "function",
                  "global", "if", "immutable", "import", "importall", "let",
                  "local", "macro", "module", "quote", "return", "try", "type",
                  "typealias", "using", "while"]

identifier_completions(hints; textual = true) =
  {:hints => hints,
   :pattern => identifier,
   :textual => textual}

identifier_completions(; textual = true) =
  identifier_completions(UTF8String[], textual)

function lastcall(scopes)
  for i = length(scopes):-1:1
    scopes[i][:type] == :call && return scopes[i][:name]
  end
end

"""
Takes a block of code and a cursor and returns autocomplete data.
"""
function completions(code, cursor; mod = Main, file = nothing)
  line = precursor(lines(code)[cursor[1]], cursor[2])
  scs = scopes(code, cursor)
  sc = scs[end]
  call = lastcall(scs)

  while true # TODO: use gotos once they've been around for a while
    if islatexinput(line)
      return {:hints => latex_completions,
              :pattern => r"\\[a-zA-Z0-9^_]*",
              :textual => false}
    elseif sc[:type] == :using
      return pkg_completions(packages())
    elseif call != nothing
      f = getthing(call, mod)
      haskey(fncompletions, f) || break
      return fncompletions[f]({:mod => mod,
                               :file => file,
                               :input => precursor(line, cursor[2])})
    elseif sc[:type] in (:string, :multiline_string, :comment, :multiline_comment)
      return nothing
    elseif (q = qualifier(line)) != nothing
      thing = getthing(mod, q, nothing)
      if isa(thing, Module)
        return identifier_completions((@> thing names(true) filtervalid),
                                      textual = false)
      elseif thing != nothing && sc[:type] == :toplevel
        return identifier_completions((@> thing names filtervalid),
                                      textual = false)
      end
    end
  end
  identifier_completions(accessible(mod))
end

"""
Takes a file of code and a cursor and returns autocomplete data.
"""
function allcompletions(code, cursor; mod = Main, file = nothing)
  block, _, cursor = getblockcursor(code, cursor)
  cs = completions(block, cursor, mod = mod, file = file) # need to take into account codemodule
  cs == nothing && return nothing
  if !haskey(cs, :textual) || cs[:textual]
    ts = tokens(code)
    hints = cs[:hints]
    for t in ts
      push!(hints, t)
    end
  end
  return cs
end

# Module completions
# ––––––––––––––––––

moduleusings(mod) = ccall(:jl_module_usings, Any, (Any,), mod)

filtervalid(names) = @>> names map(string) filter(x->!ismatch(r"#", x))

accessible(mod::Module) =
  [names(mod, true, true),
   map(names, moduleusings(mod))...,
   builtins] |> unique |> filtervalid

function qualifier(s)
  m = match(Regex("((?:$(identifier.pattern)\\.)+)(?:$(identifier.pattern))?\$"), s)
  m == nothing ? m : m.captures[1]
end

# Latex completions
# –––––––––––––––––

const tab_length = 8

tabpad(s, ts) = s * "\t"^max((ts - length(s)÷tab_length), 1)

const latex_completions =
  [{:completion => completion, :text => tabpad(text, 2) * completion}
   for (text, completion) in Base.REPLCompletions.latex_symbols]

islatexinput(str::String) =
  ismatch(r"\\[a-zA-Z0-9_^]*$", str)

# Custom completions
# ––––––––––––––––––

const fncompletions = Dict{Function,Function}()

complete(completions::Function, f::Function) =
  fncompletions[f] = completions

# Include completions
# TODO: cd completions

const pathpattern = r"[a-zA-Z0-9_\.\\/]*"

includepaths(path) =
  @>> dirsnearby(path, ascend = 0) jl_files map(p->p[length(path)+2:end])

includepaths(Pkg.dir("Jewel", "src"))

complete(include) do info
  file = info[:file]
  dir = file == nothing ? pwd() : dirname(file)
  {:hints => includepaths(dir),
   :pattern => pathpattern,
   :textual => false}
end

# Package manager completions

packages(dir = Pkg.dir()) =
  @>> dir readdir filter(x->!ismatch(r"^\.|^METADATA$|^REQUIRE$", x))

all_packages() = packages(Pkg.dir("METADATA"))

required_packages() =
  @>> Pkg.dir("REQUIRE") readall lines

unused_packages() = setdiff(all_packages(), required_packages())

pkg_completions(hints) =
  {:hints => hints,
   :pattern => r"[a-zA-Z0-9]*",
   :textual => false}

for f in (Pkg.add, Pkg.clone)
  complete(f) do _
    pkg_completions(unused_packages())
  end
end

for f in (Pkg.checkout, Pkg.free, Pkg.rm, Pkg.publish, Pkg.build, Pkg.test)
  complete(f) do _
    pkg_completions(packages())
  end
end

# What about completing `using`?
