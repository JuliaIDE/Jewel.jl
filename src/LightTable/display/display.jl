include("DOM.jl")
using .DOM

include("commands.jl")
include("objects.jl")

# Utils

function tohtml(m::MIME"text/html", x)
  HTML() do io
    writemime(io, m, x)
  end
end

function tohtml(m::MIME"text/plain", x)
  rep = stringmime(m, x)
  lines = split(rep, "\n")
  html = span(".text", rep)
  length(lines) == 1 && length(lines[1]) ≤ 50 ?
    Collapsible(html) :
    Collapsible(strong(summary(x)), html)
end

function tohtml(m::MIME"image/png", img)
  HTML() do io
    print(io, """<img src="data:image/png;base64,""")
    print(io, stringmime(m, img))
    print(io, "\" />")
  end
end

function tohtml(m::MIME"image/svg+xml", img)
  HTML() do io
     writemime(io, m, img)
  end
end

# Display infrastructure

function bestmime(val)
  for mime in ("text/html", "image/svg+xml", "image/png", "text/plain")
    mimewritable(mime, val) && return MIME(symbol(mime))
  end
  error("Cannot display $val.")
end

displayinline(x::HTML) = x

# Catch-all fallback
displayinline(x) = tohtml(bestmime(x), x)

function applydisplayinline(x)
  while (x′ = displayinline(x)) !== x
    x = x′
  end
  return x
end

displayinline!(x, opts) =
  displayinline!(displayinline(x), opts)

displayinline!(html::HTML, opts) =
  showresult(stringmime("text/html", html), opts, html=true, under=true)

# Light Table's Console as a display

type LTConsole <: Display end

import Base: display, writemime

function display(d::LTConsole, m::MIME"text/plain", x)
  console(stringmime(m, x))
end

function display(d::LTConsole, m::MIME"text/html", x)
  console(stringmime(m, x), html = true)
end

display(d::LTConsole, m::MIME"image/png", x) = display(d, tohtml(m, x))

display(d::LTConsole, x) = display(d, bestmime(x), x)
