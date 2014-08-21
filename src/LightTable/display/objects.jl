import Base: writemime

# Collapsible type – can be treated specially.

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

Collapsible(HTML("foo"),
            HTML("hello world"))

displayinline(::Nothing) = Text("✓")

# Function display
name(f::Function) =
  isgeneric(f) ? string(f.env.name) :
  isdefined(f, :env) && isa(f.env,Symbol) ? string(f.env) :
  "λ"

displayinline(f::Function) =
  isgeneric(f) ?
    Collapsible(HTML(name(f)), methods(f)) :
    Text(name(f))
