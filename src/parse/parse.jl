include("scope.jl")
include("block.jl")

lines(s) = split(s, "\n")

tokens(code, cursor = (0, 0)) = scope_pass(code, target = cursor)
scopes(code, cursor) = scope_pass(code, collect = false, stop = true, target = cursor)
scope(code, cursor) = scopes(code, cursor)[end]

codemodule(code, pos) =
  @as _ code scopes(_, pos) filter(s->s[:type]==:module, _) map(s->s[:name], _) join(_, ".")

precursor(s::String, i) = join(collect(s)[1:(i-1 <= length(s) ? i-1 : end)])
postcursor(s::String, i) = join(collect(s)[i:end])

function getblockcursor(code, line, cursor)
  code, bounds = getblock(code, line)
  code, bounds, (cursor[1]-bounds[1]+1, cursor[2])
end

getblockcursor(code, cursor) = getblockcursor(code, cursor[1], cursor)

charundercursor(code, cursor) = get(collect(lines(code)[cursor[1]]), cursor[2], ' ')

function matchorempty(args...)
  result = match(args...)
  result == nothing ? "" : result.match
end

function getqualifiedname(str::String, index::Integer)
  pre = precursor(str, index)
  post = postcursor(str, index)

  pre = matchorempty(Regex("(?:$(identifier.pattern)\\.)*(?:$(identifier.pattern))\\.?\$"), pre)

  beginning = pre == "" || last(pre) == '.'
  post = matchorempty(Regex("^$(beginning ? identifier.pattern : identifier_inner.pattern*"*")"), post)

  if beginning && post == ""
    return pre
  else
    return pre * post
  end
end

# could be more efficient
getqualifiedname(str::String, cursor) = getqualifiedname(lines(str)[cursor[1]], cursor[2])

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
