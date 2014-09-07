type Collapsible
  header
  content
end

function Base.writemime(io::IO, m::MIME"text/html", c::Collapsible)
  println(io, """<div class="collapsible">""")
  println(io, """<span class="collapsible-header">""")
  writemime(io, m, c.header)
  println(io, """</span>""")
  println(io, """<div class="collapsible-content">""")
  writemime(io, m, c.content)
  println(io, """</div></div>""")
end

displayinline!(content::Collapsible, opts) =
  showresult(render(content), opts, html=true)

function register_collapsible(c)
  id = uuid4()
  _currentresult_.data[id] = Result(id, c)
end

collapsibleclick(r::Result) = """
    var content = this.parentNode.querySelector('.collapsible-content');
    if (content.classList.contains('lazy')) {
      $(jlcall("""LightTable.collapsibleclick("$(_currentresult_.id)", "$(r.id)") """ |> htmlescape))
    } else {
      \$(content).toggle(200);
    }
  """

collapsibleclick(result, collapsible) = @show result collapsible

function render(c::Collapsible)
  _currentresult_ == nothing && return stringmime("text/html", c)
  io = IOBuffer()
  result = register_result(c)

  println(io, """<span class="collapsible-header" id="$(result.id)" onclick="$(collapsibleclick(result))">""")
  writemime(io, MIME"text/html"(), c.header)
  println(io, """</span>""")
  println(io, """<div class="collapsible-content lazy"></div>""")

  return takebuf_string(io)
end
