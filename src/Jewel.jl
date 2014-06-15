module Jewel

using JSON, Lazy

export server, ltprint, popup, notify

include("utils.jl")

exit_on_sigint(on) = ccall(:jl_exit_on_sigint, Void, (Cint,), on)

# -------------------
# Basic Communication
# -------------------

function server(port, id)
  exit_on_sigint(false)
  ltconnect(port, id)
  print("connected")
  pushdisplay(LightTable())
  while isopen(conn)
    try
      handle_next()
    catch e
      warn("Jewel: "sprint(showerror, e, catch_backtrace()))
    end
  end
end

function ltconnect(port, id)
  global conn = connect(port)
  ltwrite({"type" => "julia",
           "name" => "Julia",
           "commands" => ["editor.eval.julia", "editor.julia.hints", "editor.julia.doc"],
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
  global last_data = data[3]
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

# ------
# Others
# ------

include("commands.jl")
include("parse.jl")
include("eval.jl")
include("completions.jl")
include("doc.jl")

# ------------
# Display Code
# ------------
function best_mime(val)
  for mime in ("text/html", "text/plain")
    mimewritable(mime, val) && return MIME(symbol(mime))
  end
  error("Cannot display $val.")
end

function display_result(req, val, bounds)
  mime = best_mime(val)
  is(val, nothing)     ? result(req, "✓", bounds) :
  mime == MIME"text/plain"() ? result(req, sprint(writemime, mime, val), bounds) :
  mime == MIME"text/html"()  ? result(req, sprint(writemime, mime, val), bounds, html = true) :
  error("Cannot display $val.")
end

type LightTable <: Display end

import Base: display

function display(d::LightTable, m::MIME"text/plain", x)
  console(sprint(writemime, m, x))
end

display(d::LightTable, x) = display(d, best_mime(x), x)

end # module
