#jewel module Jewel

# Modules

import Base: in, get

in(name::Symbol, m::Module) = isdefined(m, name)

get(m::Module, name::Symbol) = m.(name)

get(m::Module, name::Symbol, default) =
  name in m ? get(m, name) : default

get(m::Module, name::String, args...) = get(m, symbol(name), args...)

get(m::Module, name, default) = default

function get_thing(mod, name::Vector{Symbol})
  sub = mod
  for m in name
    sub = get(sub, m, nothing)
    sub == nothing && break
  end
  return sub
end

get_thing(mod, name::String) =
  @as _ name split(_, ".") map(symbol, _) get_thing(mod, _)

get_thing(name::String) = get_thing(Main, name)

get_thing(names::String...) =
  @as _ names join(_, ".") get_thing

# Text

lines(s) = split(s, "\n")

function with_out_str(f::Function)
  orig_stdout = STDOUT
  rd, wr = redirect_stdout()
  f()
  redirect_stdout(orig_stdout)
  return readavailable(rd)
end

macro with_out_str(expr)
  :(with_out_str(()->$expr)) |> esc
end

help_str(x) = @with_out_str help(x)
