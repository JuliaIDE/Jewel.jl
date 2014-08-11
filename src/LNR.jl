module LNR

using Lazy

export LineNumberingReader, line, column, Cursor, cursor

immutable LineNumberingReader{T<:IO} <: IO
  io::T
  lines::Vector{Int} # The byte index of the first char in each line
end

LineNumberingReader(io::IO) = LineNumberingReader(io, [1])
LineNumberingReader(s::String) = LineNumberingReader(IOBuffer(s))

Base.eof(r::LineNumberingReader) = eof(r.io)
Base.position(r::LineNumberingReader) = position(r.io)
Base.peek(r::LineNumberingReader) = Base.peek(r.io)

scannedindex(r::LineNumberingReader, i) = i < r.lines[end]

function Base.read(r::LineNumberingReader, ::Type{Uint8})
  c = read(r.io, Uint8)
  c == '\n' && !scannedindex(r, position(r)) && !eof(r) &&
     push!(r.lines, position(r)+1)
  return c
end

function Base.skip(r::LineNumberingReader, n::Integer)
  if n > 0 && !scannedindex(r, position(r) + n)
    @dotimes n read(r, Uint8)
  else
    skip(r.io, n)
  end
end

Base.seek(r::LineNumberingReader, pos) =
  scannedindex(r, pos) ? seek(r.io, pos) : skip(r, pos-position(r))

# Cursor finding

function line(s::LineNumberingReader)
  p = position(s)+1 # after the cursor
  for i = 1:length(s.lines)
    s.lines[i] > p && return i - 1
  end
  return length(s.lines)
end

# This won't handle unicode properly
column(s::LineNumberingReader) = position(s)+1 - (s.lines[line(s)]-1)

immutable Cursor
  line::Int
  column::Int
end

cursor(s::LineNumberingReader) = Cursor(line(s), column(s))
cursor(l, c) = Cursor(l, c)

Base.isless(x::Cursor, y::Cursor) =
  x.line < y.line || (x.line == y.line && x.column < y.column)

end
