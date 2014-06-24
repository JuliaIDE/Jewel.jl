const builtins = ["begin", "function", "type", "immutable", "let", "macro",
                  "for", "while", "quote", "if", "else", "elseif", "try",
                  "finally", "catch", "do", "end", "else", "elseif", "catch",
                  "finally", "true", "false", "using"]

function completions(code, cursor, mod = Main)
  line = precursor(lines(code)[cursor[1]], cursor[2])
  # latex
  if islatexinput(line)
    {:kind => :latex,
     :hints => latex_completions,
     :pattern => r"\\[a-zA-Z0-9^_]*"}
  elseif (sc = scope(code, cursor))[:type] in (:string, :multiline_string, :comment, :multiline_comment)
    nothing
  elseif (q = qualifier(line)) != nothing
    thing = getthing(mod, q, nothing)
    if isa(thing, Module)
      {:kind => :identifier,
       :hints => (@> thing names(true) filtervalid),
       :pattern => identifier,
       :textual => false}
    end
  end
end

# Module completions
# ––––––––––––––––––

moduleusings(mod) = ccall(:jl_module_usings, Any, (Any,), mod)

# filtervalid(names) =
#   filter(x->!ismatch(r"#", x), [string(x) for x in names])

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
