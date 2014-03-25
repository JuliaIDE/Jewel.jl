#jewel module Jewel

# Modules

import Base: in, get

in(name::Symbol, m::Module) = isdefined(m, name)

get(m::Module, name::Symbol) = m.(name)

get(m::Module, name::Symbol, default) =
  name in m ? get(m, name) : default

get(m::Module, name::String, args...) = get(m, symbol(name), args...)

get(m::Module, name, default) = default

get(::Nothing, args...) = get(Main, args...)

function get_thing(mod::Module, name::Vector{Symbol})
  sub = mod
  for i = 1:length(name)
    sub = get(sub, m, nothing)
    !isa(sub, Module) && i < length(name) && return nothing
  end
  return sub
end

get_thing(mod, names::String...) =
  @as _ names join(_, ".") split(_, ".") map(symbol, _) get_thing(mod, _)

get_thing(names::String...) =
  @as _ names join(_, ".") get_thing

get_thing(::Nothing, args...) = get_thing(Main, args...)

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
