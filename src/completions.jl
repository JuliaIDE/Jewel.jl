export completions, allcompletions, complete

const builtins = ["begin", "function", "type", "immutable", "let", "macro",
                  "for", "while", "quote", "if", "else", "elseif", "try",
                  "finally", "catch", "do", "end", "else", "elseif", "catch",
                  "finally", "true", "false", "using"]

identifier_completions(hints; textual = true) =
  {:hints => hints,
   :pattern => identifier,
   :textual => textual}

identifier_completions(; textual = true) =
  identifier_completions(UTF8String[], textual)

"""
Takes a block of code and a cursor and returns autocomplete data.
"""
function completions(code, cursor, mod = Main)
  line = precursor(lines(code)[cursor[1]], cursor[2])
  if islatexinput(line)
    {:hints => latex_completions,
     :pattern => r"\\[a-zA-Z0-9^_]*",
     :textual => false}
  elseif (sc = scope(code, cursor))[:type] in (:string, :multiline_string, :comment, :multiline_comment)
    nothing
  elseif (q = qualifier(line)) != nothing
    thing = getthing(mod, q, nothing)
    if isa(thing, Module)
      identifier_completions((@> thing names(true) filtervalid),
                              textual = false)
    elseif thing != nothing && sc[:type] == :toplevel
      identifier_completions((@> thing names filtervalid),
                              textual = false)
    end
  elseif sc[:type] == :call
    f = getthing(sc[:name], mod)
    haskey(fncompletions, f) || @goto default
    fncompletions[f]()
  else
    @label default
    identifier_completions(accessible(mod))
  end
end

"""
Takes a file of code and a cursor and returns autocomplete data.
"""
function allcompletions(code, cursor, mod = Main)
  block, _, cursor = getblockcursor(code, cursor)
  cs = completions(block, cursor, mod) # need to take into account codemodule
  cs == nothing && return nothing
  if !haskey(cs, :textual) || cs[:textual]
    cs[:hints] = [cs[:hints], tokens(code)]
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

# Path completions

path_completions(path, root = true) =
  [path == "" ? readdir(pwd()) : [path*name for name in readdir(path)],
   root ? path_completions("/", false) : []]

# Package manager completions

packages(dir = Pkg.dir()) =
  @>> dir readdir filter(x->!ismatch(r"^\.|^METADATA$|^REQUIRE$", x))

all_packages() = packages(Pkg.dir("METADATA"))

required_packages() =
  @>> Pkg.dir("REQUIRE") readall lines

available_packages() = setdiff(all_packages(), required_packages())

complete(Pkg.add) do
  :add
end

# What about completing `using`?
