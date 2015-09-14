const abspathpattern =
  @windows? r"([a-zA-Z]+:[\\/][a-zA-Z_\./\\ 0-9]+\.jl)(?::([0-9]*))?" : r"(/[a-zA-Z_\./ 0-9]+\.jl)(?::([0-9]*))?"

# Make the prefix optional, but disallow spaces
const relpathpattern =
  @windows? r"([a-zA-Z_\./\\0-9]+\.jl)(?::([0-9]*))?$" : r"([a-zA-Z_\./0-9]+\.jl)(?::([0-9]*))?$"

function basepath(file)
  path = joinpath(JULIA_HOME,"..","share","julia","base",file) |> normpath
  isfile(path) || (path = nothing)
  return path
end

function githublink(path)
  file, line = match(relpathpattern, path).captures
  """<a href="https://github.com/JuliaLang/julia/tree/$(Base.GIT_VERSION_INFO.commit)/base/$file#L$line">$path</a>"""
end

function baselink(path)
  m = match(relpathpattern, path)
  m == nothing && return path
  file, line = m.captures
  link = basepath(file)
  link == nothing && return githublink(path)
  line == nothing || (link *= ":$line")
  """<a class="file-link" data-file="$link">$path</a>"""
end

function filelink(path)
  """<a class="file-link" data-file="$path">$(basename(path))</a>"""
end

function showerror_html(io, e)
  print(io, """<span class="julia error-description">""")
  showerror(io, e)
  print(io, """</span>""")
end

function showerror_html(io, e, bt, top_function = :eval_user_input)
  println(io, """<div class="julia error">""")
  showerror_html(io, e)
  showbacktrace_html(io, top_function, bt)
  println(io, """</div>""")
end

function showerror_html(io::IO, e::LoadError, bt, top_function = :eval_user_input)
  println(io, """<div class="julia error">""")
  showerror_html(io, e.error)
  showbacktrace_html(io, top_function, bt)
  println(io, """<span class="source">while loading $(e.file), in expression starting on line $(e.line)</span>""")
  println(io, """</div>""")
end

function showbacktrace_html(io::IO, top_function::Symbol, t, set = 1:typemax(Int))
  ls = map(strip, lines(sprint(Base.show_backtrace, top_function, t, set)))
  print(io, """<ul class="julia trace">""")

  for i = 2:length(ls)
    print(io, """<li class="julia trace-entry">""")
    if ismatch(abspathpattern, ls[i])
      print(io, replace(ls[i], abspathpattern, filelink))
    elseif ismatch(relpathpattern, ls[i])
      print(io, replace(ls[i], relpathpattern, baselink))
    else
      println(io, ls[i])
    end
    print(io, """</li>""")
  end

  println(io, """</ul>""")
end

# Methods

Requires.@init Jewel.@inmodule Base begin

stripparams(t) = replace(t, r"\{([A-Za-z, ]*?)\}", "")

function writemime(io::IO, ::MIME"text/html", m::Method)
  print(io, "<tr><td>")
  print(io, m.func.code.name)
  tv, decls, file, line = Base.arg_decl_parts(m)
  if !isempty(tv)
    print(io,"<i>")
    # Redundant, since type parameters appear in the parameter list
    #Base.show_delim_array(io, tv, '{', ',', '}', false)
    print(io,"</i>")
  end
  print(io, "(")
  print_joined(io, [isempty(d[2]) ? d[1] : d[1]*"::<b>"*stripparams(d[2])*"</b>"
                    for d in decls], ",", ",")
  print(io, ")")
  if line > 0
    file = "$file:$line"
    print(io, "</td><td>")
    print(io, isabspath(file) ? Main.LightTable.filelink(file) : Main.LightTable.baselink(file))
    print(io, "</tr>")
  end
end

function writemime(io::IO, m::MIME"text/html", mt::MethodTable)
  defs = Method[]
  d = mt.defs
  while !is(d,())
    push!(defs, d)
    d = d.next
  end
  writemime(io, m, defs)
end

function writemime(io::IO, m::MIME"text/html", mt::Vector{Method})
  print(io, """<div class="julia"><table class="data-frame">""")
  file(m) = m.func.code.file |> string |> basename
  line(m) = m.func.code.line
  map(d->writemime(io, m, d), sort!(mt, lt = (a, b) -> file(a) == file(b) ?
                                      line(a) < line(b) :
                                      file(a) < file(b)))
  print(io, """</table>""")
  print(io, """</div>""")
end

end
