import Base: writemime

displayinline(::Nothing) = Text("✓")

type Collapsible
  header
  content
end

function writemime(io::IO, m::MIME"text/html", c::Collapsible)
  println(io, """<div class="collapsible">""")
  println(io, """<span class="collapsible-header">""")
  writemime(io, m, c.header)
  println(io, """</span>""")
  println(io, """<div class="collapsible-content">""")
  writemime(io, m, c.content)
  println(io, """</div></div>""")
end

displayinline!(req, html::Collapsible, bounds) =
  showresult(req, stringmime("text/html", html), bounds, html=true)

Collapsible(HTML("foo"), HTML("hello world"))
