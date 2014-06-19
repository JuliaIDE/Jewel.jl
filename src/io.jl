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
