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
  data::AbstractMatrix{T}
end

Table(data::AbstractMatrix) = Table("", data)

function Base.writemime(io::IO, m::MIME"text/html", table::Table)
  println(io, """<table class="$(table.class)">""")
  h, w = size(table.data)
  max = 50; hmax = max÷2
  for i = (h ≤ max ? (1:h) : [1:hmax, h-hmax+1:h])
    println(io, """<tr>""")
    for j = (w ≤ max ? (1:w) : [1:hmax, w-hmax+1:w])
      println(io, """<td>""")
      item = table.data[i, j]
      writemime(io, bestmime(item), item)
      println(io, """</td>""")

      w > max && j == hmax && println(io, """<td>⋯</td>""")
    end
    println(io, """</tr>""")

    h > max && i == hmax && println(io, "<tr>","<td>⋮</td>"^(w≤max?w:max+1),"</tr>")
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

displayinline(x::FloatingPoint) = Text(x)

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

sizestr(a::AbstractArray) = join(size(a), "×")

displayinline(a::Matrix) =
  Collapsible(HTML("Matrix <span>$(eltype(a)), $(sizestr(a))</span>"),
              Table("array", a))

displayinline(a::Vector) =
  Collapsible(HTML("Vector <span>$(eltype(a)), $(length(a))</span>"),
              Table("array", a''))

# Data Frames

using DataFrames

displayinline(f::DataFrame) =
  Collapsible(HTML("DataFrame <span>($(join(names(f), ", "))), $(size(f,1))</span>"),
              Table("data-frame", vcat(map(s->HTML(string(s)), names(f))',
                                       array(f))))
