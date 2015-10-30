# Extract blocks of code from a file

isblank(s) = ismatch(r"^\s*(#.*)?$", s)
isend(s) = ismatch(r"^end\b", s)
iscont(s) = ismatch(r"^(else|elseif|catch|finally)\b", s)
isstart(s) = !(ismatch(r"^\s", s) || isblank(s) || isend(s) || iscont(s))

# Find to the start of this block.
function walkback(code::Vector, line)
  while line > 1 && !isstart(code[line])
    line -= 1
  end
  return line
end

closed(code::AbstractString) = scope(code).kind == :toplevel

# Scan to the start of the next block, find the end of
# this one.
function walkforward(code::Vector, line, i=1)
  j = line
  while j < length(code) && (j == line || !isstart(code[j]))
    j += 1
    l = code[j]
    if isend(l)
      !closed(join(code[i:j-1], "\n")) && (line = j)
    elseif !(isblank(l) || isstart(l))
      line = j
    end
  end
  return line
end

function getblock(s, line)
  c = lines(s)
  i = walkback(c, line)
  j = walkforward(c, line, i)
  code = join(c[i:j], '\n')
  s = scope(code, line-i+1).kind
  ((s == :toplevel && isblank(c[line])) || s == :multiline_comment) &&
    (return "", (line, line))
  code, (i, j)
end

function getblock(s, start::Cursor, stop::Cursor)
  io = LineNumberingReader(s)
  i = LNR.index(io, start)
  j = LNR.index(io, stop)-1

  # The cursor could be on the n+1th line
  stop.line > length(io.lines) && (j = endof(s))

  # As a convienience, trim blank lines
  code = lines(s[i:j])
  i, j = start.line, stop.line
  while !isempty(code) && isblank(code[1])
    shift!(code)
    i += 1
  end
  while !isempty(code) && isblank(code[end])
    pop!(code)
    j -= 1
  end

  join(code, "\n"), (i,j)
end
