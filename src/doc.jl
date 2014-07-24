function thingorfunc(code::String, cursor::(Int,Int), mod::Module = Main)
  name = getqualifiedname(code, cursor)
  thingorfunc(name, code, cursor, mod)
end

function thingorfunc(name::String, code::String, cursor::(Int,Int), mod::Module = Main)
  name == "" && (name = lastcall(scopes(code, cursor)))
  name == nothing ? name : getthing(mod, name, nothing)
end

function doc(code, cursor, mod = Main)
  docs = String[]
  name = getqualifiedname(code, cursor)

  thing = thingorfunc(name, code, cursor, mod)
  thing == nothing || push!(docs, helpstr(thing))

  texcmds = texcommands(name, code, cursor)
  texcmds == nothing || push!(docs, texcmds)

  help = join(docs, "\n\n")
  help in ("No help information found.\n", "") ? nothing : help
end

function texcommands(name, code, cursor)
  chars = collect(name)
  if isempty(chars) # fallback if getqualifiedname failed
    line = collect(lines(code)[cursor[1]])
    c = cursor[2]
    chars = line[(c < 2 ? 1 : c - 1):(c <= length(line) ? c : end)]
  end

  syms = String[]
  for char in chars
    cmd = get(reverse_latex_commands, char, "")
    isempty(cmd) || push!(syms, "  $(char)\u00a0 $(cmd)")
  end
  isempty(syms) && return

  "LaTeX command$(length(syms) > 1 ? "s" : ""):\n\n$(join(unique(syms), "\n"))"
end

function methodsorwith(code, cursor, mod = Main)
  thing = thingorfunc(code, cursor, mod)
  thing == nothing && return
  return (isa(thing, Function) && isgeneric(thing)) || isleaftype(thing) ?
    methods(thing) :
    eval(Main, :(methodswith($(typeof(thing)), true))) # I have no idea why I thought this was necessary
end
