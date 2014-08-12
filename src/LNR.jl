module LNR

using Lazy

export LineNumberingReader, line, column, Cursor, cursor, seekline

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

Base.seek(r::LineNumberingReader, pos) =
  scannedindex(r, pos) ? seek(r.io, pos) : skip(r, pos-position(r))

function seekline(r::LineNumberingReader, line::Int)
  line ≤ length(r.lines) && return seek(r, r.lines[line]-1)
  while r.lines[end] < line
    readline(r)
  end
  return r
end

seekline(r::LineNumberingReader) = seekline(r, line(r))

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
  seekstartofline(r)
  while position(r) < pos
    read(r, Char)
    col += 1
  end
  return col
end

# Cursor Type

immutable Cursor
  line::Int
  column::Int
end

cursor(s::LineNumberingReader) = Cursor(line(s), column(s))
cursor(l, c) = Cursor(l, c)

Base.isless(x::Cursor, y::Cursor) =
  x.line < y.line || (x.line == y.line && x.column < y.column)

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
