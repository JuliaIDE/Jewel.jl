function thingorfunc(code, cursor, mod = Main; name = getqualifiedname(code, cursor))
  name == "" && (name = lastcall(scopes(code, cursor)))
  name == nothing ? name : getthing(mod, name, nothing)
end

function doc(code, cursor, mod = Main)
  docs = AbstractString[]
  name = getqualifiedname(code, cursor)

  thing = thingorfunc(code, cursor, mod; name = name)
  thing == nothing || push!(docs, sprint(Base.help, thing))

  texcmds = texcommands(name, code, cursor)
  texcmds == nothing || push!(docs, texcmds)

  help = join(docs, "\n\n")
  help in ("No help information found.\n", "") ? nothing : help
end

function texcommands(name, code, cursor)
  chars = collect(name)
  if isempty(chars) # fallback if getqualifiedname failed
    line = collect(lines(code)[cursor.line])
    c = cursor.column
    chars = line[max(c - 1, 1):min(c, length(line))]
  end

  syms = AbstractString[]
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
  return thing == Module ? methodswith(Module) :
         (isa(thing, Function) && isgeneric(thing)) || isleaftype(thing) ? methods(thing) :
         eval(Main, :(methodswith($(typeof(thing)), true))) # I have no idea why I thought this was necessary
end
