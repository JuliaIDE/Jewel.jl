function thingorfunc(code, cursor, mod = Main)
  name = getqualifiedname(code, cursor)
  name, mod
  name == "" && (name = lastcall(scopes(code, cursor)))
  name == nothing && return
  getthing(mod, name, nothing)
end

function doc(code, cursor, mod = Main)
  docs = String[]

  thing = thingorfunc(code, cursor, mod)
  thing == nothing || push!(docs, helpstr(thing))

  texcmd = texcommand(code, cursor)
  texcmd == nothing || push!(docs, texcmd)

  help = join(docs, "\n\n")
  help in ("No help information found.\n", "") ? nothing : help
end

function texcommand(code, cursor)
  sym = string(charundercursor(code, cursor))
  cmd = get(reverse_latex_commands, sym, "")
  isempty(cmd) ? nothing : "LaTeX command for \"$(sym)\" is \"$(cmd)\"."
end

function methodsorwith(code, cursor, mod = Main)
  thing = thingorfunc(code, cursor, mod)
  thing == nothing && return
  return (isa(thing, Function) && isgeneric(thing)) || isleaftype(thing) ?
    methods(thing) :
    eval(Main, :(methodswith($(typeof(thing)), true))) # I have no idea why I thought this was necessary
end
