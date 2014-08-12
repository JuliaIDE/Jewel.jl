module LNR

using Lazy
import Base: seek

export LineNumberingReader, line, column, Cursor, cursor, seekline, seekcol

# Cursor Type

immutable Cursor
  line::Int
  column::Int
end

Base.isless(x::Cursor, y::Cursor) =
  x.line < y.line || (x.line == y.line && x.column < y.column)

# LNR

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

# Seeking

function seek(r::LineNumberingReader, pos)
  scannedindex(r, pos) ? seek(r.io, pos) : skip(r, pos-position(r))
  return r
end

function seekline(r::LineNumberingReader, line::Integer)
  line ≤ length(r.lines) && return seek(r, r.lines[line]-1)
  while r.lines[end] < line && !eof(r)
    readline(r)
  end
  return r
end

seekline(r::LineNumberingReader) = seekline(r, line(r))

function seekcol(r::LineNumberingReader, col::Integer)
  seekline(r)
  c = 1
  while c < col && !eof(r)
    read(r, Char) == '\n' && return skip(r,-1)
    c += 1
  end
  return r
end

seek(r::LineNumberingReader, c::Cursor) =
  @> r seekline(c.line) seekcol(c.column)

# Cursor finding

function line(s::LineNumberingReader)
  p = position(s)+1 # after the cursor
  for i = 1:length(s.lines)
    s.lines[i] > p && return i - 1
  end
  return length(s.lines)
end

function column(r::LineNumberingReader)
  pos = position(r)
  col = 1
  seekline(r)
  while position(r) < pos
    read(r, Char)
    col += 1
  end
  return col
end

cursor(s::LineNumberingReader) = Cursor(line(s), column(s))
cursor(l, c) = Cursor(l, c)

# Util

function withstream(f, io)
  pos = position(stream)
  try
    f()
  finally
    seek(stream, pos)
  end
end

end
