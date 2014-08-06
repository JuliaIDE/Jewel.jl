module LightTable

using JSON, Lazy, Jewel

import Jewel: lines, helpstr

export server, ltprint, popup, notify

exit_on_sigint(on) = ccall(:jl_exit_on_sigint, Void, (Cint,), on)

# -------------------
# Basic Communication
# -------------------

function server(port, id)
  exit_on_sigint(false)
  ltconnect(port, id)
  print("connected")
  pushdisplay(LTConsole())
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

raise(object::Integer, command, data) = ltwrite([object, command, data])
raise(req, command, data) = raise(req[1], command, data)

# ----------------
# Command Handling
# ----------------

const cmd_handlers = Dict{String, Function}()

function handle_cmd(data)
  data == nothing && return
  global last_data = data[3]
  cmd = data[2]
  if haskey(cmd_handlers, cmd)
    cmd_handlers[cmd](data[1], data[3])
  else
    warn("Can't handle command $cmd")
  end
end

handle(f, cmd) = (cmd_handlers[cmd] = f)

handle_next() = handle_cmd(ltread())

handle("client.close") do req, data
  close(conn)
end

# ------
# Others
# ------

include("commands.jl")
include("parse.jl")
include("eval.jl")
include("completions.jl")
include("doc.jl")
include("profile.jl")
include("display.jl")

# Modules

handle("editor.julia.module.update") do editor, data
  mod = data["path"] == nothing ? "Main" : Jewel.filemodule(data["path"])
  mod == "" && (mod = "Main")
  if getthing(mod) == nothing
    notify("This file's module, `$mod`, isn't loaded yet.", class = "error")
    mod = "Main"
  end
  raise(editor, "editor.julia.module.update", mod)
end

end
