# Extract blocks of code from a file

# TODO: Rewrite to use the pseudo-parser, LineNumberingReader

isblank(s) = ismatch(r"^\s*(#.*)?$", s)
isend(s) = ismatch(r"^end", s)
isstart(s) = !(ismatch(r"^\s", s) || isblank(s) || isend(s))

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
  while l < length(code) && (!isstart(code[l]) || l == line)
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

# Extract a selection

# TODO: rewrite to use LineNumberingReader
function indexof(s, line, char)
  lines = 1
  chars = 0
  for i = 1:endof(s)
    isvalid(s, i) || continue
    lines == line && char == chars+1 && return i
    if s[i] == '\n'
      lines += 1
      chars =  0
      i == length(s) && return i-1
    else
      chars += 1
    end
  end
  error("Position $line:$char not found in string.")
end

function getcode(s, start, stop)
  i, j = indexof(s, start[1], start[2]), indexof(s, stop[1], stop[2]-1) # Selection is in front of cursor
  s[i:j], (start[1], stop[1])
end
