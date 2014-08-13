# Extract blocks of code from a file

isblank(s) = ismatch(r"^\s*(#.*)?$", s)
isstart(s) = !(ismatch(r"^\s", s) || isblank(s) || isend(s))
isend(s) = ismatch(r"^end\b", s)

# Find to the start of this block.
function walkback(code::Vector, line)
  while line > 1 && !isstart(code[line])
    line -= 1
  end
  return line
end

# Scan to the start of the next block, find the end of
# this one.
function walkforward(code::Vector, line)
  l = line
  while l < length(code) && (l == line || !isstart(code[l]))
    l += 1
    !(isblank(code[l]) || isstart(code[l])) && (line = l)
  end
  return line
end

function getblock(s, line)
  c = lines(s)
  i, j = walkback(c, line), walkforward(c, line)
  join(c[i:j], "\n"), (i, j)
end

function getblock(s, start::Cursor, stop::Cursor)
  io = LineNumberingReader(s)
  i = LNR.index(io, start)
  j = LNR.index(io, stop)-1
  s[i:j], (start.line, stop.line)
end
