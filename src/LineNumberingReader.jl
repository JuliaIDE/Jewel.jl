immutable LineNumberingReader{T<:IO} <: IO
  io::T
  lines::Vector{Int}
end
LineNumberingReader(io::IO) = LineNumberingReader(io, [0])

Base.eof(r::LineNumberingReader) = eof(r.io)
# Base.skip(r::LineNumberingReader, n::Integer) = skip(r.io, n)
Base.position(r::LineNumberingReader) = position(r.io)

function Base.read(r::LineNumberingReader, ::Type{Char})
  c = read(r.io, Char)
  c == '\n' && position(r.io) > last(r.lines) &&
    push!(r.lines, position(r.io))
  return c
end

# The line / column number of the next character
function line(s::LineNumberingReader)
  p = position(s)
  for i = 1:length(s.lines)
    s.lines[i] > p && return i - 1
  end
  return length(s.lines)
end

column(s::LineNumberingReader) = position(s) - s.lines[line(s)]
