# Editor commands

function showresult(req, value::String, bounds::(Int, Int); under = false, html = false)
  raise(req, "julia.result",
        {"value" => value,
         "start" => bounds[1],
         "end"   => bounds[2],
         "under" => under,
         "html"  => html})
end

function showexception(req, value::String, bounds::(Int, Int))
  raise(req, "julia.error",
        {"value" => value,
         "start" => bounds[1],
         "end"   => bounds[2]})
end

function showexception(editor, e, bt, bounds::(Int, Int))
  notify_error(sprint(showerror, e))
  showexception(
    editor,
    sprint(showerror_html, e, bt, :include_string),
    bounds)
end

# Display infrastructure

function bestmime(val)
  for mime in ("text/html", "image/png", "text/plain")
    mimewritable(mime, val) && return MIME(symbol(mime))
  end
  error("Cannot display $val.")
end

function displayinline!(req, val, bounds)
  mime = bestmime(val)
  is(val, nothing)     ? showresult(req, "✓", bounds) :
  mime == MIME"text/plain"() ? showresult(req, sprint(writemime, mime, val), bounds) :
  mime == MIME"image/png"() ? displayinline!(req, html_image(val), bounds) :
  mime == MIME"text/html"()  ? showresult(req, sprint(writemime, mime, val), bounds, html=true, under=true) :
  error("Cannot display $val.")
end

# Light Table's Console as a display

type LTConsole <: Display end

import Base: display, writemime

# Should use CSS for width
html_image(img) = HTML("""<img width="500px" src="data:image/png;base64,$(stringmime("image/png", img))" />""")

function display(d::LTConsole, m::MIME"text/plain", x)
  console(stringmime(m, x))
end

function display(d::LTConsole, m::MIME"text/html", x)
  console(stringmime(m, x), html = true)
end

display(d::LTConsole, m::MIME"image/png", x) = display(d, html_image(x))

display(d::LTConsole, x) = display(d, bestmime(x), x)
