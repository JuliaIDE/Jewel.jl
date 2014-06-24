include("scope.jl")

lines(s) = split(s, "\n")

tokens(code) = scope_pass(code)
scopes(code, cursor) = scope_pass(code, collect = false, stop = true, target = cursor)
scope(code, cursor) = scopes(code, cursor)[end]

codemodule(code, pos) =
  @as _ code scopes(_, pos) filter(s->s[:type]==:module, _) map(s->s[:name], _) join(_, ".")

# some utils, not essential any more

function withoutstr(f::Function)
  orig_stdout = STDOUT
  rd, wr = redirect_stdout()
  f()
  redirect_stdout(orig_stdout)
  return readavailable(rd)
end

macro withoutstr(expr)
  :(withoutstr(()->$expr)) |> esc
end

helpstr(x) = @withoutstr help(x)
