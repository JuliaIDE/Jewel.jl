immutable LineNumberingReader{T<:IO} <: IO
  io::T
  lines::Vector{Int}
end
LineNumberingReader(io::IO) = LineNumberingReader(io, [0])
LineNumberingReader(s::String) = LineNumberingReader(IOBuffer(s))

Base.eof(r::LineNumberingReader) = eof(r.io)
Base.position(r::LineNumberingReader) = position(r.io)
Base.peek(r::LineNumberingReader) = Base.peek(r.io)

function Base.skip(r::LineNumberingReader, n::Integer)
  # Could be more efficient
  if n > 0 && position(r) + n > r.lines[end]
    @dotimes n read(r, Uint8)
  else
    skip(r.io, n)
  end
end

Base.seek(io::LineNumberingReader, pos) =
  pos <= io.lines[end] ? seek(io.io, pos) : skip(io, pos-position(io))

function Base.read(r::LineNumberingReader, ::Type{Uint8})
  c = read(r.io, Uint8)
  c == '\n' && position(r.io) > last(r.lines) &&
    push!(r.lines, position(r.io))
  return c
end

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

column(s::LineNumberingReader) = position(s) - s.lines[line(s)] + 1

linecol(s::LineNumberingReader) = LineCol(line(s), column(s))

immutable LineCol
  line::Int
  column::Int
end

Base.isless(x::LineCol, y::LineCol) =
  x.line < y.line || (x.line == y.line && x.column < y.column)
