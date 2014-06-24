include("scope.jl")

lines(s) = split(s, "\n")

tokens(s) = scope_pass(s)
scopes(s, cursor) = scope_pass(s, collect = false, stop = true, target = cursor)
scope(s, cursor) = scopes(s, cursor)[end]

# some utils, not essential any more

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

