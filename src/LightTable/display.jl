# Editor commands

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

# Display infrastructure

function best_mime(val)
  for mime in ("text/html", "image/png", "text/plain")
    mimewritable(mime, val) && return MIME(symbol(mime))
  end
  error("Cannot display $val.")
end

function displayinline!(req, val, bounds)
  mime = best_mime(val)
  is(val, nothing)     ? result(req, "✓", bounds) :
  mime == MIME"text/plain"() ? result(req, sprint(writemime, mime, val), bounds) :
  mime == MIME"image/png"() ? displayinline!(req, html_image(val), bounds) :
  mime == MIME"text/html"()  ? result(req, sprint(writemime, mime, val), bounds, html=true, under=true) :
  error("Cannot display $val.")
end

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
