module LightTable

using JSON, Lazy, Jewel, LNR, Requires

import Jewel: lines

export server, ltprint, popup, notify

exit_on_sigint(on) = ccall(:jl_exit_on_sigint, Void, (Cint,), on)

const connect_notify = Condition()

function flushpipe(io)
  @schedule begin
    wait(connect_notify)
    while true
      ltprint(readline(io))
    end
  end
end

# -------------------
# Basic Communication
# -------------------

function server(port, id, headless = false)
  global isheadless = headless
  exit_on_sigint(false)
  ltconnect(port, id)
  headless && pushdisplay(LTConsole())
  while isopen(conn)
    try
      handlenext()
    catch e
      warn("LightTable.jl: "sprint(showerror, e, catch_backtrace()))
    end
  end
end

function ltconnect(port, id)
  global conn = connect(port)
  ltwrite(@d("type" => "julia",
             "name" => "Julia",
             "commands" => ["editor.eval.julia", "editor.julia.hints", "editor.julia.doc"],
             "client-id" => id))
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
  data = JSON.parse(conn)
  eof(conn) || read(conn, Char) # newline
  return data
end

raise(object::Integer, event, data = nothing) = ltwrite([object, event, data])

# ----------------
# Command Handling
# ----------------

const cmdhandlers = Dict{AbstractString, Function}()

function handlecmd(data)
  data == nothing && return
  cmd = data[2]
  if haskey(cmdhandlers, cmd)
    cmdhandlers[cmd](data[1], data[3])
  else
    warn("Can't handle command $cmd")
  end
end

handle(f, cmd) = (cmdhandlers[cmd] = f)

const cmdqueue = c()

function queuecmds()
  while nb_available(conn) > 0
    push!(cmdqueue, ltread())
  end
end

handlenext() = handlecmd(!isempty(cmdqueue) ? shift!(cmdqueue) : ltread())

handle("notify-connected") do client, data
  raise(client, "connected")
end

handle("client.close") do req, data
  close(conn)
end

# ------
# Others
# ------

include("commands.jl")
include("interaction/interaction.jl")
include("interaction/collapsible.jl")
include("interaction/scales.jl")
include("interaction/lazy.jl")
include("eval.jl")
include("completions.jl")
include("doc.jl")
include("errorshow.jl")
include("display/display.jl")
include("misc.jl")

end
