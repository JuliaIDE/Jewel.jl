export getthing

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

getthing(mod::Module, name::String, default = nothing) =
  @as _ name split(_, ".") map(symbol, _) getthing(mod, _, default)

getthing(name::String, default = nothing) =
  getthing(Main, name, default)

# include_string with line numbers

function Base.include_string(s::String, fname::String, line::Integer)
  include_string("\n"^(line-1)*s, fname)
end

function Base.include_string(mod::Module, args...)
  eval(mod, :(include_string($(args...))))
end

# Get the current module for a file/pos

function get_module(file::String, code::String, pos)
  filem = file_module(file)
  codem = code_module(code, pos)
  modstr = (codem != "" && filem != "") ? "$codem.$filem" :
           codem == "" ? filem : codem
  getthing(modstr, Main)
end
