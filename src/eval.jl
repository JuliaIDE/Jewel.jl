export get_thing

# Qualified names → objects

function get_thing(mod::Module, name::Vector{Symbol}, default = nothing)
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

get_thing(name::Vector{Symbol}, default = nothing) =
  get_thing(Main, name, default)

get_thing(mod::Module, name::String, default = nothing) =
  @as _ name split(_, ".") map(symbol, _) get_thing(mod, _, default)

get_thing(name::String, default = nothing) =
  get_thing(Main, name, default)

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
  get_thing(modstr, Main)
end
