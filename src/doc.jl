function thingorfunc(code, cursor, mod = Main)
  name = getqualifiedname(code, cursor)
  name, mod
  name == "" && (name = lastcall(scopes(code, cursor)))
  name == nothing && return
  getthing(mod, name, nothing)
end

function doc(code, cursor, mod = Main)
  thing = thingorfunc(code, cursor, mod)
  thing == nothing && return
  help = helpstr(thing)
  help != "No help information found.\n" && return help
  return
end

function methodsorwith(code, cursor, mod = Main)
  thing = thingorfunc(code, cursor, mod)
  thing == nothing && return
  return (isa(thing, Function) && isgeneric(thing)) || isleaftype(thing) ?
    methods(thing) :
    eval(Main, :(methodswith($(typeof(thing)), true))) # I have no idea why I thought this was necessary
end
