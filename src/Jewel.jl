module Jewel

# export server

using JSON

include("utils.jl")

# -------------------
# Basic Communication
# -------------------

function server(port, id)
  ltconnect(port, id)
  println("connected")
  while isopen(conn)
    try
      handle_next()
    catch e
      warn("Jewel: "sprint(show, e))
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
  data = get_code(data)
  code, lines = data[:code], data[:lines]
  val = nothing
  try
    code = parse(code)
    val = Main.eval(code)
  catch e
    show_exception(req, sprint(showerror, e), lines)
    return
  end
  display_result(req, val, lines)
end

include("parse.jl")

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

end # module
