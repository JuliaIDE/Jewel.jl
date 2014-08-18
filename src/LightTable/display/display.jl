include("commands.jl")

# Utils

# Should use CSS for width
function htmlimage(img)
  HTML() do io
    print(io, """<img width="500px" src="data:image/png;base64,""")
    writemime(io, MIME"image/png", img)
    print(io, "\" />")
  end
end

# Display infrastructure

# `displayinline` can be overridden to lower an object into something
# more basic for display. It is applied repeatedly by
# `applydisplayinline` until it reaches the most basic form possible.

function bestmime(val)
  for mime in ("text/html", "image/png", "text/plain")
    mimewritable(mime, val) && return MIME(symbol(mime))
  end
  error("Cannot display $val.")
end

# Catch-all fallback
function displayinline(x)
  m = bestmime(x)
  if m == MIME"text/html"()
    HTML() do io
      writemime(io, MIME"text/html"(), x)
    end
  elseif m == MIME"image/png"()
    htmlimage(x)
  elseif m == MIME"text/plain"()
    Text() do io
      writemime(io, MIME"text/plain"(), x)
    end
  end
end

function applydisplayinline(x)
  while (x′ = displayinline(x)) ≠ x
    x = x′
  end
  return x
end

displayinline(::Nothing) = Text("✓")

displayinline(x::Text) = x
displayinline!(req, text::Text, bounds) =
  showresult(req, stringmime("text/plain", text), bounds)

displayinline(x::HTML) = x
displayinline!(req, html::HTML, bounds) =
  showresult(req, stringmime("text/html", html), bounds, html=true, under=true)

# Light Table's Console as a display

type LTConsole <: Display end

import Base: display, writemime

function display(d::LTConsole, m::MIME"text/plain", x)
  console(stringmime(m, x))
end

function display(d::LTConsole, m::MIME"text/html", x)
  console(stringmime(m, x), html = true)
end

display(d::LTConsole, m::MIME"image/png", x) = display(d, htmlimage(x))

display(d::LTConsole, x) = display(d, bestmime(x), x)
