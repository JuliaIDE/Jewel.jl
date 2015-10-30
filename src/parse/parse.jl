using MacroTools

include("scope.jl")
include("block.jl")

lines(s) = split(s, "\n")

codemodule(code, pos) =
  @as _ code scopes(_, pos) filter(s->s.kind==:module, _) map(s->s.name, _) join(_, ".")

precursor(s::AbstractString, i) = join(collect(s)[1:min(i-1, end)])
postcursor(s::AbstractString, i) = join(collect(s)[i:end])

function getblockcursor(code, line, c)
  code, bounds = getblock(code, line)
  code, bounds, cursor(c.line-bounds[1]+1, c.column)
end

getblockcursor(code, cursor) = getblockcursor(code, cursor.line, cursor)

charundercursor(code, cursor) = get(collect(lines(code)[cursor.line]), cursor.column, ' ')

function matchorempty(args...)
  result = match(args...)
  result == nothing ? "" : result.match
end

function getqualifiedname(str::AbstractString, index::Integer)
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
getqualifiedname(str::AbstractString, cursor) = getqualifiedname(lines(str)[cursor.line], cursor.column)

function isdefinition(code::AbstractString)
  try
    code = parse(code)
    return isexpr(code, :function) || (isexpr(code, :(=)) && isexpr(code.args[1], :call))
  catch e
    return false
  end
end

:(a() = b).args[1].head
