# -------------
# Code handling
# -------------

cursor_start(data) = data["start"]["line"], data["start"]["col"]
cursor_end(data) = data["end"]["line"], data["end"]["col"]
cursor(data) = cursor_start(data)

function index_of(s, line, char)
  lines = 1
  chars = 0
  for i = 1:endof(s)
    isvalid(s, i) || continue
    lines == line && char == chars+1 && return i
    if s[i] == '\n'
      lines += 1
      chars =  0
    else
      chars += 1
    end
  end
  error("Position $line:$char not found in string.")
end

lines(s) = split(s, "\n")

isblank(s) = ismatch(r"^\s*(#.*)?$", s)
isend(s) = ismatch(r"^end", s)
isstart(s) = !(ismatch(r"^\s", s) || isblank(s) || isend(s))

# Find to the start of this block.
function walk_back(code::Vector{String}, line)
  while line > 1 && !isstart(code[line])
    line -= 1
  end
  return line
end

# Scan to the start of the next block, find the end of
# this one.
function walk_forward(code::Vector{String}, line)
  l = line+1
  while l < length(code) && !isstart(code[l])
    l += 1
    !(isblank(code[l]) || isstart(code[l])) && (line = l)
  end
  return line
end

function get_code(data)
  if cursor_start(data) != cursor_end(data)
    s = data["code"]
    start, stop = cursor_start(data), cursor_end(data)
    i, j = index_of(s, start[1], start[2]), index_of(s, stop[1], stop[2]-1) # Selection is in front of cursor
    return s[i:j], (start[1], stop[1])
  else
    c = data["code"] |> lines
    l = cursor(data)[1]
    i, j = walk_back(c, l), walk_forward(c, l)
    return join(c[i:j], "\n"), (i, j)
  end
end
