# Qualified names → objects

function getthing(mod::Module, name::Vector{Symbol}, default = nothing)
  thing = mod
  for sym in name
    if isdefined(thing, sym)
      thing = thing.(sym)
    else
      return default
    end
  end
  return thing
end

getthing(name::Vector{Symbol}, default = nothing) =
  getthing(Main, name, default)

getthing(mod::Module, name::AbstractString, default = nothing) =
  name == "" ?
    default :
    @as _ name split(_, ".", keep=false) map(symbol, _) getthing(mod, _, default)

getthing(name::AbstractString, default = nothing) =
  getthing(Main, name, default)

getthing(::Void, default) = default
getthing(mod, ::Void, default) = default

# include_string with line numbers

function Base.include_string(s::AbstractString, fname::AbstractString, line::Integer)
  include_string("\n"^(line-1)*s, fname)
end

function Base.include_string(mod::Module, args...)
  eval(mod, :(include_string($(args...))))
end

# Get the current module for a file/pos

function getmodule(code, pos; filemod = nothing)
  codem = codemodule(code, pos)
  modstr = (codem != "" && filemod != nothing) ? "$filemod.$codem" :
           codem == "" ? filemod : codem
  getthing(modstr, Main)
end
