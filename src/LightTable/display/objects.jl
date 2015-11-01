import Base: writemime

# HTML utils

using .DOM

fade(x) = span(".fade", x)

# Text

function displayinline(t::Text)
  lines = split(string(t), "\n")
  Collapsible(span(".text", lines[1]),
              span(".text", join(lines[2:end], "\n")))
end

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
  for i = (h′ == h ? (1:h′) : [1:(h′÷2), h-(h′÷2)+1:h])
    println(io, """<tr>""")
    for j = (w′ == w ? (1:w′) : [1:(w′÷2), w-(w′÷2)+1:w])
      println(io, """<td>""")
      if isdefined(table.data, i, j)
        item = applydisplayinline(table.data[i, j])
        writemime(io, bestmime(item), item)
      else
        print(io, "#undef")
      end
      println(io, """</td>""")

      w > w′ && j == (w′÷2) && println(io, """<td>⋯</td>""")
    end
    println(io, """</tr>""")

    h > h′ && i == (h′÷2) && println(io, "<tr>","<td>⋮</td>"^(w≤w′?w:w′+1),"</tr>")
  end
  @label none
  println(io, """</table>""")
end

# Void

displayinline(::Void) = Text("✓")

# Floats

function round3(n)
  n = string(n)
  n = replace(n, r"\.0$", ".")
  ismatch(r"[0-9]\.0*999", n) && return n
  zero = ismatch(r"^[^\d]*0\.0+", n) # Special case for e.g. 0.0001
  r = zero ? r"0[1-9][0-9]{3,}[^\.]*$" : r"\.[0-9]{4,}"
  n = replace(n, r, s->string(s[1], @sprintf("%03d", round(Integer, parse(Int, s[2:5])/10 ))), 1)
end

function writemime(io::IO, m::MIME"text/html", x::AbstractFloat)
  print(io, """<span class="float" title="$(string(x))">""")
  print(io, round3(x))
  print(io, """</span>""")
end

displayinline!(x::AbstractFloat, opts) =
  showresult(stringmime("text/html", x), opts, html=true)

# Functions

name(f::Function) =
  isgeneric(f) ? string(f.env.name) :
  isdefined(f, :env) && isa(f.env,Symbol) ? string(f.env) :
  "λ"

displayinline(f::Function) =
  isgeneric(f) ?
    Collapsible(strong(name(f)), methods(f)) :
    Text(name(f))

# Arrays

sizestr(a::AbstractArray) = join(size(a), "×")

displayinline(a::Matrix) =
  Collapsible(span(strong("Matrix "), fade("$(eltype(a)), $(sizestr(a))")),
              Table("array", a))

function copytranspose(xs::Vector)
  result = similar(xs, length(xs), 1)
  for i = 1:length(xs)
    isdefined(xs, i) && (result[i] = xs[i])
  end
  return result
end

displayinline(a::Vector, t = "Vector") =
  Collapsible(span(strong(t), fade(" $(eltype(a)), $(length(a))")),
              Table("array", copytranspose(a)))

displayinline(s::Set) = displayinline(collect(s), "Set")

@cond if VERSION < v"0.4-"
  keytype(d) = eltype(d)[1]
  valtype(d) = eltype(d)[2]
else
  keytype(d) = eltype(d).parameters[1]
  valtype(d) = eltype(d).parameters[2]
end

displayinline(d::Dict) =
  Collapsible(span(strong("Dictionary "), fade("$(keytype(d)) → $(valtype(d)), $(length(d))")),
              HTML() do io
                println(io, """<table class="array">""")
                kv = collect(d)
                for i = 1:(min(length(kv), MAX_CELLS÷2))
                  print(io, "<tr><td>")
                  item = displayinline(kv[i][1])
                  writemime(io, bestmime(item), item)
                  print(io, "</td><td>")
                  item = displayinline(kv[i][2])
                  writemime(io, bestmime(item), item)
                  print(io, "</td></tr>")
                end
                length(kv) ≥ MAX_CELLS÷2 && println(io, """<td>⋮</td><td>⋮</td>""")
                println(io, """</table>""")
              end)

# Others

import Jewel: @require

# Data Frames

@require DataFrames begin
  displayinline(f::DataFrames.DataFrame) =
    isempty(f) ? Collapsible(span(strong("DataFrame "), fade("Empty"))) :
      Collapsible(span(strong("DataFrame "), fade("($(join(names(f), ", "))), $(size(f,1))")),
                  Table("data-frame", vcat(map(s->HTML(string(s)), names(f))',
                                           DataFrames.DataArray(f))))
end

# Colors

@require Color begin
  displayinline(c::Color.ColourValue) =
    Collapsible(span(strong(@d(:style => "color: #$(Color.hex(c))"),
                            "#$(Color.hex(c)) "),
                     fade(string(c))),
                tohtml(MIME"image/svg+xml"(), c))

  displayinline{C<:Color.ColourValue}(cs::VecOrMat{C}) = tohtml(MIME"image/svg+xml"(), cs)
end

# Gadfly

@require Gadfly begin
  displayinline(p::Gadfly.Plot) = DOM.div(p, style = "background: white")
end

# PyPlot

@require PyPlot begin
  try
    PyPlot.pygui(true)
  catch e
    warn("PyPlot is set to display in the console")
  end
end

# Images

@require Images begin
  displayinline{T,N,A}(img::Images.Image{T,N,A}) =
    Collapsible(HTML("""$(strong("Image")) <span class="fade">$(sizestr(img)), $T</span>"""),
                HTML(applydisplayinline(img.properties),tohtml(MIME"image/png"(), img)))
end

# Expressions

fixsyms(x) = x
fixsyms(x::Symbol) = @> x string replace(r"#", "_") symbol
fixsyms(ex::Expr) = Expr(ex.head, map(fixsyms, ex.args)...)

function displayinline(x::Expr)
  rep = stringmime(MIME"text/plain"(), x |> fixsyms)
  lines = split(rep, "\n")
  html = span(".code.text", @d("data-lang" => "julia2"), rep)
  length(lines) == 1 && length(lines[1]) ≤ 50 ?
    Collapsible(html) :
    Collapsible(strong("Julia Code"), html)
end

# Profile tree

function toabspath(file)
  isabspath(file) && file
  path = basepath(file)
  return path == nothing ? file : path
end

@require Jewel.ProfileView begin
  function displayinline!(tree::Jewel.ProfileView.ProfileTree, opts)
    raise(opts[:editor], "julia.profile-result",
          @d("value" => stringmime("text/html", tree),
             "bounds" => opts[:bounds],
             "lines" => [@d(:file => toabspath(li.file),
                            :line => li.line,
                            :percent => p) for (li, p) in Jewel.ProfileView.fetch() |> Jewel.ProfileView.flatlines]))
  end
end
