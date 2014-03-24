#jewel module Jewel

Base.in(name::Symbol, m::Module) = isdefined(m, name)

Base.get(m::Module, name) = m.(name)

Base.get(m::Module, name::Symbol, default) =
  name in m ? get(m, name) : default

Base.get(m::Module, name, default) = default

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
