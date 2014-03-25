#jewel module Jewel

# -------------
# Code handling
# -------------

# All this is a somewhat temporary solution,
# it can be much improved once CodeMirror's
# julia mode is fixed

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
function walk_back(code::Vector, line)
  while line > 1 && !isstart(code[line])
    line -= 1
  end
  return line
end

# Scan to the start of the next block, find the end of
# this one.
function walk_forward(code::Vector, line)
  l = isstart(code[line]) ? line + 1 : line
  while l < length(code) && !isstart(code[l])
    l += 1
    !(isblank(code[l]) || isstart(code[l])) && (line = l)
  end
  return line
end

function get_module_name(code::Vector, line)
  while line > 1
    line -= 1
    m = match(r"^(?:#jewel )?module (\w+)", code[line])
    m == nothing || return symbol(m.captures[1])
  end
  return nothing
end

function file_module(code::String)
  m = match(r"^\s*#jewel module (\w+)", code)
  m == nothing ? nothing : symbol(m.captures[1])
end

function get_code(s, start, stop)
  i, j = index_of(s, start[1], start[2]), index_of(s, stop[1], stop[2]-1) # Selection is in front of cursor
  {:code   => s[i:j],
   :lines  => (start[1], stop[1]),
   :module => get_module_name(lines(s), start[1])}
end

function get_code(s, line)
  c = lines(s)
  i, j = walk_back(c, line), walk_forward(c, line)
  {:code   => join(c[i:j], "\n"),
   :lines  => (i, j),
   :module => get_module_name(c, i)}
end

function get_code(s::String)
  {:code   => s,
   :lines  => (1, length(lines(s))),
   :module => file_module(s)}
end

get_code(data::Dict) =
  get(data, "all", false) ? get_code(data["code"]) :
  cursor_start(data) == cursor_end(data) ?
    get_code(data["code"], cursor(data)[1]) :
    get_code(data["code"], cursor_start(data), cursor_end(data))

# Token parsing

# Very basic
function get_qualified_name(str::String, index)
  next(s, i) = s[nextind(s, i)]
  prev(s, i) = s[prevind(s, i)]
  word_char(c; dot = true) = ismatch(dot ? r"[\.@a-zA-Z!]" : r"[@a-zA-Z!]", string(c))

  index > endof(str) &&
    (word_char(str[end]) ? index = endof(str) : return "")

  i = index

  while i > 1 && word_char(prev(str, i))
    i = prevind(str, i)
  end

  j = word_char(str[index]) ? index : prevind(str, index)
  while j < endof(str) && word_char(next(str, j), dot=false)
    j = nextind(str, j)
  end

  return str[i:j]
end
