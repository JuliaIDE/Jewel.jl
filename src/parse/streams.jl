import Base: peek

const whitespace = " \t"

function skipwhitespace(io::IO; newlines = true)
  while !eof(io) && (peek(io) in whitespace || (newlines && peek(io) == '\n'))
    read(io, Char)
  end
  return io
end

function startswith(stream::IO, s::AbstractString; eat = true, padding = false)
  start = position(stream)
  padding && skipwhitespace(stream)
  result = true
  for char in s
    !eof(stream) && read(stream, Char) == char ||
      (result = false; break)
  end
  !(result && eat) && seek(stream, start)
  return result
end

function startswith(stream::IO, c::Char; eat = true)
  if peek(stream) == c
    eat && read(stream, Char)
    return true
  else
    return false
  end
end

function startswith{T<:AbstractString}(stream::IO, ss::Vector{T}; eat = true)
  for s in ss
    startswith(stream, s, eat = eat) && return true
  end
  return false
end

function startswith(stream::IO, r::Regex; eat = true, padding = false)
  @assert beginswith(r.pattern, "^")
  start = position(stream)
  padding && skipwhitespace(stream)
  line = chomp(readline(stream))
  seek(stream, start)
  m = match(r, line)
  m == nothing && return ""
  eat && @dotimes length(m.match) read(stream, Char)
  return m.match
end

function peekbehind(stream::IO, offset = 0)
  c = '\0'
  skip(stream, offset)
  if position(stream) > 0
    skip(stream, -1)
    c = read(stream, Char)
  end
  skip(stream, -offset)
  return c
end
