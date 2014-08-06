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

# ---------------
# Editor Commands
# ---------------

function result(req, value::String, bounds::(Int, Int); under = false, html = false)
  raise(req, "julia.result",
        {"value" => value,
         "start" => bounds[1],
         "end"   => bounds[2],
         "under" => under,
         "html"  => html})
end

function show_exception(req, value::String, bounds::(Int, Int))
  raise(req, "julia.error",
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
  for mime in ("text/html", "image/png", "text/plain")
    mimewritable(mime, val) && return MIME(symbol(mime))
  end
  error("Cannot display $val.")
end

function display_result(req, val, bounds)
  mime = best_mime(val)
  is(val, nothing)     ? result(req, "✓", bounds) :
  mime == MIME"text/plain"() ? result(req, sprint(writemime, mime, val), bounds) :
  mime == MIME"image/png"() ? display_result(req, html_image(val), bounds) :
  mime == MIME"text/html"()  ? result(req, sprint(writemime, mime, val), bounds, html=true, under=true) :
  error("Cannot display $val.")
end

type Pass end
const pass = Pass()

display_result(req, val::Pass, bounds) = nothing

type LTConsole <: Display end

import Base: display, writemime

type HTML
  content::UTF8String
end

writemime(io::IO, ::MIME"text/html", h::HTML) = print(io, h.content)

# Should use CSS for width
html_image(img) = HTML("""<img width="500px" src="data:image/png;base64,$(stringmime("image/png", img))" />""")

function display(d::LTConsole, m::MIME"text/plain", x)
  console(stringmime(m, x))
end

function display(d::LTConsole, m::MIME"text/html", x)
  console(stringmime(m, x), html = true)
end

display(d::LTConsole, m::MIME"image/png", x) = display(d, html_image(x))

display(d::LTConsole, x) = display(d, best_mime(x), x)

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
