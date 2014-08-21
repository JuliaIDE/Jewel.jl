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

# Tables

type Table{T}
  class::ASCIIString
  data::Matrix{T}
end

Table(data::Matrix) = Table("", data)

function Base.writemime(io::IO, m::MIME"text/html", table::Table)
  println(io, """<table class="$(table.class)">""")
  for i = 1:size(table.data, 1)
    println(io, """<tr>""")
    for j = 1:size(table.data, 2)
      println(io, """<td>""")
      item = table.data[i, j]
      writemime(io, bestmime(item), item)
      println(io, """</td>""")
    end
    println(io, """</tr>""")
  end
  println(io, """</table>""")
end

# Nothing

displayinline(::Nothing) = Text("✓")

# Floats

function writemime(io::IO, m::MIME"text/html", x::FloatingPoint)
  print(io, """<span class="float" title="$(string(x))">""")
  Base.Grisu._show(io, x, Base.Grisu.PRECISION, 4, false)
  print(io, """</span>""")
end

# Functions

name(f::Function) =
  isgeneric(f) ? string(f.env.name) :
  isdefined(f, :env) && isa(f.env,Symbol) ? string(f.env) :
  "λ"

displayinline(f::Function) =
  isgeneric(f) ?
    Collapsible(HTML(name(f)), methods(f)) :
    Text(name(f))

# Arrays

sizestr(a::Array) = join(size(a), "×")

displayinline(a::Matrix) =
  Collapsible(HTML("Matrix <span>$(eltype(a)), $(sizestr(a))</span>"),
              Table("array", a))

rand(100,100)
