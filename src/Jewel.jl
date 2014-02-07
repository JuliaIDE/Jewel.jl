module Jewel

# export server

using JSON

# Utils

macro dotimes(n, body)
  quote
    for i = 1:$(esc(n))
      $(esc(body))
    end
  end
end

# -------------------
# Basic Communication
# -------------------

function server(port, id)
  ltconnect(port, id)
  # pipe_stdio()
  println("Connected")
  while isopen(conn)
    try
      handle_next()
    catch e
      ltprint("Jewel Error: "sprint(show, e))
    end
  end
end

function ltconnect(port, id)
  global conn = connect(port)
  ltwrite({"type" => "julia",
           "name" => "Julia",
           "commands" => ["editor.eval.julia"],
           "client-id" => id})
end

function ltclose()
  close(conn)
end

function ltwrite(data)
  @assert isopen(conn)
  println(conn, json(data))
end

function ltread()
  @assert isopen(conn)
  JSON.parse(conn)
end

send(client::Integer, command, info) = ltwrite([client, command, info])
send(req, command, info) = send(req[1], command, info)

# ----------------
# Command Handling
# ----------------

const cmd_handlers = Dict{String, Function}()

function handle_cmd(data)
  data == nothing && return
  cmd = data[2]
  if haskey(cmd_handlers, cmd)
    cmd_handlers[cmd](data, data[3])
  else
    error("Can't handle command $cmd")
  end
end

handle(f, cmd) = (cmd_handlers[cmd] = f)

handle_next() = handle_cmd(ltread())

handle("client.close") do req, data
  close(conn)
end

# ---------------
# Editor Commands
# ---------------

function editor_command(client, cmd, data)
  data[:cmd] = cmd
  send(client, "editor.eval.julia.editor-command", data)
end

function result(req, value::String, bounds::(Int, Int); under = false, html = false)
  editor_command(req, "result",
                 {"value" => value,
                  "start" => bounds[1],
                  "end"   => bounds[2],
                  "under" => under,
                  "html"  => html})
end

function show_exception(req, value::String, bounds::(Int, Int))
  editor_command(req, "error",
                 {"value" => value,
                  "start" => bounds[1],
                  "end"   => bounds[2]})
end

# ---------------
# Global Commands
# ---------------

handle("julia.set-global-client") do req, data
  global const global_client = req[1]
end

function command(cmd, data)
  data[:cmd] = cmd
  send(global_client, "editor.eval.julia.command", data)
end

function popup(header, body="", buttons = [{:label => "Ok"}])
  command("popup",
          [:header => header,
           :body => body,
           :buttons => buttons])
end

function ltprint(message; error = false)
  command("print",
          [:value => message,
           :error => error])
end

# ----
# Eval
# ----

handle("editor.eval.julia") do req, data
  code, lines = get_code(data)
  val = nothing
  try
    code = parse(code)
    val = eval(code)
  catch e
    show_exception(req, sprint(showerror, e), lines)
    return
  end
  display_result(req, val, lines)
end

# -------------
# Code handling
# -------------

cursor(data) = data["start"]["line"], data["start"]["col"]
cursor_start(data) = cursor(data)
cursor_end(data) = data["end"]["line"], data["end"]["col"]

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
    # lines == line && chars == char && return i
  end
  error("$line:$char not found.")
end

function position_of(s, index)
  @assert isvalid(s, index)
  lines = 1
  chars = 0
  for i = 1:endof(s)
    isvalid(s, i) || continue
    i == index && return lines, chars+1
    if s[i] == '\n'
      lines += 1
      chars =  0
    else
      chars += 1
    end
  end
end

line_at(s, index) = position_of(s, index)[1]

cursor_index(data) = index_of(data["code"], cursor(data)...)

const whitespace = (' ', '\n', '\t')

function walk_back(s, i)
  while i > 1
    i_ = prevind(s, i)
    !(s[i] in whitespace) && s[i_] == '\n' && break
    i = i_
  end
  return i
end

function Base.nextind(s::String, i::Integer, n::Integer)
  @dotimes n i = nextind(s, i)
  return i
end

function walk_forward(s, i)
  j = i
  while (i_ = nextind(s, i)) <= endof(s)
    if !(s[i] in whitespace)
      j = i
    elseif s[i] == '\n' && !(s[i_] in whitespace)
      return beginswith(s[i_:end], "end") ? nextind(s, i, 3) : j
    end
    i = i_
  end
  return j
end

function get_code(data)
  if cursor_start(data) != cursor_end(data)
    s = data["code"]
    start, stop = cursor_start(data), cursor_end(data)
    i, j = index_of(s, start...), index_of(s, stop...)
    return s[i:j], (start[1], stop[1])
  else
    # May not work well with comments yet.
    s = data["code"]
    c = cursor_index(data)
    i, j = walk_back(s, c), walk_forward(s, c)
    start, stop = line_at(s, i), line_at(s, j)
    s[i:j], (start, stop)
  end
end

# ------------
# Display Code
# ------------

function best_mime(val) 
  for mime in ("text/html", "text/plain")
    mimewritable(mime, val) && return mime
  end
end

function display_result(req, val, bounds)
  mime = best_mime(val)
  val == nothing       ? result(req, "✓", bounds) :
  mime == "text/plain" ? result(req, sprint(writemime, "text/plain", val), bounds) :
  mime == "text/html"  ? result(req, sprint(writemime, "text/html", val), bounds, html = true) :
  error("Cannot display $val.")
end

# --
# IO
# --

const orig_STDOUT = STDOUT

# function pipe_stdio()
#   @async begin
#     read_stdout, _ = redirect_stdout()
#     while true
#       s = readavailable(read_stdout)
#       ltprint(s)
#     end
#   end
# end


end # module
