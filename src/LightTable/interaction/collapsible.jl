type Collapsible
  header
  content
end

Collapsible(a::AbstractString, b::AbstractString = "") = Collapsible(HTML(a), HTML(b))
Collapsible(a) = Collapsible(a, HTML(""))

function register_collapsible(c)
  _currentresult_ == nothing && return
  id = uuid4()
  _currentresult_.data[id] = c
  return id
end

collapsibleclickjs(id) = """
    var content = this.parentNode.querySelector('.collapsible-content');
    if (content.classList.contains('lazy')) {
      lt.objs.notifos.working();
      $(jlcall(""" LightTable.collapsibleclick("$id") """))
    } else {
      \$(content).toggle(200);
      setTimeout(function () {
        lt.objs.editor.refresh(lt.objs.editor.pool.last_active());
      }, 210);
    }
  """

collapsibleclick(id) = jscall("""
  node = document.getElementById('$(id)');
  node.innerHTML = '$(jsescapestring(stringmime("text/html", _currentresult_.data[UUID(id)].content)))';
  lt.objs.langs.julia.process(node);
  node.classList.remove('lazy');
  lt.objs.notifos.done_working();
  \$(node).show(200)
  """)

function Base.writemime(io::IO, m::MIME"text/html", c::Collapsible)
  id = register_collapsible(c)

  println(io, """<div class="collapsible">""")

  println(io, """<span class="collapsible-header" onclick="$(collapsibleclickjs(id))">""")
  writemime(io, MIME"text/html"(), c.header)
  println(io, """</span>""")
  if _currentresult_ != nothing
    println(io, """<div id="$id" style="display:none;" class="collapsible-content lazy"></div>""")
  else
    println(io, """<div class="collapsible-content">""")
    writemime(io, m, c.content)
    println(io, """</div>""")
  end

  println(io, """</div>""")
end

displayinline!(content::Collapsible, opts) =
  showresult(stringmime("text/html", content), opts, html=true)
