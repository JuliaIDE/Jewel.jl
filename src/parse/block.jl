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
