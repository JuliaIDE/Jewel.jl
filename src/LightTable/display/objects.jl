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

const MAX_CELLS = 500

function getsize(h, w, maxcells)
  (h == 0 || w == 0) && return 0, 0
  swap = false
  w > h && ((w, h, swap) = (h, w, true))
  h = min(maxcells ÷ w, h)
  h ≥ w ?
    (swap ? (w, h) : (h, w)) :
    (ifloor(sqrt(maxcells)), ifloor(sqrt(maxcells)))
end

function Base.writemime(io::IO, m::MIME"text/html", table::Table)
  println(io, """<table class="$(table.class)">""")
  h, w = size(table.data)
  (h == 0 || w == 0) && @goto none
  h′, w′ = getsize(h, w, MAX_CELLS)
  for i = (h′ ≤ h ? (1:h′) : [1:(h′÷2), h-(h′÷2)+1:h])
    println(io, """<tr>""")
    for j = (w′ ≤ w ? (1:w′) : [1:(w′÷2), w-(w′÷2)+1:w])
      println(io, """<td>""")
      item = table.data[i, j]
      writemime(io, bestmime(item), item)
      println(io, """</td>""")

      w > w′ && j == (w′÷2) && println(io, """<td>⋯</td>""")
    end
    println(io, """</tr>""")

    h > h′ && i == (h′÷2) && println(io, "<tr>","<td>⋮</td>"^(w≤w′?w:w′+1),"</tr>")
  end
  @label none
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

displayinline(a::Vector, t = "Vector") =
  Collapsible(HTML("$t <span>$(eltype(a)), $(length(a))</span>"),
              Table("array", a''))

displayinline(s::Set) = displayinline(collect(s), "Set")

# Others

import Jewel: @require

# Data Frames

@require DataFrames begin
  displayinline(f::DataFrame) =
    Collapsible(HTML("DataFrame <span>($(join(names(f), ", "))), $(size(f,1))</span>"),
                Table("data-frame", vcat(map(s->HTML(string(s)), names(f))',
                                         array(f))))
end

# Colors

@require Color begin
  displayinline(c::ColorValue) =
    Collapsible(HTML("""<span style="color:#$(hex(c));
                                     font-weight:bold;">#$(hex(c))</span>
                        <span>$(c)</span>"""),
                tohtml(MIME"image/svg+xml"(), c))

  displayinline{C<:ColourValue}(cs::VecOrMat{C}) = tohtml(MIME"image/svg+xml"(), cs)
end

# Profile tree

function toabspath(file)
  isabspath(file) && file
  path = basepath(file)
  return path == nothing ? file : path
end

@require Jewel.ProfileView begin
  function displayinline!(req, tree::Jewel.ProfileView.ProfileTree, bounds)
    raise(req, "julia.profile-result",
          {"value" => stringmime("text/html", tree),
           "start" => bounds[1],
           "end"   => bounds[2],
           "lines" => [{:file => toabspath(li.file),
                        :line => li.line,
                        :percent => p} for (li, p) in Jewel.ProfileView.fetch() |> Jewel.ProfileView.flatlines]})
  end
end
